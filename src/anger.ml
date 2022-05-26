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
  if status != 0 then Some notes else None

let write_note rev message = git [ "notes"; "add"; "-f"; "-m"; message; rev ]

let reset_branch branch_name rev =
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

let make_note ~rev =
  let message = get_commit_message rev in
  Format.printf
    "Missing notes for the following commit:\n\n\
     %s\n\n\
     Please enter a branch name:\n\n\
     %!"
    message;
  (* let branch_name = Stdlib.read_line () in *)
  let branch_name = Stdlib.read_line () in
  let note = Format.sprintf "branch_name: %s" branch_name in
  let _ = write_note rev note |> lift_error in
  Format.printf "Created branch and note: %s\n%!" branch_name;
  branch_name

let () =
  let open Feather.Infix in
  (* Find all commits between HEAD and origin/main *)
  git [ "rev-list"; Format.sprintf "%s/%s..HEAD" default_remote default_branch ]
  |> lift_error |> lines
  (* Gather up the notes for each commit *)
  |> List.rev
  |> make_command_string |> echo > ".git/anger" |> run

(* |> List.iter (fun rev ->
       Format.printf "Rev: %s\n %!" rev;
       let notes, status =
         git [ "notes"; "show"; rev ] |> collect stdout_and_status
       in
       Format.printf "git notes status %d\n%!" status;
       let branch_name =
         if status <> 0 then make_note ~rev
         else
           let len = String.length "branch_name: " in
           String.sub notes len (String.length notes - len)
       in
       Format.printf "Resetting...";
       reset_branch branch_name rev;
       Format.printf "Done\n%!";
       let _ =
         git
           [
             "push";
             "--force-with-lease";
             "--set-upstream";
             default_remote;
             branch_name;
           ]
         |> lift_error
       in
       ()) *)
