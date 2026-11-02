class Terminal117 < Formula
  desc "Block-based terminal with Agent Mode, zsh extensions and MCP"
  homepage "https://github.com/1985epma/117-terminal"
  # Linux tarballs from the GitHub release; scripts/bump.sh rewrites both.
  if Hardware::CPU.arm?
    url "https://github.com/1985epma/117-terminal/releases/download/v0.1.3/117Terminal-0.1.3-linux-arm64.tar.gz"
    sha256 "3a69d8d33363b952d12a99aae70b66d790976a0acbc32b1f710cbae158c47f91"
  else
    url "https://github.com/1985epma/117-terminal/releases/download/v0.1.3/117Terminal-0.1.3-linux-x64.tar.gz"
    sha256 "115e3b78c87daa5ec63deb2569763d7f5cf2a594eb5f7205a9a1d3b70dc6f610"
  end
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

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
