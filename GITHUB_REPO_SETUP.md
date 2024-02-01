# Branches

## master

### Purpose

This is the branch that all releases are cut. It is only to accept
fast-forward merges from the develop branch, and can only be written to by the
release bot and overseer intervention.

### Protection Rules

* Requires linear history
* Restrict who can push:
  * ci bot user
     - (may be different per pipeline team: gkconcourseninja for gstack team,
       cloudfoundry-community-ci-bot for cloudfoundry-community, ...)
  * overseer
     - (currently bgandon)
* Allow force pushes:
  * Specify who can force push
    * overseer

## develop

### Purpose

Receives all feature branch merged, which then triggers the pipeline process.
Unless unavoidable, branches must be rebased-merged or squashed-merged into
this branch.

### Protection Rules

* Require a pull request before merging
  * Require approvals
    * Required number of approvals before merging: 1
  * Allow specific actors to bypass required pull requests:
    * overseer
    * ci-bot
* Require linear history
* Allow force pushes
  * Specify who can force push
    * overseer

### Protection Rules

* Lock branch

## #.#.x-develop

### Purpose

When the primary version advances to the next major or minor semantic version,
<version>-develop branches may be created to backport features or bug fixes to
support clients that are not able to advanced to the current version branch.

These should not be named with the explicit version, but the patch level
should be 'x' to indicate that it is still an evergreen branch, which may have
further development. (ie 2.8.x-develop)

## All Other Branches

### Purpose

The remaining branches are for the purpose of feature development or bug
fixes.  If it is being worked on by a single developer, it is recommended that
it be named '<user>/<purpose>', such as 'bgandon/fix-broken-garblewaffle'

Pull requests will be created from these branches against develop, and deleted
upon merging.  It is recommended that any development WIP or cruft commits be
cleaned up using `git rebase -i origin/develop` prior to creating the pull
request so as to not pollute the commit history.
