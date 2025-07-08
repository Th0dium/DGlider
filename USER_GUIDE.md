# DGlider User Guide

## Table of Contents
1. [Installation](#installation)
2. [GUI Overview](#gui-overview)
3. [Configuration](#configuration)
4. [Hotkey Library](#hotkey-library)
5. [Advanced Features](#advanced-features)
6. [Troubleshooting](#troubleshooting)

## Installation

### Requirements
- Windows OS
- AutoHotkey v1.1+ 
- Python 3.6+ (for GUI)

### Setup Steps
1. Download and install AutoHotkey from [autohotkey.com](https://autohotkey.com)
2. Clone or download DGlider project
3. Navigate to DGlider folder
4. Run `python gesture_gui.py` to launch the configuration GUI

## GUI Overview

### Main Interface
The DGlider GUI features a modern tabbed interface with four main sections:

#### 1. Gesture Configuration Tab
- **Mouse Button Selection**: Choose which mouse button triggers gestures
- **Hotkey Management**: Add/remove hotkey combinations
- **Direction Mapping**: Configure actions for each gesture direction
- **Library Integration**: Browse and assign from hotkey library

#### 2. Settings Tab
- **Gesture Threshold**: Adjust sensitivity (10-100 pixels)
- **Auto-save**: Automatically save changes
- **Configuration File**: View current config file

#### 3. Hotkey Library Tab
- **Categories**: Organized shortcut collections
- **Management**: Add/edit/delete categories and hotkeys
- **Quick Assignment**: Double-click to use in gestures

#### 4. Preview & Export Tab
- **Live Preview**: See complete configuration
- **Export Options**: Generate AHK script, JSON, or INI files
- **Validation**: Check configuration before use

## Configuration

### Basic Setup

1. **Launch GUI**: Run `python gesture_gui.py`
2. **Load Sample**: File → Open Config → `sample_config.json`
3. **Customize**: Modify gestures to your preferences
4. **Export**: Preview & Export → Export to AHK
5. **Activate**: Run the generated `.ahk` file

### Adding Hotkeys

1. Go to **Gesture Configuration** tab
2. Click **Add Hotkey** button
3. Enter hotkey combination (e.g., `^!1` for Ctrl+Alt+1)
4. Configure actions for each direction
5. Save configuration

### Gesture Directions

- **↑ Up**: Move mouse upward while holding hotkey
- **↓ Down**: Move mouse downward while holding hotkey  
- **← Left**: Move mouse left while holding hotkey
- **→ Right**: Move mouse right while holding hotkey
- **● Default**: Release hotkey without moving mouse

### Action Types

#### Keyboard Shortcuts
- `^c` = Ctrl+C (Copy)
- `!{Tab}` = Alt+Tab (Switch windows)
- `{LWin}d` = Windows+D (Show desktop)

#### Function Calls
- `fn:SCI` = Call SCI() function (screenshot to clipboard)
- `fn:CustomFunc` = Call custom function

## Hotkey Library

### Built-in Categories

#### System
- Copy, Paste, Cut, Undo, Redo
- Save, Open, New, Close
- Select All, Quit

#### Navigation  
- Alt+Tab, Windows shortcuts
- Task Manager, File Explorer
- Run Dialog, Settings

#### Browser
- Tab management (New, Close, Switch)
- Refresh, Developer Tools
- Bookmarks, History

#### Media
- Play/Pause, Next/Previous Track
- Volume Up/Down/Mute

#### Functions
- Screenshot functions
- Custom user functions

### Managing Library

#### Adding Categories
1. Go to **Hotkey Library** tab
2. Click **Add Category**
3. Enter category name
4. Click OK

#### Adding Hotkeys
1. Select a category
2. Click **Add Hotkey**
3. Enter action name and hotkey/function
4. Click OK

#### Editing Hotkeys
1. Select hotkey in tree view
2. Click **Edit Selected**
3. Modify name or hotkey
4. Click OK

## Advanced Features

### Configuration Files

#### JSON Format
```json
{
    "^!1": {
        "up": "^c",
        "down": "^v", 
        "left": "^z",
        "right": "^y",
        "default": "fn:SCI"
    }
}
```

#### INI Format
```ini
[Hotkey_^!1]
up=^c
down=^v
left=^z
right=^y
default=fn:SCI
```

### Custom Functions

Add custom functions to AutoHotkey script:

```autohotkey
CustomFunc() {
    ; Your custom code here
    MsgBox, Custom function executed!
}
```

### Gesture Threshold

- **Low (10-30)**: Very sensitive, small movements trigger
- **Medium (30-60)**: Balanced sensitivity  
- **High (60-100)**: Requires larger movements

### Auto-Export

Enable auto-save to automatically update configuration files when changes are made.

## Troubleshooting

### Common Issues

#### GUI Won't Start
- Check Python installation
- Ensure tkinter is available
- Run from command line to see errors

#### Gestures Not Working
- Verify AutoHotkey is running
- Check hotkey conflicts with other software
- Review gesture threshold settings
- Check log files for errors

#### Configuration Not Loading
- Verify file format (JSON/INI)
- Check file permissions
- Validate JSON syntax

### Log Files

Gesture logs are saved to:
`~/Desktop/Log/gesture_log.txt`

Use **Tools → View Logs** to monitor activity.

### Getting Help

1. Check this user guide
2. Review **Help → Hotkey Reference** in GUI
3. Examine sample configurations
4. Check log files for error messages

## Tips & Best Practices

### Gesture Design
- Use intuitive directions (up=copy, down=paste)
- Group related functions on same hotkey
- Keep frequently used actions on default gesture

### Performance
- Limit number of active hotkeys
- Use appropriate gesture threshold
- Regular log cleanup

### Backup
- Save multiple configuration profiles
- Export configurations before major changes
- Keep backup of working AutoHotkey scripts
