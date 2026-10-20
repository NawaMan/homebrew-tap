class Viewmd < Formula
  desc "Browse a folder of Markdown files in your browser"
  homepage "https://github.com/NawaMan/MarkDownViewer"
  license "Apache-2.0"

  livecheck do
    url :homepage
    strategy :github_releases
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  on_macos do
    on_arm do
      url "https://github.com/NawaMan/MarkDownViewer/releases/download/v0.9.0/viewmd-darwin-arm64"
      sha256 "56e69071c1ee255cf04c8326bf076d7e18fe54fa2853ae260d618556a899ac17"
    end
    on_intel do
      url "https://github.com/NawaMan/MarkDownViewer/releases/download/v0.9.0/viewmd-darwin-amd64"
      sha256 "ec2fa43075cdf94d25e9cdf0a7b1f55ca8c6662ebd1e5855063fc742517c787a"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/NawaMan/MarkDownViewer/releases/download/v0.9.0/viewmd-linux-arm64"
      sha256 "0b60319a8cd48416784e92c30f0ec5a133790577fc9071c1656e2b39d6e892f9"
    end
    on_intel do
      url "https://github.com/NawaMan/MarkDownViewer/releases/download/v0.9.0/viewmd-linux-amd64"
      sha256 "3a2bb8f1dfa860e1f9b8684c48ed7620917db377b506e91875687797c19c15d4"
    end
  end

  def install
    bin.install Dir["viewmd-*"].first => "viewmd"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/viewmd --version")
  end
end
