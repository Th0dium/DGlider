# Glidra

**Glidra** is a modular mouse gesture engine designed to enhance productivity through customizable directional gestures. Built with AutoHotkey and Python, it offers a flexible configuration system and aims to support GUI-based gesture editing.

## Features

- Directional gesture recognition: Up / Down / Left / Right / Default
- Per-hotkey gesture mapping
- Trigger key sequences or built-in functions
- Configurable via external `.json` files
- GUI for editing gesture profiles (work in progress)
- Designed with modularity in mind

## Project Status

Glidra is in early development. The gesture engine is functional and supports external config files. A basic GUI is under development to manage gestures and enable dynamic script generation based on user-defined features.

This project is built gradually as a personal side project and is not yet feature-complete.

## Tech Stack

- AutoHotkey (core gesture engine)
- Python (Tkinter-based GUI)
- JSON (configuration format)

## Getting Started

1. Clone this repository.
2. Run `gestures.ahk` to activate the gesture engine.
3. Press one of the defined hotkeys (e.g., Ctrl + Alt + 1), move the mouse in a direction, and trigger the assigned action.

The GUI component is still under development and will be added in future commits.

## Folder Structure (Planned)

Glidra/
├── gestures.ahk # Core gesture engine
├── config/
│ └── gestures.json # Gesture mapping
├── gui/
│ └── main.py # GUI editor (WIP)
└── README.md

shell
Sao chép
Chỉnh sửa

## License

To be determined.
