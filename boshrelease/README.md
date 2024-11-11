Bosh Release pipeline
=====================

Test flight
-----------

The `testflight` job deploys a default deployment manifest, applying defaults
to it, and optionally run one or many test errands.

### Deployment manifest path

Path is provided by the `meta.manifest.path` setting with two levels of
defaults, matching conventions.

The default maifest path is `manifests/<meta.name>.yml` where the default
`manifests` directory may be customized by the `meta.manifest.directory`
setting.

When your manifest follows the `<meta.name>.yml` convention but is in a
different directory, let's say `deploy` for example, you just need to
customize the directory name:

```yaml
meta:
  manifest:
    directory: deploy
```

Otherwise, you may customize `meta.manifest.path` altogether.

The `meta.manifest.path` and `meta.manifest.directory` variables are referring
to filenames, so they , also known as
[Bash globbing][bash_globbing].

[bash_globbing]: https://www.gnu.org/software/bash/manual/bash.html#Filename-Expansion


#### Applied operators

Operator files can be listed in the `meta.manifest.operator_file_paths`
setting. This is not an array but a YAML string of comma-separated or
space-separated files.

Space-separated is convenient when leveraging the default YAML behavior with
multi-line strings, where end-of-lines are replaced by spaces. So, you just
list one operator file per line:

```yaml
meta:
  manifest:
    operator_file_paths:
      deploy/operators/teak-stuff.yml
      deploy/operators/fix-things.yml
```

The files listed in `meta.manifest.operator_file_paths` are subject to
standard [Bash Filename Expansion][bash_globbing].


#### Injected variable values

Ad-hoc values may be defined as raw YAML key-values, in the
`meta.manifest.vars` setting:

```yaml
meta:
  manifest:
    vars: |
      ---
      deployment_name: my-release-testflight
      other_variable:  other-value
```

#### Test errands

The test errands are defined in the `meta.test-errands` (string) setting.
These are space-separated (commas not allowed) which is fine with YAML
multi-line strings.

```yaml
meta:
  test-errands: |
    some-prerequisite-setup
    smoke-tests
```

Test errands are not filenames, so they don't support globbing.


### Implementation notes

#### Adjustments made to the deployment manifest

##### Deployment name

The deployment name is forced to `<meta.name>-testflight` for the `testflight`
job and `<meta.name>-testflight-pr`for the `testflight-pr` job, so that they
may run in parallel without conflicting.


##### Cloud config-related adjustments

By convention, the `testflight` job forces several bits of the tested
deployment manifest.

From the default `cloud-config` (as provided by `bosh cloud-config`), the
`testflight` job uses:

- first available VM type
- first available disk type
- first available network

And forces those into the deployment manifest.

Disk type is forced only on instance groupe having a defined
`persistent_disk_type`.

This means that you have to take care that these first vm type, disk type and
network are appropriate.

### Git-LFS blobstore support

When `meta.aws.access_key` is not defined, no `config/private.yml` is
generated, which provides the flexibility for having a local blobstore.

Plus, `git lfs install` is properly executed in the container whenever a
`.gitattributes` file exists at the root of the Git project, and contains the
string `lfs`.


### Note on dev release version

It builds the `${ver}+dev.0` where `${ver}` is the latest of final versions
that have been cut so far.

Then this version is not forced.

The forced release version is `${ver}.latest`

So if you've more recent releases uploaded already, they will take precedence.


### Support for cached blobs

Caching of Bosh blobs can be activated with custom additions to your
`settings.yml` file as shown below.

```yaml
jobs:
  - name: testflight
    plan:
      - (( inline ))
      - {} # in_parallel:
      - task: testflight
        config:
          caches:
            - path: git/blobs
            - path: /root/.bosh/cache

  - name: testflight-pr
    plan:
      - (( inline ))
      - {} # in_parallel:
      - {} # put: git-pull-requests
      - task: testflight
        config:
          caches:
            - path: git-pull-requests/blobs
            - path: /root/.bosh/cache

  - name: shipit
    plan:
      - (( inline ))
      - {} # in_parallel:
      - task: release
        config:
          caches:
            - path: git/blobs
            - path: /root/.bosh/cache
```

In this case, the `blobs/` subdirectory of the Bosh release becomes a mounted
volume. The implementation takes extra care not to evice that cache when
running any `bosh reset-release` that would be required after committing with
a too liberal `.gitignore`.
