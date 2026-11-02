# homebrew-117terminal

Homebrew tap for [117Terminal](https://github.com/1985epma/117-terminal), a block-based terminal with
Agent Mode, zsh extensions and MCP. By 117-Labs.

## Install

**macOS** (Apple Silicon and Intel, macOS 13 Ventura or newer), installs `117Terminal.app` into `/Applications`
and a `117terminal` command (`117terminal --serve` opens it in a browser, e.g. on a HarmonyOS tablet):

    brew tap 1985epma/117terminal
    brew trust 1985epma/117terminal
    brew install --cask 1985epma/117terminal/117terminal

**Linux** (Homebrew on Linux, x86_64 and arm64):

    brew tap 1985epma/117terminal
    brew trust 1985epma/117terminal
    brew install 1985epma/117terminal/117terminal
    117terminal

Recent Homebrew versions refuse to load packages from third-party taps until you trust them; if you see
`Refusing to load … from untrusted tap`, run the `brew trust` line above once.

On Linux the formula is called `terminal117` (`117terminal` is an alias): Homebrew turns a formula name
into a Ruby class name, and a class cannot start with a digit. Both names work with `brew install`,
`brew upgrade` and `brew uninstall`. The app's desktop libraries come from your distro
(`libnss3`, `libgtk-3-0`, `libxss1`, `libasound2`).

## What the cask does after installing (macOS)

117Terminal is ad-hoc signed but not notarized by Apple, so macOS would block it with a
"cannot verify the developer" warning. The cask's `postflight` removes the quarantine flag:

    xattr -dr com.apple.quarantine /Applications/117Terminal.app

That is the only change it makes. If you installed the `.dmg` by hand, run the same command yourself
(or use System Settings → Privacy & Security → *Open Anyway*).

On Linux the `117terminal` command starts the app with `--no-sandbox`: Electron's `chrome-sandbox` helper
must be owned by root with the setuid bit, which Homebrew cannot set. If you want the sandbox, install the
`.deb` from the [releases](https://github.com/1985epma/117-terminal/releases) instead.

## Uninstall

    brew uninstall --cask 117terminal          # macOS: removes the app
    brew uninstall --zap --cask 117terminal    # macOS: also removes settings and data
    brew uninstall 117terminal                 # Linux

`--zap` deletes `~/Library/Application Support/117Terminal`, `~/.117terminal` and
`~/Library/Preferences/dev.117terminal.app.plist`.

## Maintainers

After a release `vX.Y.Z` is published in `1985epma/117-terminal`:

    scripts/bump.sh X.Y.Z      # downloads the assets, rewrites version + sha256 in the cask and formula
    brew style .
    git commit -am "117terminal X.Y.Z"

## License

[MIT](LICENSE)
