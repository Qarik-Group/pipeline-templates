Genesis CI for Kits
-------------------

## Architecture Overview

The general structure is shown below.  It's broken into the base directory,
the pipeline contents (jobs and resources), the tasks the pipeline calls, and
the scripts the tasks use.  There is also a place for the environment
definitions used in the tests.

```
ci
├── envs
├── pipeline
│   ├── jobs
│   └── resources
├── scripts
└── tasks
```

### Pipeline

The general pipeline structure is specified in `ci/pipeline/base.yml`.  It is
merged with the contents of `ci/pipeline/jobs/*` and `ci/pipeline/resources/*`
to add the job and resource definitions needed by the base pipeline structure.
That provides the template for the pipeline uploaded by the `ci/repipe`
command, which merges that template with the `ci/settings.yml` file to
configure the pipeline for the specific values that define the targets of the
pipeline.

It is ONLY when the contents of these files change that a `repipe` is required
to be run.  All other changes are updated by pushing the changes into the
develop branch of this repository, which is picked up by the `git-ci`
resource.

### Tasks

Tasks are atomic definitions for a single task that a job may perform.  While
it is possible to embed tasks in the job definitions above, by seperating them
out as tasks means you can update or fix a bug in a task and simply push it to
the repository to have it take effect without having to rebuild the pipeline.

Unlike the pipeline defintions, including the jobs and resources, the tasks
yaml files cannot use spruce operators.

However, the tasks can make use of concourse variables in the form of
`((var_name[.field]))`, which accesses values stored in the `concourse` vault,
in one of the following locations, in order of checking:

* `concourse/<team>/<pipeline>/`
* `concourse/<team>/`
* `concourse/shared/`

If the field name is empty, the field `value` is assumed.

### Scripts

The `ci/scripts` directory contains the scripts that are used by the tasks.
They reside in a single common scripts file, rather than split out by tasks,
because they are often shared among multiple tasks, so this promotes
reusability.

While most are bash scripts, there are perl scripts too.  Please restrict your
scripts to these two languages because they are common to all platforms that
we test under.

## Customising for Specific Kits

Most of the contents of the ci are generic, but customizations are required to
meet the testing needs of each kit.  These will be explained below.

### Custom Settings

The `ci/settings.yml` file contains most of the custom values that need to be
set for running the tests.  The basic structure is:

```
---
meta:
  kit:            bosh
  release:        BOSH Genesis Kit
  target:         cloudpipes/genesis
  url:            https://cloudpipes.starkandwayne.com
  iaas:           gcp
  exposed:        false
  initial_version: 0.2.0

  upstream:
    package:  bosh-deployment

  vault:
    url:       ((vault.url))
    token:     ((vault.token))

  aws:
    access_key: ((aws.access_key_id))
    secret_key: ((aws.secret_access_key))

  github:
    owner:        genesis-community
    repo:         bosh-genesis-kit
    branch:       develop
    main-branch:  master
    private_key:  ((github.private_key))
    access_token: ((github.access_token))

  shout:
    url:      ((shout.url))
    username: ((shout.username))
    password: ((shout.password))
```

The settings are all under the `meta` key, and will be pruned before pusing to
concourse.

#### Regarding Secrets...

Some of these values are sensitive, and should be stored in the vault that
concourse uses.  Note that they don't have to be added for each pipeline, as
the copy stored in the team endpoint will provide for all pipelines under that
team.  If you do need separate values for a specific pipeline, store them
under the pipeline endpoint instead of overwriting the common team endpoint.

#### Basic Configuration

`kit`
: The name of the kit being tested

`name`
: Name of the kit -- defaults to "`kit`-genesis-kit"

