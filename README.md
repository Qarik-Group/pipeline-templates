Pipeline Templates
==================

This repository collects up all that tribal wisdom we've gained
from building Concourse Pipelines for various different purposes.
Each template provides a base `ci/pipeline.yml` that structures the
pipeline, `ci/settings.yml` to override any parameters defined by the template, a set of scripts (in `ci/scripts/`) that are referenced
from the pipeline, and a `ci/repipe` utility for putting all the
pieces together into a functioning Concourse pipeline.

Setup is straightforward:

```shell
git clone https://github.com/starkandwayne/pipeline-templates
cd pipeline-templates
./setup <template> ~/bosh/my-new-boshrelease
```

Alternatively, you can initialize the pipeline from inside the
target repository:

```shell
cd code/my-buildpack
~/code/pipeline-templates/setup <template>
```

The first argument to `setup` is the template you want to use. Currently available templates:

* `bash`
* `boshrelease`
* `genesis-kit`
* `buildpack`
* `cfpush`
* `docker/base`
* `docker/ext-tests`
* `go`
* `helm`

Don't let the name fool you!  `./setup` can also be used to update
an existing templated pipeline `ci/` directory to pick up new
changes made to the templates.

Once you've set up your repository, you'll need to fill in your
`ci/settings.yml` file with any parameters the template required:

```shell
cd code/my-project
ci/repipe # Attempt to update the pipeline config,
          # spitting out errors for missing parameters
vi ci/settings.yml # fill in the missing parameters
ci/repipe # Deploy the pipeline config!
```

### Dependencies

The `ci/repipe` script uses [Spruce](https://github.com/geofffranks/spruce) to merge `ci/pipeline.yml` and your bespoke `ci/settings.yml`.

On MacOS/Homebrew:

```shell
brew install starkandwayne/cf/spruce
```

On Debian/Ubuntu:

```shell
wget -q -O - https://raw.githubusercontent.com/starkandwayne/homebrew-cf/master/public.key | apt-key add -
echo "deb http://apt.starkandwayne.com stable main" | tee /etc/apt/sources.list.d/starkandwayne.list
apt-get update

apt-get install spruce
```

The `ci/repipe` for genesis-kits also requires `jq`, which can be installed via
brew on MacOS or apt-get on Debian/Ubuntu.

## And Now, The Templates!

### docker/base and docker/ext-tests

For building Docker images, with tests.  This template comes in
two flavors: `docker/base` (where the unit tests are inside the
Docker image) and `docker/ext-tests`, where the tests live outside
of the image.

![Docker Pipeline][docker-pipeline]

### go

Takes a Go software project repository, runs unit tests and
(when the manual `shipit` job is run) releases to Github.

![Go Project Pipeline][go-pipeline]

### boshrelease

Tries to create a BOSH release from the repository, upload it to a
hosted BOSH-lite for viability testing, and (when the manual
`shipit` job is run) releasing it to Github with a tarball
artifact, and also uploading that release tarball to S3.

![BOSH Release Pipeline][boshrelease-pipeline]

### genesis-kit

Builds a pipeline to create a pipeline that builds a release candidate, runs
it through [spec tests](https://github.com/genesis-community/testkit) and
spec-check, then any deployment, upgrad and acceptance tests.  Passing those,
it prepares the release notes based on commit messages, and then can be
manually released.  It also includes a manual prerelease after the initial RC
is built.

There is also provision for pulling upstream dependencies and bumping semantic
version components.

Read the README.md file under genesis-kit for customization options.  As
written, it is based on the cf-genesis-kit.

![Genesis Kit Pipeline][genesis-kit-pipeline]

### buildpack

Runs unit and integration tests on a Cloud Foundry buildpack, and can release it to Github.

![Buildpack Pipeline][buildpack-pipeline]

### helm

Builds a docker image and uploads Helm chart to an S3 bucket

![Helm][helm-pipeline]

## ci/settings.yml

You will need to customize your pipeline with information about your CI, your Amazon AWS credentials + S3 bucket for storing assets + `version` file, your Slack account, etc.

You will create and maintain `ci/settings.yml` for this.

Try very very hard to not modify `ci/pipeline.yml`. Instead, use `./setup` to update `ci/pipeline.yml` with new changes from this repo. If you do need to modify `ci/pipeline.yml` please feel welcome to submit PRs to this repo so that we can merge them and share them with everyone.

At Stark & Wayne we store our credentials for pipelines in Vault. We use the spruce syntax `(( vault "path1" ))` to dynamically fetch these values during `ci/repipe`. Recently Concourse CI has added native support for Vault, so we will investigate this in the future. Or you could try to use it and let us know how it goes!

Here is an example [`ci/settings.yml`](https://github.com/starkandwayne/eden/blob/master/ci/settings.yml) from the `eden` CLI project (uses the `go` template):

```yaml
---
meta:
  name: eden
  target: sw
  url:     https://ci.starkandwayne.com

  initial_version: 0.5.0

  go:
    binary: eden
    cmd_module: .

  aws:
    access_key: (( vault "secret/aws/starkandwayne-s3:access" ))
    secret_key: (( vault "secret/aws/starkandwayne-s3:secret" ))
    region_name: eu-central-1

  slack:
    webhook: (( vault "secret/pipelines/eden/slack:webhook" ))
    channel: "#eden" # https://openservicebrokerapi.slack.com/messages/C6Y5A2N8Z/
    username: starkandwayne-ci
    icon:     https://www.starkandwayne.com/assets/images/shield-blue-50x50.png

  github:
    owner: starkandwayne
    repo: eden
    access_token: (( vault "secret/pipelines/shared/github:access_token" ))
    private_key: (( vault  "secret/pipelines/shared/github:private_key" ))
```

Bonus, we use https://github.com/starkandwayne/safe as our CLI to interact with Vault.

For example, to populate the `(( vault "secret/pipelines/eden/slack:webhook" ))` value in Vault:

```
safe set secret/pipelines/eden/slack webhook=https://hooks.slack.com/services/T2S1X7xxx/B6Y5A7xx/0nP7jxxx
```

[docker-pipeline]:      https://raw.githubusercontent.com/cloudfoundry-community/pipeline-templates/master/screenshots/docker.png
[boshrelease-pipeline]: https://raw.githubusercontent.com/cloudfoundry-community/pipeline-templates/master/screenshots/boshrelease.png
[genesis-kit-pipeline]: https://raw.githubusercontent.com/cloudfoundry-community/pipeline-templates/master/screenshots/genesis-kit.png
[go-pipeline]:          https://raw.githubusercontent.com/cloudfoundry-community/pipeline-templates/master/screenshots/go.png
[buildpack-pipeline]:   https://raw.githubusercontent.com/cloudfoundry-community/pipeline-templates/master/screenshots/buildpack.png
[helm-pipeline]:        https://raw.githubusercontent.com/cloudfoundry-community/pipeline-templates/master/screenshots/helm.png
