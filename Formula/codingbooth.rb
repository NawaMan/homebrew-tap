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
    # `booth completion bash|zsh|fish` arrived after 0.80.0; older wrappers would
    # hand the unknown command to the binary, so ask only one that has it.
    return unless (bin/"booth").read.include?("booth completion bash")

    chmod 0755, bin/"booth" # the download is not executable until the install ends
    generate_completions_from_executable(bin/"booth", "completion")
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
    return unless (bin/"booth").read.include?("booth completion bash")

    assert_match "complete -F _booth_completion booth", (bash_completion/"booth").read
    assert_match "#compdef booth", (zsh_completion/"_booth").read
    assert_match "complete -c booth", (fish_completion/"booth.fish").read
    assert_match "shell-config", shell_output("#{bin}/booth __complete sh")
  end
end
