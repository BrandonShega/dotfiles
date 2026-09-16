{ pkgs, ... }:

{
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Determinate Nix Installer manages Nix itself, so we keep this false.
  nix.enable = false;

  # macOS system configurations
  system.defaults = {
    NSGlobalDomain = {
      AppleShowScrollBars = "Always";
      ApplePressAndHoldEnabled = false;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      PMPrintingExpandedStateForPrint = true;
      PMPrintingExpandedStateForPrint2 = true;
      NSDocumentSaveNewDocumentsToCloud = false;
      NSDisableAutomaticTermination = true;
    };

    finder = {
      FXDefaultSearchScope = "SCcf";
    };

    screencapture = {
      show-thumbnail = false;
    };

    # Declarative macOS domain preferences
    CustomUserPreferences = {
      "NSGlobalDomain" = {
        NSToolbarTitleViewRolloverDelay = 0.0;
        WebAutomaticTextReplacementEnabled = false;
      };
      "com.apple.dt.Xcode" = {
        ShowBuildOperationDuration = true;
        IDEIndexShowLog = true;
        ApplePersistenceIgnoreState = true;
      };
      "com.apple.iphonesimulator" = {
        ShowSingleTouches = true;
        PasteboardAutomaticSync = false;
        ScreenShotUseMask = false;
      };
    };
  };

  # Activation script running as root for settings requiring elevated privileges
  system.activationScripts.postActivation.text = ''
    # Show the ~/Library folder
    chflags nohidden ~/Library
    xattr -d com.apple.FinderInfo ~/Library 2>/dev/null || true

    # UniversalAccess settings require root/sudo privileges
    defaults write com.apple.universalaccess showWindowTitlebarIcons -bool YES
  '';
}
