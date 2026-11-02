cask "117terminal" do
  arch arm: "arm64", intel: "x64"

  version "0.1.3"
  sha256 arm:   "f1fc857ce0c1ff5daa7a8fc148e4192448a2078a02dc0668e2ed376a9959e067",
         intel: "e1426c80b79832650439e75a852914f21759afe593465dfa2f404996b92c55c1"

  url "https://github.com/1985epma/117-terminal/releases/download/v#{version}/117Terminal-#{version}-mac-#{arch}.dmg"
  name "117Terminal"
  desc "Block-based terminal with Agent Mode, zsh extensions and MCP"
  homepage "https://github.com/1985epma/117-terminal"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :ventura

  # Electron finds its helper apps next to the path it was started from, so a symlink to the
  # executable crashes; a small wrapper script runs the real path instead.
  app "117Terminal.app"
  # `117terminal --serve` runs it headless for a browser (HarmonyOS, tablets).
  binary "117terminal.wrapper.sh", target: "117terminal"

  preflight_steps do
    write_file "117terminal.wrapper.sh", <<~EOS
      #!/bin/sh
      for dir in /Applications "$HOME/Applications"; do
        app="$dir/117Terminal.app/Contents/MacOS/117Terminal"
        [ -x "$app" ] && exec "$app" "$@"
      done
      echo "117terminal: 117Terminal.app not found in /Applications or ~/Applications" >&2
      exit 1
    EOS
    set_permissions "117terminal.wrapper.sh", "0755"
  end

  # The app is ad-hoc signed only (not notarized by Apple); remove the quarantine flag so it opens
  # without a Gatekeeper warning.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/117Terminal.app"]
  end

  zap trash: [
    "~/.117terminal",
    "~/Library/Application Support/117Terminal",
    "~/Library/Preferences/dev.117terminal.app.plist",
  ]
end
