class Folio < Formula
  desc "Store texts and secrets on pass and load them as environment variables"
  homepage "https://github.com/NawaMan/EnvFolio"
  url "https://github.com/NawaMan/EnvFolio/releases/download/v1.1.0/folio"
  sha256 "c3739c8ddb9a2d54a78f5144244e2ee2b0d29d9f7fb6bbb6a7107e350ef7aa1c"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_releases
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  depends_on "git"
  depends_on "pass"
  depends_on "tree"

  def install
    bin.install "folio"
    chmod 0755, bin/"folio" # the download is not executable until the install ends
    generate_completions_from_executable(bin/"folio", "completion", shells: [:bash, :zsh])
  end

  def caveats
    <<~EOS
      EnvFolio (the folio command) keeps its store in ~/.folio (or $FOLIO_STORE_DIR).
      Create it with:  folio init

      Tab completion is installed for bash (needs bash-completion@2) and zsh
      (needs #{HOMEBREW_PREFIX}/share/zsh/site-functions on fpath before compinit).
      Otherwise: eval "$(folio completion bash)" or eval "$(folio completion zsh)".

      gpg 2.5.24 (Homebrew's gnupg at the time of writing) breaks
      `folio restore`, `folio import` and `--from`; folio warns when it finds it.
      gpg 2.4.x works.
    EOS
  end

  test do
    assert_match "EnvFolio #{version}", shell_output("#{bin}/folio version")
    assert_match "complete -o filenames -F _folio folio", (bash_completion/"folio").read
    assert_match "#compdef folio", (zsh_completion/"_folio").read
  end
end
