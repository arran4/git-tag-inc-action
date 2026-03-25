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
```

## Inputs

| Name | Description | Default | Required |
|---|---|---|---|
| `version` | The version of `git-tag-inc` to install (e.g. `latest`, `v0.0.18`). | `latest` | No |
| `github-token` | GitHub token to authenticate API requests to prevent rate limiting. | `${{ github.token }}` | No |
| `action` | The action to run with `git-tag-inc`. | `''` | No |
| `mode` | The execution mode: `install`, `install and run`, or `run`. | `install and run` | No |

## License

This action is distributed under the same terms as the `git-tag-inc` tool itself. See the `LICENSE` file for details.
