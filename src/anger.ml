open Feather
open Feather.Infix

let default_remote = "origin"
let default_branch = "master"

let all_commits =
  process "git"
    [ "rev-list"; Format.sprintf "%s/%s..HEAD" default_remote default_branch ]
  |> collect stdout |> lines

let all_notes =
  all_commits
  |> List.map (fun rev ->
         process "git" [ "notes"; "show"; rev ] |> collect stdout)

let () = List.iter (fun notes -> Format.printf "note: %s\n" notes) all_notes

(*
   find all commits between HEAD and origin/main
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
