# homebrew-tap

Homebrew formulas for NawaMan's tools.

```sh
brew install nawaman/tap/codingbooth   # CodingBooth — the `booth` wrapper
brew install nawaman/tap/folio         # EnvFolio — texts and secrets on pass, as env vars
brew install nawaman/tap/viewmd        # MarkDownViewer — browse Markdown in the browser
```

`codingbooth` also installs tab completion for bash, zsh and fish (`booth completion <shell>`), once
the release it points at has that command (after 0.80.0). Shells load it through Homebrew's
[shell completion](https://docs.brew.sh/Shell-Completion) setup.

## Updating the formulas

After a release of any of these, run the **Bump formulas** workflow (Actions →
Bump formulas → Run workflow, or `gh workflow run "Bump formulas" -R NawaMan/homebrew-tap`).
It moves every formula to its project's newest stable release, then audits,
installs and tests the bumped ones on Linux, and pushes one commit per formula.
Tick `dry_run` to see the bump without pushing. Nothing newer = nothing pushed.

By hand: `bin/bump-formula.sh Formula/<name>.rb [<X.Y.Z>]`.
Test the script: `tests/test-bump-formula.sh`.
