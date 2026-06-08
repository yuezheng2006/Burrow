# Homebrew cask for 拂尘 (Fuchen).
#
# Template for a tap (e.g. caezium/homebrew-tap). After a GitHub release,
# set `version` + `sha256`, copy to `Casks/fuchen.rb`, then:
#
#   brew install --cask caezium/tap/fuchen
#
cask "fuchen" do
  version "0.0.1"
  sha256 "700841fe29b7f72fdc28951fe9da8558d92518f5d4a7365ad098555a57a4dcb9"

  url "https://github.com/yuezheng2006/fuchen/releases/download/v#{version}/Fuchen-#{version}.zip"
  name "Fuchen"
  desc "Free, open-source native GUI for the Mole CLI (Chinese UI)"
  homepage "https://github.com/yuezheng2006/fuchen"

  depends_on formula: "mole"
  depends_on macos: ">= :sonoma"

  app "Fuchen.app"

  postflight do
    system_command "/usr/bin/xattr", args: ["-cr", "#{appdir}/Fuchen.app"], sudo: false
  end

  caveats <<~EOS
    Fuchen is an unsigned pre-1.0 build. If macOS still blocks it, right-click
    the app and choose Open, or run:  xattr -cr "#{appdir}/Fuchen.app"
  EOS

  zap trash: [
    "~/Library/Application Support/Fuchen",
    "~/Library/Preferences/dev.yuezheng2006.Fuchen.plist",
  ]
end
