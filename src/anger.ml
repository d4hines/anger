open Feather

let lift_error cmd =
  let result, status = cmd |> collect stdout_and_status in
  if status <> 0 then failwith "non-zero exit code" else result

let default_remote = "origin"
let default_branch = "main"
let git = process "git"

let get_commit_message rev =
  git [ "log"; "-n 1"; "--oneline"; rev ] |> lift_error

let get_notes rev =
  let notes, status =
    git [ "notes"; "show"; rev ] |> collect stdout_and_status
  in
  Format.printf "notes: %s, status: %d\n%!" notes status;
  if status = 0 then Some notes else None

let write_note ~rev ~message = git [ "notes"; "add"; "-f"; "-m"; message; rev ]

let reset_branch ~branch_name ~rev =
  let _ = git [ "branch"; "-f"; branch_name; rev ] |> lift_error in
  ()

let make_command_string revs =
  let commits =
    revs
    |> List.map (fun rev ->
           let message = get_commit_message rev in
           let branch =
             match get_notes rev with
             | Some notes ->
                 let len = String.length "branch_name: " in
                 let branch_name =
                   String.sub notes len (String.length notes - len)
                 in
                 Format.sprintf " -> %s" branch_name
             | None -> ""
           in
           message ^ branch)
    |> String.concat "\n"
  in
  Format.sprintf
    "# vim: syntax=gitrebase\n\
     #\n\
     # Below are all the commits between %s/%s and the current branch,\n\
     # along with the branches they map to. \n\
     #\n\
     # Example:\n\
     # <commit> <message> -> my_prefix/my_branch\n\n\
     %s"
    default_remote default_branch commits

let () =
  let open Feather.Infix in
  let anger_file = ".git/anger" in
  (* Find all commits between HEAD and origin/main *)
  git [ "rev-list"; Format.sprintf "%s/%s..HEAD" default_remote default_branch ]
  |> lift_error |> lines
  (* Gather up the notes for each commit *)
  |> List.rev
  |> make_command_string |> echo > anger_file |> run;
  sh "$EDITOR .git/anger" |> run;
  cat anger_file |> lift_error |> lines
  |> List.filter (fun x ->
         Stdlib.( > ) (String.length x) 0 && String.sub x 0 1 <> "#")
  |> List.filter_map (fun line ->
         Format.printf "Line: %s\n%!" line;
         match Str.split (Str.regexp "->") line with
         | [] -> assert false
         | [ _ ] -> None
         | [ message; branch_name ] ->
             let rev = String.split_on_char ' ' message |> List.hd in
             let branch_name = String.trim branch_name in
             Some (rev, branch_name)
         | _ -> assert false)
  |> List.iter (fun (rev, branch_name) ->
         let message = Format.sprintf "branch_name: %s" branch_name in
         write_note ~rev ~message |> run;
         reset_branch ~branch_name ~rev;
         git
           [
             "push";
             "--force-with-lease";
             "--set-upstream";
             default_remote;
             branch_name;
           ]
         |> run)
