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
      url "https://github.com/NawaMan/MarkDownViewer/releases/download/v0.10.0/viewmd-darwin-arm64"
      sha256 "9f7796a8bb41c62904ede7ef57367c6310d51d0f4b362a755af67ea4be8ca2fa"
    end
    on_intel do
      url "https://github.com/NawaMan/MarkDownViewer/releases/download/v0.10.0/viewmd-darwin-amd64"
      sha256 "5a124cbc4628691529c766385d4890becb07cf06ed14d49f679923429343df7f"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/NawaMan/MarkDownViewer/releases/download/v0.10.0/viewmd-linux-arm64"
      sha256 "1d9556b39ed8c635f0e3fa3126651af3c4f53ff02b6412a69c536d7f8f4d7380"
    end
    on_intel do
      url "https://github.com/NawaMan/MarkDownViewer/releases/download/v0.10.0/viewmd-linux-amd64"
      sha256 "9091055313f901554cb7b209b8460464587ed4e8ca1a5dfd01a28355eb3a1844"
    end
  end

  def install
    bin.install Dir["viewmd-*"].first => "viewmd"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/viewmd --version")
  end
end
