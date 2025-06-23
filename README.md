# DGlider

**DGlider** is a modular mouse gesture engine that enhances productivity through fully customizable directional gestures. Built with AutoHotkey and Python, it features a flexible configuration system and supports GUI-based gesture editing.

Imagine your mouse as a gateway to a temple. Each mouse button represents a different “floor” in this temple — and each floor contains five wands, one in each cardinal direction and one right beneath your feet. When you hold a mouse button, you enter that floor. Move your mouse in a direction (up, down, left, right, or just remaining still), then release — and DGlider casts the corresponding actions like spells. (god i play too much Noita)

## Features

- Directional gesture recognition: Up / Down / Left / Right / Default
- Per-hotkey gesture mapping
- Trigger key sequences or built-in functions
- Configurable via external `.json` files
- GUI for editing gesture profiles (work in progress)
- Designed with modularity in mind

## Project Status

DGlider is in early development. The gesture engine is functional and supports external config files. A basic GUI is under development to manage gestures and enable dynamic script generation based on user-defined features.

This project is built gradually as a personal side project and is not yet feature-complete.

## Tech Stack

- AutoHotkey (core gesture engine)
- Python (GUI)
- JSON (configuration format)

## Getting Started

1. Clone this repository.
2. Install AHK (v1)
3. Run `GesturesV1.ahk` to activate the gesture engine.
4. Press one of the defined hotkeys (e.g., Ctrl + Alt + 1), move the mouse in a direction, and trigger the assigned action.

The GUI component is still under development and will be added in future commits.


