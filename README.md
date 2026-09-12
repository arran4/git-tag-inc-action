# git-tag-inc GitHub Action

This GitHub Action downloads, installs, and optionally runs [`git-tag-inc`](https://github.com/arran4/git-tag-inc).

## Usage

```yaml
name: Example workflow
on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7

      - name: Use git-tag-inc Action
        uses: arran4/git-tag-inc-action@v1
        with:
          # Optional: specify an action
          action: 'patch'

      - name: Use git-tag-inc Action (Minor)
        uses: arran4/git-tag-inc-action@v1
        with:
          action: 'minor'

      - name: Use git-tag-inc Action (Combination)
        uses: arran4/git-tag-inc-action@v1
        with:
          action: 'patch rc2'

      - name: Use git-tag-inc Action (skip forwards)
        uses: arran4/git-tag-inc-action@v1
        with:
          action: '--skip-forwards test1'

      - name: Use git-tag-inc Action (override ref for dev testing)
        uses: arran4/git-tag-inc-action@v1
        with:
          ref: 'main'

      - name: Use git-tag-inc Action (dry run)
        uses: arran4/git-tag-inc-action@v1
        with:
          action: '--dry patch'

      - name: Use git-tag-inc Action (capture version)
        id: tagger
        uses: arran4/git-tag-inc-action@v1
        with:
          action: 'patch'
      - name: Print captured version
        run: echo "The new version is ${{ steps.tagger.outputs.version }}"
```

For release-critical workflows, pin the `git-tag-inc` release and independently pin its archive digest:

```yaml
- name: Install pinned git-tag-inc
  uses: arran4/git-tag-inc-action@v1
  with:
    mode: install
    version: v1.3.10
    sha256: 4fab8594ffff76ef99cb911baf0fe3126e4674a4fda2194d33d4f37993f82d9d
```

The `sha256` input is optional for backwards compatibility, but it is recommended whenever the installed CLI participates in release/version decisions. Supplying it makes installation fail closed if the downloaded archive does not match the expected digest.

```yaml
on:
  workflow_dispatch:
    inputs:
      action:
        description: 'The action to run with git-tag-inc'
        type: choice
        required: true
        default: 'patch'
        options:
          - patch
          - minor
          - major
          - release
          - test
          - uat
          - alpha
          - beta
          - rc
          - next

jobs:
  tag:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - name: Run git-tag-inc
        uses: arran4/git-tag-inc-action@v1
        with:
          action: ${{ github.event.inputs.action }}
```

Action inputs are passed to shell steps through environment variables rather than interpolated directly into shell source. The `action` input is split into an argument array before invoking `git-tag-inc`, so workflow/user input cannot introduce shell operators.

## Inputs

| Name | Description | Default | Required |
|---|---|---|---|
| `version` | The version of `git-tag-inc` to install (e.g. `latest`, `v0.0.18`). | `latest` | No |
| `sha256` | Expected SHA256 of the downloaded release archive. Recommended for release-critical pinned installs. | `''` | No |
| `github-token` | GitHub token to authenticate API requests to prevent rate limiting. | `${{ github.token }}` | No |
| `ref` | The branch, tag, or ref to run from instead of downloading a specific version (e.g. `main`, `v0.0.18`). This overrides `version` and builds from source using `go install` for development/testing purposes. | `''` | No |
| `action` | The arguments to pass to `git-tag-inc`, separated by whitespace. | `''` | No |
| `mode` | The execution mode: `install`, `install and run`, or `run`. | `install and run` | No |

## Outputs

| Name | Description |
|---|---|
| `version` | The resulting version tag after running `git-tag-inc`. |

## License

This action is distributed under the same terms as the `git-tag-inc` tool itself. See the `LICENSE` file for details.
