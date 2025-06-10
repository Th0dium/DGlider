Glidra
Glidra is an experimental mouse gesture engine built with AutoHotkey and Python, aiming to bring modular control and productivity boosts to your desktop through simple drag gestures.

🔧 Features (Planned / WIP)
⚙️ Fully customizable mouse gestures per hotkey

🖱️ Directional gesture recognition (Up / Down / Left / Right / Default)

🧠 Command mapping: key sequences or built-in functions (e.g., window snap)

📁 Configurable via external .json files

🪟 GUI interface for gesture management (in progress)

🧩 Modular design: plan to assemble custom scripts dynamically based on user-selected functions

📌 Project Status
Glidra is still in its early development stage. The core gesture engine is functional and script-based.
We're currently working on:

Designing a minimal GUI to load and edit gesture configurations

Allowing plug-and-play function modules

Preparing the project for GitHub showcase and portfolio use

This is a side project, actively developed in free time. Feedback and suggestions are welcome.

📦 Tech Stack
AutoHotkey v1

Python (Tkinter for GUI, future expansion to PyQt possible)

JSON for config structure

📁 Folder Structure (Preview)
css
Sao chép
Chỉnh sửa
Glidra/
│
├── gestures.ahk            ; Core gesture engine
├── config/
│   └── gestures.json       ; Gesture mapping per hotkey
├── gui/
│   └── main.py             ; GUI for editing gestures (WIP)
├── README.md
└── ...
🚀 Getting Started
Clone the repo

Run gestures.ahk

Drag mouse with modifier key (e.g., Ctrl + Alt + 1) to trigger configured gestures
(more setup details will be provided once GUI is ready)

📄 License
This project is open-source, under a permissive license (TBD). Use, modify, or contribute freely.
