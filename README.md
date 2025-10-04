# DGlider

DGlider is a modular mouse-gesture engine for Windows (AutoHotkey v1) with a flexible, profile‑based configuration. It lets you bind directional gestures (Up, Down, Left, Right, Default) per hotkey (keyboard/mouse) to send keys or call functions.

## Features

- Directional gesture recognition: Up / Down / Left / Right / Default
- Per‑hotkey gesture mapping (keyboard combos and mouse buttons)
- Action types: send key sequences or call built‑in functions (`fn:Name`)
- Profiles: multiple profiles in one INI, with per‑profile hotkey sections
- Per‑profile disabled hotkeys (choose which hotkeys are untracked)
- Logging for debugging (Desktop\Log\gesture_log.txt)

## Getting Started

Prerequisites
- AutoHotkey v1
- Python 3.x (for the separate GUI, if used)

Quick Start
1. Run `GestureV1.ahk` to activate gestures.
2. Edit `gesture_config.ini` to customize mappings.
3. Use a gesture mapped to `fn:SelectProfile` to switch profiles via a small selector GUI.

Example Usage
1. Hold `Ctrl+Alt+1` (or a mouse button you’ve mapped).
2. Move mouse Up → Copy (Ctrl+C)
3. Move mouse Down → Paste (Ctrl+V)
4. Move mouse Left → Undo (Ctrl+Z)
5. Move mouse Right → Redo (Ctrl+Y)
6. Release without moving (Default) → e.g. Screenshot

## Configuration Overview

The config file `gesture_config.ini` stores everything.

- `[Settings]` → `ActiveProfile` selects which profile is active.
- `[Profiles]` → `Names` lists available profiles (comma/pipe/semicolon separated).
- For each profile, gestures live under sections:
  - `Profile_<profile>_Hotkey_<hotkey>` with keys: `up`, `down`, `left`, `right`, `default`.
  - Example hotkeys: `^!1`..`^!8`, `{mbutton}`, `{rbutton}`, `{xbutton1}`, `{xbutton2}`.
- Empty directions should be written as `{}` (no‑op). The engine ignores `{}`.

Example (simplified)

```
[Settings]
ActiveProfile=dglider

[Profiles]
Names=dglider,default,Off

[Profile_dglider_Hotkey_^!2]
up=fn:SelectProfile
default={Enter}

[Profile_default_Hotkey_^!2]
default={Enter}

[Profile_dglider_Hotkey_{xbutton1}]
right=^+{Tab}
down=^+{t}
up=^{w}
default=!{left}

[Profile_default_Hotkey_{xbutton1}]
default=^!5
```

## Profiles

- Multiple profiles in the same file: e.g., `dglider`, `default`, `Off`.
- Select a profile via gesture mapped to `fn:SelectProfile` (opens a two‑column selector GUI) or `fn:ProfilePrompt` (input box).
- The script logs active profile per gesture for transparency.

Per‑Profile Disabled Hotkeys
- Each profile can disable any subset of gesture hotkeys so they are not tracked (pass‑through behavior).
- Section: `Profile_<profile>_Disabled` with `Keys` listing the disabled hotkeys.
- Format: comma/pipe/semicolon separated; case‑insensitive. Examples:
  - Mouse only: `Keys={mbutton},{rbutton}`
  - XButtons: `Keys={xbutton1},{xbutton2}`
  - Specific keys: `Keys=^!5,^!6`
  - Disable all (like Off): `Keys=^!1,^!2,^!3,^!4,^!5,^!6,^!7,^!8,{mbutton},{rbutton},{xbutton1},{xbutton2}`

## Built‑in Functions

- `fn:SelectProfile` — open the profile selector GUI (two columns of buttons).
- `fn:ProfilePrompt` — prompt to enter/select a profile by name.
- `fn:TypeText` — prompt for text and type it raw.
- `fn:SCI` — save clipboard image to `C:\EpsteinBackupDrive\SavedPictures\yyyy-MM-dd_HH-mm-ss.png`.
- `fn:VolumeOSD` — show a simple volume OSD at the bottom‑left; use mouse wheel to adjust.

## Volume OSD Notes

- When the OSD opens, the script enables wheel handling immediately to avoid missing the first wheel tick.
- The wheel hotkeys are active only while OSD is open; they won’t interfere otherwise.

## Tips

- Use `{}` for “no action” to keep INI fields explicit and avoid parse quirks.
- You can assign mouse buttons and keyboard combos in the same profile.
- Logs live at Desktop\Log\gesture_log.txt for troubleshooting.

