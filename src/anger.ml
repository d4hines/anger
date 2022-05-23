open Feather
open Feather.Infix

let lift_error cmd =
  let result, status = cmd |> collect stdout_and_status in
  if status <> 0 then failwith "non-zero exit code" else result

let default_remote = "origin"
let default_branch = "master"
let branch_prefix = "d4hines"
let git = process "git"

(* Find all commits between HEAD and origin/main *)
let all_commits =
  git [ "rev-list"; Format.sprintf "%s/%s..HEAD" default_remote default_branch ]
  |> lift_error |> lines

let rev_to_commit_message rev =
  git [ "log"; "-n 1"; "--oneline"; rev ] |> lift_error

let write_note rev message = git [ "notes"; "add"; "-f"; "-m"; message; rev ]

let reset_branch branch_name rev =
  let _ = git [ "branch"; "-f"; branch_name; rev ] |> lift_error in
  ()

let make_note ~rev =
  let message = rev_to_commit_message rev in
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

(* Gather up the notes for each commit *)
let revs =
  all_commits |> List.rev
  |> List.iter (fun rev ->
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
         ())

(* I think stderr is safe here to drop in /dev/null*)
(* >! "/dev/null"
          |> collect stdout_and_status)
   |> List.map (fun (notes, status) -> if status = 0 then notes else
     let () = Format.printf "Missing annotation for the following commit:\nCommit: %s\n%Message: %s\n%!" rev (rev_to_commit_message rev) in
     assert false

     )

(* let () =
   List.iter (function None -> git [ "branch" ] | Some notes -> assert false) *)
(*  *)

(*
   
   > git rev-list origin/main..HEAD

   check their annotations
   > git notes show <ref>

   if it does not have a note
     generate a branch
     > git branch <generated name> <ref>
     add a note designating the branch name
     > git notes add -m "branch: <generated name>"
   if it has a note
     get the contents of the note
     > git notes show <ref>
     parse the name by chopping off the "branch: " in "branch: <generated name>"
     overwrite the branch
     > git branch -f <generated name>
     push the changes
     > git push --force-with-lease --set-upstream origin <generated name>
 *)

(* test edit *)
