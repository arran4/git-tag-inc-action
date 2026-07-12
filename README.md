# git-tag-inc GitHub Action

This GitHub Action downloads and installs [`git-tag-inc`](https://github.com/arran4/git-tag-inc).

## Usage

```yaml
name: Example workflow
on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

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
      - uses: actions/checkout@v4
      - name: Run git-tag-inc
        uses: arran4/git-tag-inc-action@v1
        with:
          action: ${{ github.event.inputs.action }}
```

## Inputs

| Name | Description | Default | Required |
|---|---|---|---|
| `version` | The version of `git-tag-inc` to install (e.g. `latest`, `v0.0.18`). | `latest` | No |
| `github-token` | GitHub token to authenticate API requests to prevent rate limiting. | `${{ github.token }}` | No |
| `ref` | The branch, tag, or ref to run from instead of downloading a specific version (e.g., `main`, `v0.0.18`). This overrides `version` and builds from source using go install for dev testing purposes. | `''` | No |
| `action` | The action to run with `git-tag-inc`. | `''` | No |
| `mode` | The execution mode: `install`, `install and run`, or `run`. | `install and run` | No |

## Outputs

| Name | Description |
|---|---|
| `version` | The resulting version tag after running `git-tag-inc`. |

## License

This action is distributed under the same terms as the `git-tag-inc` tool itself. See the `LICENSE` file for details.
