# homebrew-tap

Homebrew formulas for NawaMan's tools.

```sh
brew install nawaman/tap/codingbooth   # CodingBooth — the `booth` wrapper
brew install nawaman/tap/folio         # EnvFolio — texts and secrets on pass, as env vars
brew install nawaman/tap/viewmd        # MarkDownViewer — browse Markdown in the browser
```

## Updating the formulas

After a release of any of these, run the **Bump formulas** workflow (Actions →
Bump formulas → Run workflow, or `gh workflow run "Bump formulas" -R NawaMan/homebrew-tap`).
It moves every formula to its project's newest stable release, then audits,
installs and tests the bumped ones on Linux, and pushes one commit per formula.
Tick `dry_run` to see the bump without pushing. Nothing newer = nothing pushed.

By hand: `bin/bump-formula.sh Formula/<name>.rb [<X.Y.Z>]`.
Test the script: `tests/test-bump-formula.sh`.
