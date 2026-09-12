# Agent Guidelines for git-tag-inc-action Repository

This repository is a GitHub composite action (`git-tag-inc-action`) for downloading, installing, and executing `git-tag-inc`.

When working on this codebase, please adhere to the following rules and guidelines.

## 1. Updating `AGENTS.md`
- Consider updating `AGENTS.md` when you discover highly important new insights, patterns, or critical information about the repository. Ensure any updates are concise and generally applicable, and avoid overly frequent or minor updates.

## 2. Updating `README.md`
- When adding new features, making significant behavioral changes, or altering the public API of this GitHub Action, you must review and update `README.md` accordingly. Ensure that user-facing documentation accurately reflects the current capabilities and usage requirements.

## 3. CI Workflows and Matrices
- The CI workflow (e.g., `.github/workflows/ci.yml`) uses a `route` job to dynamically generate workflow parameters and test matrices (such as `os_matrix`). These are passed to downstream jobs via outputs.

## 4. Testing `git-tag-inc` CLI
- The `git-tag-inc` CLI tool returns an exit code of `255` when run with `--help` or no arguments.
- **Do not** use `git-tag-inc --help` or just `git-tag-inc` to test installation in CI environments.
- **Instead**, to verify its installation without triggering false failures, use a specific valid subcommand such as `git-tag-inc lint --help`, which returns an exit code of `0`.

## 5. Release and Versioning
- Releases for this GitHub action rely on semantic tagging.
- **Major version tags** (e.g., `v1`, `v2`) must be updated to point to the latest minor/patch release.

## 6. Shell Script Execution in Composite Actions
- In this repository's composite action configurations (like `action.yml`), shell scripts should be executed explicitly using `bash`.
- For example, use: `bash $GITHUB_ACTION_PATH/setup.sh`.
- **Do not** call them directly. This prevents "Permission denied" (exit code 126) errors caused by lost executable bits in the runner environment.
- **Never interpolate action inputs directly into `run:` shell source.** Pass inputs through step `env:` variables or positional arguments, then quote/parse them as data inside the shell script.
- When an input represents multiple CLI arguments, construct an argument array and invoke the target command with `"${args[@]}"`; do not use `eval`.

## 7. Release-critical binary installation
- Production/release workflows should be able to pin both the `git-tag-inc` release version and the expected SHA256 of the downloaded archive.
- Keep checksum verification inside the action so downstream repositories do not need to duplicate installer scripts.
- Preserve backwards compatibility where practical, but document that release-critical callers should supply the checksum pin.

## 8. Local Execution of Setup Scripts
- Local execution of `setup.sh` requires simulating the GitHub Actions runner environment.
- You must set variables like `RUNNER_OS` and `RUNNER_ARCH`.
- Example: `RUNNER_OS=Linux RUNNER_ARCH=X86 ./setup.sh latest ""`

## 9. Validation Techniques
- **YAML configurations**: Can be validated using PyYAML (installable via `python3 -m pip install pyyaml`) and evaluated with `python3 -c 'import yaml; yaml.safe_load(open("filename.yml"))'`.
- **Shell scripts**: Can be syntax-checked using `bash -n`.
