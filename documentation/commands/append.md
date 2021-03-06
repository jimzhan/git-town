#### NAME

append - create a new feature branch as a direct child of the current branch

#### SYNOPSIS

```
git town append <branch_name>
```

#### DESCRIPTION

Syncs the current branch,
forks a new feature branch with the given name off the current branch,
makes the new branch a child of the current branch,
pushes the new feature branch to the remote repository
if and only if [new-branch-push-flag](./new-branch-push-flag.md) is true,
and brings over all uncommitted changes to the new feature branch.

#### OPTIONS

```
<branch_name>
    The name of the branch to create.
```
