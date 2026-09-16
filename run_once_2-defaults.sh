#!/bin/bash

if test "$(uname)" != "Darwin"; then exit 0; fi

# Some from https://github.com/mathiasbynens/dotfiles/blob/master/.macos

# always show scrollbars
defaults write -g AppleShowScrollBars -string "Always"

# allow key repeat
defaults write -g ApplePressAndHoldEnabled -bool false

# remove delay on the dang window icon, and enable it again on Monterey
defaults write -g NSToolbarTitleViewRolloverDelay -float 0

if [ "$(defaults read com.apple.universalaccess showWindowTitlebarIcons 2>/dev/null)" != "1" ]; then
	echo "Updating showWindowTitlebarIcons requires sudo..."
	sudo defaults write com.apple.universalaccess showWindowTitlebarIcons -bool YES
fi

# show timing in xcode
defaults write com.apple.dt.Xcode ShowBuildOperationDuration YES

# show indexing logging in xcode
defaults write com.apple.dt.Xcode IDEIndexShowLog -bool YES

# prevents xcode from using state restoration
defaults write com.apple.dt.Xcode ApplePersistenceIgnoreState -bool YES

# simulator preferences
defaults write com.apple.iphonesimulator ShowSingleTouches -bool true
defaults write com.apple.iphonesimulator PasteboardAutomaticSync -bool false
defaults write com.apple.iphonesimulator ScreenShotUseMask -bool false

# Expand save panel by default
defaults write -g NSNavPanelExpandedStateForSaveMode -bool true
defaults write -g NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
defaults write -g PMPrintingExpandedStateForPrint -bool true
defaults write -g PMPrintingExpandedStateForPrint2 -bool true

# Save to disk (not to iCloud) by default
defaults write -g NSDocumentSaveNewDocumentsToCloud -bool false

# Show the ~/Library folder
chflags nohidden ~/Library
xattr -d com.apple.FinderInfo ~/Library 2>/dev/null || true

# disable text replacements, where possible
defaults write -g WebAutomaticTextReplacementEnabled -bool false
defaults delete -g NSUserDictionaryReplacementItems || true

# disable automatic termination because this isn't an iphone
defaults write -g NSDisableAutomaticTermination -bool true

# disable screenshot thumbnails
defaults write com.apple.screencapture show-thumbnail -bool false

# search current folder by default in finder
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
