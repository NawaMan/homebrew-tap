class Folio < Formula
  desc "Store texts and secrets on pass and load them as environment variables"
  homepage "https://github.com/NawaMan/EnvFolio"
  url "https://github.com/NawaMan/EnvFolio/releases/download/v1.0.0/folio"
  sha256 "e23d33092f2cc6674bc060376b392c69cb459bab66d5555df430035d7a74b478"
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
  end

  def caveats
    <<~EOS
      EnvFolio (the folio command) keeps its store in ~/.folio (or $FOLIO_STORE_DIR).
      Create it with:  folio init

      gpg 2.5.24 (Homebrew's gnupg at the time of writing) breaks
      `folio restore`, `folio import` and `--from`; folio warns when it finds it.
      gpg 2.4.x works.
    EOS
  end

  test do
    assert_match "EnvFolio #{version}", shell_output("#{bin}/folio version")
  end
end
