class Codingbooth < Formula
  desc "Reproducible, containerized dev environments for any project"
  homepage "https://codingbooth.io"
  url "https://github.com/NawaMan/CodingBooth/releases/download/0.80.0/booth"
  sha256 "965458b7c132474692247e82bfe866c2e6e64a78b5b370cde528006963fa7644"
  license "Apache-2.0"

  # Not :github_latest: the repo also has a moving "latest" release.
  livecheck do
    url :stable
    strategy :github_releases
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  def install
    bin.install "booth"
  end

  def caveats
    <<~EOS
      CodingBooth needs Docker (Docker Desktop on macOS; rootful Docker Engine on Linux).
      Start a project with:  cd my-project && booth install
      Downloaded binaries live in the user cache; before `brew uninstall`, run
        booth uninstall --all-shared-binary   to remove them too.
    EOS
  end

  test do
    assert_match "CodingBooth Wrapper", shell_output("#{bin}/booth version")
  end
end
