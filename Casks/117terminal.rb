cask "117terminal" do
  arch arm: "arm64", intel: "x64"

  version "0.1.1"
  sha256 arm:   "c0f7e0f6ae0cc5b68d0ba14a55d00f66cab873e8157d6f29bd8b66366356c779",
         intel: "15b98a09dd8747d3fa8dc8bb81f23096eb565125582064981bc26492aca8f7b0"

  url "https://github.com/1985epma/117-terminal/releases/download/v#{version}/117Terminal-#{version}-mac-#{arch}.dmg"
  name "117Terminal"
  desc "Block-based terminal with Agent Mode, zsh extensions and MCP"
  homepage "https://github.com/1985epma/117-terminal"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :ventura

  app "117Terminal.app"

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
