# AutoHotkeyUX

Installer and other scripts packaged with AutoHotkey v2, aimed at improving the overall user experience.

Most of the content of this repository ends up in the UX subdirectory of an AutoHotkey installation. `tools` is excluded.

Documentation for users is included with AutoHotkey v2, under [Using the Program](https://lexikos.github.io/v2/docs/Program.htm).
  - [Installation](https://lexikos.github.io/v2/docs/Program.htm#install)
  - [Launcher](https://lexikos.github.io/v2/docs/Program.htm#launcher)
  - [Dash](https://lexikos.github.io/v2/docs/Program.htm#dash)
  - [New Script](https://lexikos.github.io/v2/docs/Program.htm#newscript)

See the comments at the top of each `.ahk` file for a brief description. Files in the root directory are generally capable of being executed on their own, but may also be used by the dash. Files beginning with "ui-" will show a GUI, whereas other files might have some immediate action and might not show any visible UI.

The scripts all require AutoHotkey v2. Initially they require v2.0-beta.3 or v2.0-beta.4 as indicated by `#Requires`, but requirements may change.
