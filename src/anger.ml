open Feather
open Feather.Infix

let default_remote = "origin"
let default_branch = "master"
let branch_prefix = "d4hines"
let git = process "git"

let name = Stdlib.read_line ()

let () = print_endline @@ "Hello, " ^ name

(* Find all commits between HEAD and origin/main *)
let all_commits =
  git [ "rev-list"; Format.sprintf "%s/%s..HEAD" default_remote default_branch ]
  |> collect stdout |> lines

  
(* Gather up the notes for each commit *)
let revs =
  all_commits
  |> List.map (fun rev ->
         git [ "notes"; "show"; rev ]
         (* I think stderr is safe here to drop in /dev/null*)
         >! "/dev/null"
         |> collect stdout_and_status)
  |> List.map (fun (notes, status) ->
    if status = 0 then notes else
      print_endline "No "
      let branch_name = 
    if status = 0 then Some notes else None)

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