`release`
: Humanized title for the release (not currently used, defaults to "`kit`
Genesis Kit")

`target`
: The Concourse team name that will host the pipeline

`url`
: The URL for the Concourse application, including schema.

`iaas`
: The Infrastructure Service Provider.  Currently only `vsphere` and `gcp` are
supported, but new ones could be added with minimal effort.  This setting
determines which enviornments are used when testing, along with some script
decisions based on the IaaS.

`expose`
: Determines if the pipeline is exposed or hidden from the public in
Concourse.  Before setting this to true, make sure that the log outputs don't
contain any secrets that will allow the public access to the IaaS or other
proprietary systems.

`initial_version`
: If you are moving pipelines and have lost access to the backend storage that
contained the version tracking, you can specify the initial version value
here.  Default is 0.0.0

#### Upstream

The following is only needed if your kit embeds another upstream package (such
as bosh-deployment or cf-deployment in their respective kits)  Only
`upstream.package` is required, the rest are computed unless overwritten.

`upstream.package`
: The name of the upstream package that is being tracked.  This is also known
as the project or the repo (without the org prefix)

`upstream.path`
: The name of the directory in the kit that holds the upstream package.
Defaults to `upstream.package` value.

`upstream.org`
: The name of the github org that hosts the upstream repo.  Defaults to
`cloudfoundry` if not given.

`upstream.repo`
: The name of the fully qualified repo that provides the contents for the
embedded upstream package. Default is `upstream.org`/`upstream.package`

`upstream.url`
: If the upstream repo is not on github, specify the full url to it here.

The Upstream section also works for bosh releases.  If you want new versions
of bosh releases automatically updated for your kit, you can add the following
sections:

`upstream.bosh_releases`
: Array of hashes, consisisting of the following keys:

`name`
: name of the release as specified by the kit

`path`
: path to the file in the kit that holds the release definition that will be
overwriten with the updated version.

`type`
: the type of release resource.  Assumed to be (and so far only validated
against) bosh-io-release if not specified

`repo`
: the release resource repository.


#### Vault

This is the configuration for access the vault used by Genesis to deploy
environments.  It doesn't have to be the same vault as is used by Concourse.

`vault.url`
:  The url to the vault.  Unless otherwise indicated, it should be stored in
the concourse vault and provided to the pipeline as `((vault.url))`

`vault.token`
:  The app-role token for accessing the Genesis CI vault data.  This should be
customized to only allow access to the paths required, and like the url above,
stored in concourse vault and specified by `((vault.token))`

#### AWS

The AWS credentials for access the s3 blobstore for resources such as version:

`aws.access_key`
: AWS Access Key (public). Stored in concourse vault and specify as `((aws.access_key_id))`

`aws.secret_key`
: AWS Secret Key (private).  Stored in concourse vault and specify as `((aws.secret_access_key))`

#### Github

The access credentials for the kit's repository

`github.owner`
: The name of the github organization; unless otherwise indicated, this will
likely be "genesis-community"

`github.repo`
: The name of the repository (without org prefix) for the kit being tested.

`github.branch`
: The name of the source branch, most likely "develop"

`github.main-branch`
: The name of the release branch, most likely "main", but some older
repositories use "master"

`github.private_key`
: The ssh key used to push commits to the main branch.  Stored in concourse
vault and specify as `((github.private_key))`

`github.access_token`
: The Github Personal Access Token, primarily used to prevent API throttling.
Stored in concourse vault and specify `((github.access_token))`

#### Shout

Shout is a notification consolidator, running as a job on Concourse if that
feature is enabled.

`shout.url`
: URL for accessing Shout, stored in concourse vault, and specified as
`((shout.url))`

`shout.username`
: Username for accessing Shout, stored in concourse vault, and specified as
`((shout.username))`

`shout.password`
: You guessed it; password for accessing Shout, and stored in councourse
valut, specified as `((shout.password))`

#### Custom Blocks

Some kits will have additional blocks to support their custom testing.  Bosh
kit has a `bats` block for specifying the configuration of the BOSH Acceptance
Tests, for example.  These settings should be namespaced under here, and
references in the corresponding jobs via `params` environment variable
declarations for the tasks to use.

If any custom blocks use sensitive data, add those values to the concourse
vault under the pipeline endpoing (or team endpoint if common to more than one
pipeline), and reference them via concourse variables.

### Custom Testing Scenarios

Beyond the settings, some pipelines will need customisations to the jobs,
resources, tasks and scripts.  While we try to keep this to a minimum, some
can't be helped.  Here is a handy guide to know where to customize.

#### Custom Jobs

If you add a custom test job, such as a special acceptance test, or make some
tests run in parallel, you will have to modify the default configuration yaml
files as follows:

##### `ci/pipeline/base`

The list of jobs in the groups must be updated to reflect what jobs exist and
what groups the belong to.  The default configuration is below:

```
groups:
  - name: (( grab meta.pipeline ))
    jobs:
    - build-kit
    - spec-tests
    - spec-check
    - ship-prerelease
    - deploy
    - upgrade
    - acceptance-tests
    - prepare
    - ship-release
  - name: upstream
    jobs:
    - upstream-sync
  - name: versions
    jobs:
    - major
    - minor
    - patch
```

Common edits would be to remove the upgrade or acceptance-tests from the main
group, named after the pipeline, and to remove the upstream group and its jobs
if your kit does not embed an upstream package.

#### `ci/pipeline/jobs/prepare`

The prepare job runs after the testing is complete.  If you have modified what
test jobs are run, you will need to update the `passed` block in the `git`,
`version`, and `spec-check` resources, as shown below:

```
    - in_parallel:
      - { get: version,    passed: [deploy,upgrade], params: {bump: final} }
      - { get: spec-check, passed: [deploy,upgrade] }
      - { get: git,        passed: [deploy,upgrade], trigger: true }
```

It is common to leave out the acceptance tests, but it is also okay to make
them mandatory to pass before allowing the kit to be released.

#### `ci/pipeline/jobs/acceptance-tests`

The acceptance tests, if you have one at all, will be very specific to your
kit.  Follow the provided example as a template, but feel free to colour
outside the lines as needed.

The acceptance tests will likely require tasks and scripts specific for
configuring and running those tests.  Those should be placed in the `ci/tasks`
and `ci/scripts` directories respectively, and named specific to the test
being perfomred (eg: `ci/tasks/bats.yml` and `ci/script/bats` for the BOSH
acceptance tests)

#### `ci/pipeline/jobs/*.yml` and `ci/pipeline/resources/*.yml`

Any jobs or resources that are not used need to be removed or renamed to not
end with .yml (ie rename to `<whatever>.yml-disabled`)

#### `ci/scripts/get-latest-upstream`

If your kit has an embedded upstream package, you should modify this file to
perform your upstream synchronization.  Most of it is common, and used the
settings from above, but different actions may be needed to fully synchronize
correctly, such as stripping test and doc files, putting releases in the
release overlay files, or modifying directory structures.

#### `ci/scripts/test-deployment`

This is the guts of deploying and testing the kit.  While most of the code is
common, there may be modifications needed in specifying what tests get run.
If running upgrade tests, this gets called twice, once to set up the starting
state, and once to apply the upgrade.

If you need to set up scenarios for testing upgrading, it may seem natural to
put those steps in this script, but the recommended way would be to add a
configuration task and script to the upgrade job between deploying the base
and deploying the upgrade.

#### `ci/scripts/release-notes`

In rare cases, you may have to modify this script if your kit has special
commits that warrant a special handling in the release notes, such as upstream
synchronization pattern matching.

#### `ci/envs/*`

These are the deployment environments.  You will need to make one per
deployment tested by the pipeline.  The pattern to use is:

`ci-<iaas>-<purpose>.yml`

The `iaas` is the same value as specified in `meta.iaas` in the
`ci/settings.yml` file

The `purpose` is what the test is testing.  Convention has the nominal
deployment envionment purpose called `baseline`, and there is also `upgrade`,
but it can anything.

The deployment name is specified in the deployment jobs as the param value
`DEPLOY_ENV`

#### Other Considerations

Some custom tests may need configuration files for their own purposes.  Please
store them in the base `ci/` directory, named after the test they are
supporting. (eg: `ci/bats.yml` for the BOSH Acceptance Test configuration
file)

There are definitely many places this can be further modified, but try to keep
to the template as much as possible.  If you can't, see if it can be
generalized and backported to the main template.
