# ESP32 Firmware Automation

This repository automates the process of building firmware images for
ESP32-based devices. It utilizes GitHub Actions to trigger builds when a pull
request is opened or updated, and specific labels are applied. 

## Workflow Overview

The workflow is triggered on:

- A pull request targeting the main branch.
- Pull request events such as push to the PR branch, or adding/removing a label
- Manual dispatch via GitHub UI (`workflow_dispatch`) (Actions -> Workflow -> Run).

## Concurrency Control

To avoid overlapping builds, the workflow uses a concurrency group based on the
workflow name and the pull request number or reference. If another workflow
from the same group is in progress, the previous run will be canceled. This is
due to change, as we would like to allow builds triggered externally. For now
we keep it, but once we get a robust workflow, we will remove that.

## Labels for Control

The following labels control the workflow behavior when ran via a PR:

- `ok-to-test`: When this label is applied to a pull request, the build process
  will run.
- `ok-to-upload`: If this label is applied, the workflow will upload the
  generated firmware to our S3 repository.

### Label workflow

You can add labels to a pull request manually through the GitHub UI:

- Navigate to the pull request page.
- In the right-hand sidebar, find the "Labels" section.
- Click on "Labels" and select `ok-to-test` to trigger the build and
  `ok-to-upload` to upload the resulting artifacts.

To stop a build or prevent uploads:

- Navigate to the pull request page.
- In the right-hand sidebar, find the "Labels" section.
- Remove the `ok-to-test` or `ok-to-upload` label as necessary.

## Configuration

The workflow references a separate .github/workflows/build.yml file to execute
the actual build steps. This should be agnostic to your changes.

Below is how to customize your build configuration:

### Specifying Repos and Branches

You can specify which repositories and branches the workflow should use by
modifying the apps variable in the `ci.yml` workflow. This is a JSON array
where each entry defines the repository and the branch to be used.

#### Example:

```yaml
apps: '[{"repo": "nubificus/esp-idf-http-camera", "branch":"feat_nbfc"}]'
```
where 
- `repo`: The repository where the firmware source is located (e.g., `nubificus/esp-idf-http-camera`).
- `branch`: The branch from which to pull the source code (e.g., `feat_nbfc`).

### Adding/Removing Repositories
To build firmware from multiple repositories, update the apps array with additional repository configurations:

#### Example:

```yaml
apps: '[{"repo": "nubificus/esp-idf-http-camera", "branch":"feat_nbfc"}, {"repo": "nubificus/esp32-ota-update", "branch":"main"}]'
```

### Specifying Keys

The keys array is used to define any secrets (e.g., signing keys) that need to
be passed to the build process. These should correspond to GitHub Action
secrets.

Example:

```yaml
keys: '["ESP32_KEY1","ESP32_KEY2"]'
```

To add or remove keys, modify the keys array accordingly.

### Custom Builder Image

The `builder_image` option allows you to specify the Docker image used for
building the firmware. You can change this based on your environment needs:

#### Example:

```yaml
builder_image: 'harbor.nbfc.io/nubificus/esp-idf:x86_64-slim'
```

Currently, the image used is built from the Dockerfile in this repo using the
following command:

```
docker build -t harbor.nbfc.io/nubificus/esp-idf:x86_64-slim --build-arg IDF_CLONE_SHALLOW=1   --build-arg IDF_INSTALL_TARGETS="esp32,esp32s2,esp32s3" -f Dockerfile .
```

### Specifying targets

You can produce binaries for all available variants of ESP32 devices (`esp32`,
`esp32s2`, `esp32s3`), or for some of them. This option is customized using the
`targets` param.

Example:

```yaml
targets: '["esp32", "esp32s3"]'
```

## Triggering

The workflow can be triggered manually, via the UI, or via the GH API. An
example bash script is included for reference.
