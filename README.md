> as in "`git reset` used in anger"

## Concept

You want to use the [stacked diff workflow](https://jg.gg/2018/09/29/stacked-diffs-versus-pull-requests/).
But you want to do so in Github, which doesn't support it well out-of-the-box.

So you abuse Github branches in the following way:
- Add your commits to your local copy of `main`.
- Create one branch per commit
- Make your PR's point to their parent commit so Github will automatically update the
  base when it gets merged.
- Every time you rebase, reset the branch to the new commit.

But this is tedious to do by hand. `anger` does it for you, using `git notes` to associate
commits with git branches. If we configure the `notes.rewriteRef` setting in git, the notes
become resilient to `git rebase`, allowing us freedom to edit our local history while automatically
synchronizing all our PR's.

## Usage

First configure your git setup:
```
git config notes.rewriteRef refs/notes/commits
```

Then do some work:
```
...
git commit -m "A"
...
git commit -m "B"
...
git commit -m "C"
```

At any time, to create one branch per commit
ahead of main, run `anger`:
```
nix run github:d4hines/anger
```
You'll be prompted to give a name to any branches
that don't exist yet.

Existing branches will be hard reset to the corresponding
commits

**Warning** Extremely poorly tested - use at your own risk.
