class Folio < Formula
  desc "Store texts and secrets on pass and load them as environment variables"
  homepage "https://github.com/NawaMan/EnvFolio"
  url "https://github.com/NawaMan/EnvFolio/releases/download/v1.0.0/folio"
  sha256 "61150fbb3fbd78eeff41de6c9a730a9713e9a83dc35a68f27c200063d218d517"
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
