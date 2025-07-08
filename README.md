# DGlider

**DGlider** is a modular mouse gesture engine that enhances productivity through fully customizable directional gestures. Built with AutoHotkey and Python, it features a flexible configuration system and a GUI for gesture editing.

Imagine your mouse as a gateway to a temple. Each mouse button represents a different “floor” in this temple — and each floor contains five wands, one in each cardinal direction and one right beneath your feet. When you hold a mouse button, you enter that floor. Move your mouse in a direction (up, down, left, right, or just remaining still), then release — and DGlider casts the corresponding actions like spells. (god i play too much Noita)

## Features

### Core Engine
- **Directional gesture recognition**: Up / Down / Left / Right / Default
- **Per-hotkey gesture mapping**: Configure multiple hotkey combinations
- **Action types**: Trigger key sequences or built-in functions
- **Configurable threshold**: Adjust gesture sensitivity
- **Comprehensive logging**: Track all gesture activities

### GUI Features
- **Modern tabbed interface**: Organized configuration management
- **Mouse button selection**: Choose which mouse button to use
- **Hotkey library**: Extensive collection of pre-defined shortcuts
- **Live preview**: See your configuration before applying
- **Multiple export formats**: JSON, INI, and AutoHotkey script generation
- **Configuration management**: Save, load, and manage multiple profiles
- **Log viewer**: Monitor gesture usage and debug issues

### Hotkey Library Categories
- **System**: Copy, Paste, Cut, Undo, Redo, Save, etc.
- **Navigation**: Alt+Tab, Windows key shortcuts, Task Manager
- **Browser**: Tab management, refresh, developer tools
- **Media**: Play/pause, volume control, track navigation
- **Functions**: Custom function calls (expandable)

## Project Status

DGlider now features a GUI interface for configuration management. The gesture engine is somewhat functional with logging and multiple export options.

## Tech Stack

- **AutoHotkey (v1)**: Core gesture engine
- **Python 3.x**: GUI application with tkinter
- **JSON/INI**: Configuration formats
- **Modern UI**: Tabbed interface with scrollable areas

## Getting Started

### Prerequisites
1. **AutoHotkey v1**: Download from [autohotkey.com](https://autohotkey.com)
2. **Python 3.x**

### Quick Start
1. **Clone this repository**
2. **Launch the GUI**: Run the .bat file
3. **Configure gestures**: Use the GUI to set up your preferred shortcuts
4. **Export configuration**: Generate AutoHotkey script or save as JSON/INI
5. **Run the engine**: Execute `GestureV1.ahk` to activate gestures

### Using the GUI

#### Gesture Configuration Tab
- Select mouse button for gestures
- Add/remove hotkey combinations
- Configure actions for each direction (↑↓←→●)
- Browse the hotkey library for quick assignment

#### Settings Tab
- Adjust gesture threshold (sensitivity)
- Configure auto-save options
- Manage configuration files

#### Hotkey Library Tab
- Browse pre-defined shortcuts by category
- Add custom categories and hotkeys
- Edit existing library entries

#### Preview & Export Tab
- View complete configuration
- Export to AutoHotkey script
- Save as JSON or INI format

### Example Usage
1. Press and hold `Ctrl+Alt+1` (you can assign a mouse button)
2. Move mouse **up** → Copy (Ctrl+C)
3. Move mouse **down** → Paste (Ctrl+V)
4. Move mouse **left** → Undo (Ctrl+Z)
5. Move mouse **right** → Redo (Ctrl+Y)
6. Release without moving → Screenshot (Win+Shift+S)

## Configuration Files

### Sample Configuration



