cask "117terminal" do
  arch arm: "arm64", intel: "x64"

  version "0.1.2"
  sha256 arm:   "4d625aacf92ec4fd7042731d1ba6e66caaf032d982707020693cb912eed9ac6f",
         intel: "af22d9d4e00134192ab315c5ec956aa161039b08a8665b8d4651efcfafda764a"

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
