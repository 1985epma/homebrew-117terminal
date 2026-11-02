class Terminal117 < Formula
  desc "Block-based terminal with Agent Mode, zsh extensions and MCP"
  homepage "https://github.com/1985epma/117-terminal"
  # Linux x64 tarball from the GitHub release. If the asset name changes, edit only this line.
  url "https://github.com/1985epma/117-terminal/releases/download/v0.1.2/117Terminal-0.1.2-linux-x64.tar.gz"
  sha256 "562838a87e2710db05b65cc1c2f28d36f708a2d3ad6a7bd5f4a28a99cd451308"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on arch: :x86_64
  depends_on :linux

  def install
    # Homebrew already cd's into the tarball's single top-level folder.
    libexec.install Dir["*"]
    # chrome-sandbox would need to be setuid root, which Homebrew cannot do, so run without the sandbox.
    (bin/"117terminal").write <<~SH
      #!/bin/bash
      exec "#{libexec}/117terminal" --no-sandbox "$@"
    SH
  end

  def caveats
    <<~EOS
      117Terminal is a GUI app (Electron). It needs the usual desktop libraries from your
      distro (e.g. libnss3, libgtk-3-0, libxss1, libasound2). Start it with:
        117terminal
      It runs with --no-sandbox: Electron's chrome-sandbox helper must be owned by root,
      which Homebrew does not do. Use the .deb from the GitHub release if you need the sandbox.
    EOS
  end

  test do
    assert_predicate libexec/"117terminal", :executable?
    assert_path_exists libexec/"resources"
    assert_predicate bin/"117terminal", :executable?
    assert_match "--no-sandbox", (bin/"117terminal").read
  end
end
