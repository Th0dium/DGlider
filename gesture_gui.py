import json
import os
import tkinter as tk
from tkinter import ttk, filedialog, messagebox, colorchooser
from tkinter.scrolledtext import ScrolledText
import configparser
from datetime import datetime

class DGliderGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("DGlider - Advanced Gesture Configuration")
        self.root.geometry("1200x800")
        self.root.minsize(1000, 600)

        # Configuration data
        self.config_data = {}
        self.current_config_file = None
        self.mouse_buttons = ["Left", "Right", "Middle", "X1", "X2"]
        self.selected_mouse_button = tk.StringVar(value="Left")
        self.gesture_threshold = tk.IntVar(value=40)

        # Hotkey library (expandable)
        self.hotkey_library = {
            "System": {
                "Copy": "^c",
                "Paste": "^v",
                "Cut": "^x",
                "Undo": "^z",
                "Redo": "^y",
                "Select All": "^a",
                "Save": "^s",
                "Open": "^o",
                "New": "^n",
                "Close": "^w",
                "Quit": "!{F4}"
            },
            "Navigation": {
                "Alt+Tab": "!{Tab}",
                "Windows Key": "{LWin}",
                "Task Manager": "^+{Esc}",
                "Desktop": "{LWin}d",
                "File Explorer": "{LWin}e",
                "Run Dialog": "{LWin}r",
                "Settings": "{LWin}i"
            },
            "Browser": {
                "New Tab": "^t",
                "Close Tab": "^w",
                "Reopen Tab": "^+t",
                "Next Tab": "^{Tab}",
                "Previous Tab": "^+{Tab}",
                "Refresh": "{F5}",
                "Hard Refresh": "^{F5}",
                "Developer Tools": "{F12}",
                "Bookmark": "^d",
                "History": "^h"
            },
            "Media": {
                "Play/Pause": "{Media_Play_Pause}",
                "Next Track": "{Media_Next}",
                "Previous Track": "{Media_Prev}",
                "Volume Up": "{Volume_Up}",
                "Volume Down": "{Volume_Down}",
                "Mute": "{Volume_Mute}"
            },
            "Functions": {
                "Screenshot to Clipboard": "fn:SCI",
                "Custom Function 1": "fn:CustomFunc1",
                "Custom Function 2": "fn:CustomFunc2"
            }
        }

        # Initialize UI
        self.setup_styles()
        self.create_menu()
        self.create_main_interface()
        self.load_default_config()

    def setup_styles(self):
        """Setup modern styling for the application"""
        style = ttk.Style()
        style.theme_use('clam')

        # Configure colors
        style.configure('Title.TLabel', font=('Arial', 14, 'bold'), foreground='#2c3e50')
        style.configure('Heading.TLabel', font=('Arial', 11, 'bold'), foreground='#34495e')
        style.configure('Custom.TButton', padding=(10, 5))
        style.configure('Danger.TButton', foreground='white', background='#e74c3c')
        style.configure('Success.TButton', foreground='white', background='#27ae60')

    def create_menu(self):
        """Create application menu bar"""
        menubar = tk.Menu(self.root)
        self.root.config(menu=menubar)

        # File menu
        file_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="File", menu=file_menu)
        file_menu.add_command(label="New Config", command=self.new_config)
        file_menu.add_command(label="Open Config", command=self.load_config)
        file_menu.add_command(label="Save Config", command=self.save_config)
        file_menu.add_command(label="Save As...", command=self.save_config_as)
        file_menu.add_separator()
        file_menu.add_command(label="Export to AHK", command=self.export_to_ahk)
        file_menu.add_separator()
        file_menu.add_command(label="Exit", command=self.root.quit)

        # Tools menu
        tools_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="Tools", menu=tools_menu)
        tools_menu.add_command(label="Test Gesture", command=self.test_gesture)
        tools_menu.add_command(label="View Logs", command=self.view_logs)
        tools_menu.add_command(label="Clear Logs", command=self.clear_logs)

        # Help menu
        help_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="Help", menu=help_menu)
        help_menu.add_command(label="About", command=self.show_about)
        help_menu.add_command(label="Hotkey Reference", command=self.show_hotkey_reference)

    def create_main_interface(self):
        """Create the main interface with tabs"""
        # Create notebook for tabs
        self.notebook = ttk.Notebook(self.root)
        self.notebook.pack(fill='both', expand=True, padx=10, pady=10)

        # Create tabs
        self.create_gesture_tab()
        self.create_settings_tab()
        self.create_hotkey_library_tab()
        self.create_preview_tab()

    def create_gesture_tab(self):
        """Create the main gesture configuration tab"""
        gesture_frame = ttk.Frame(self.notebook)
        self.notebook.add(gesture_frame, text="Gesture Configuration")

        # Top controls
        top_frame = ttk.Frame(gesture_frame)
        top_frame.pack(fill='x', padx=10, pady=5)

        # Mouse button selection
        ttk.Label(top_frame, text="Mouse Button:", style='Heading.TLabel').pack(side='left')
        mouse_combo = ttk.Combobox(top_frame, textvariable=self.selected_mouse_button,
                                  values=self.mouse_buttons, state='readonly', width=10)
        mouse_combo.pack(side='left', padx=(5, 20))
        mouse_combo.bind('<<ComboboxSelected>>', self.on_mouse_button_change)

        # Add/Remove hotkey buttons
        ttk.Button(top_frame, text="Add Hotkey", command=self.add_hotkey,
                  style='Success.TButton').pack(side='right', padx=5)
        ttk.Button(top_frame, text="Remove Hotkey", command=self.remove_hotkey,
                  style='Danger.TButton').pack(side='right')

        # Gesture configuration area
        self.gesture_canvas_frame = ttk.Frame(gesture_frame)
        self.gesture_canvas_frame.pack(fill='both', expand=True, padx=10, pady=10)

        # Create scrollable area for gesture configurations
        self.create_scrollable_gesture_area()

    def create_scrollable_gesture_area(self):
        """Create scrollable area for gesture configurations"""
        # Canvas and scrollbar
        canvas = tk.Canvas(self.gesture_canvas_frame, bg='white')
        scrollbar = ttk.Scrollbar(self.gesture_canvas_frame, orient="vertical", command=canvas.yview)
        self.scrollable_frame = ttk.Frame(canvas)

        self.scrollable_frame.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )

        canvas.create_window((0, 0), window=self.scrollable_frame, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)

        canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")

        self.gesture_canvas = canvas

    def create_settings_tab(self):
        """Create settings configuration tab"""
        settings_frame = ttk.Frame(self.notebook)
        self.notebook.add(settings_frame, text="Settings")

        # General settings
        general_frame = ttk.LabelFrame(settings_frame, text="General Settings", padding=10)
        general_frame.pack(fill='x', padx=10, pady=5)

        # Gesture threshold
        threshold_frame = ttk.Frame(general_frame)
        threshold_frame.pack(fill='x', pady=5)
        ttk.Label(threshold_frame, text="Gesture Threshold (pixels):").pack(side='left')
        threshold_scale = ttk.Scale(threshold_frame, from_=10, to=100,
                                   variable=self.gesture_threshold, orient='horizontal')
        threshold_scale.pack(side='left', fill='x', expand=True, padx=10)
        threshold_label = ttk.Label(threshold_frame, textvariable=self.gesture_threshold)
        threshold_label.pack(side='left')

        # Config file settings
        config_frame = ttk.LabelFrame(settings_frame, text="Configuration", padding=10)
        config_frame.pack(fill='x', padx=10, pady=5)

        current_config_frame = ttk.Frame(config_frame)
        current_config_frame.pack(fill='x', pady=5)
        ttk.Label(current_config_frame, text="Current Config:").pack(side='left')
        self.current_config_label = ttk.Label(current_config_frame, text="None", foreground='gray')
        self.current_config_label.pack(side='left', padx=10)

        # Auto-save option
        self.auto_save_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(config_frame, text="Auto-save changes",
                       variable=self.auto_save_var).pack(anchor='w', pady=5)

    def create_hotkey_library_tab(self):
        """Create hotkey library management tab"""
        library_frame = ttk.Frame(self.notebook)
        self.notebook.add(library_frame, text="Hotkey Library")

        # Split into two panes
        paned = ttk.PanedWindow(library_frame, orient='horizontal')
        paned.pack(fill='both', expand=True, padx=10, pady=10)

        # Left pane - Categories
        left_frame = ttk.Frame(paned)
        paned.add(left_frame, weight=1)

        ttk.Label(left_frame, text="Categories", style='Heading.TLabel').pack(pady=5)

        # Category listbox
        self.category_listbox = tk.Listbox(left_frame, height=15)
        self.category_listbox.pack(fill='both', expand=True, pady=5)
        self.category_listbox.bind('<<ListboxSelect>>', self.on_category_select)

        # Populate categories
        for category in self.hotkey_library.keys():
            self.category_listbox.insert(tk.END, category)

        # Right pane - Hotkeys
        right_frame = ttk.Frame(paned)
        paned.add(right_frame, weight=2)

        ttk.Label(right_frame, text="Hotkeys", style='Heading.TLabel').pack(pady=5)

        # Hotkey tree
        columns = ('Name', 'Hotkey')
        self.hotkey_tree = ttk.Treeview(right_frame, columns=columns, show='headings', height=15)
        self.hotkey_tree.heading('Name', text='Action Name')
        self.hotkey_tree.heading('Hotkey', text='Hotkey/Function')
        self.hotkey_tree.column('Name', width=200)
        self.hotkey_tree.column('Hotkey', width=200)

        # Scrollbar for tree
        tree_scroll = ttk.Scrollbar(right_frame, orient='vertical', command=self.hotkey_tree.yview)
        self.hotkey_tree.configure(yscrollcommand=tree_scroll.set)

        self.hotkey_tree.pack(side='left', fill='both', expand=True, pady=5)
        tree_scroll.pack(side='right', fill='y', pady=5)

        # Buttons for hotkey management
        button_frame = ttk.Frame(library_frame)
        button_frame.pack(fill='x', padx=10, pady=5)

        ttk.Button(button_frame, text="Add Category", command=self.add_category).pack(side='left', padx=5)
        ttk.Button(button_frame, text="Add Hotkey", command=self.add_hotkey_to_library).pack(side='left', padx=5)
        ttk.Button(button_frame, text="Edit Selected", command=self.edit_hotkey).pack(side='left', padx=5)
        ttk.Button(button_frame, text="Delete Selected", command=self.delete_hotkey).pack(side='left', padx=5)

    def create_preview_tab(self):
        """Create preview and export tab"""
        preview_frame = ttk.Frame(self.notebook)
        self.notebook.add(preview_frame, text="Preview & Export")

        # Preview area
        preview_label_frame = ttk.LabelFrame(preview_frame, text="Configuration Preview", padding=10)
        preview_label_frame.pack(fill='both', expand=True, padx=10, pady=5)

        self.preview_text = ScrolledText(preview_label_frame, height=20, width=80)
        self.preview_text.pack(fill='both', expand=True)

        # Export buttons
        export_frame = ttk.Frame(preview_frame)
        export_frame.pack(fill='x', padx=10, pady=5)

        ttk.Button(export_frame, text="Refresh Preview", command=self.refresh_preview).pack(side='left', padx=5)
        ttk.Button(export_frame, text="Export to AHK", command=self.export_to_ahk).pack(side='left', padx=5)
        ttk.Button(export_frame, text="Export to JSON", command=self.export_to_json).pack(side='left', padx=5)
        ttk.Button(export_frame, text="Export to INI", command=self.export_to_ini).pack(side='left', padx=5)

    def load_default_config(self):
        """Load default configuration"""
        self.config_data = {
            "^!1": {"up": "", "down": "", "left": "", "right": "", "default": ""},
            "^!2": {"up": "", "down": "", "left": "", "right": "", "default": ""},
            "^!3": {"up": "", "down": "", "left": "", "right": "", "default": ""},
            "^!4": {"up": "", "down": "", "left": "", "right": "", "default": ""},
        }
        self.refresh_gesture_ui()
        self.refresh_preview()

    def refresh_gesture_ui(self):
        """Refresh the gesture configuration UI"""
        # Clear existing widgets
        for widget in self.scrollable_frame.winfo_children():
            widget.destroy()

        # Create gesture configuration for each hotkey
        for i, (hotkey, directions) in enumerate(self.config_data.items()):
            self.create_gesture_config_widget(hotkey, directions, i)

    def create_gesture_config_widget(self, hotkey, directions, row):
        """Create a widget for configuring a single hotkey's gestures"""
        # Main frame for this hotkey
        main_frame = ttk.LabelFrame(self.scrollable_frame, text=f"Hotkey: {hotkey}", padding=10)
        main_frame.pack(fill='x', pady=5, padx=5)

        # Create gesture grid
        gesture_frame = ttk.Frame(main_frame)
        gesture_frame.pack(fill='x')

        # Headers
        ttk.Label(gesture_frame, text="Direction", style='Heading.TLabel').grid(row=0, column=0, padx=5, pady=2)
        ttk.Label(gesture_frame, text="Action", style='Heading.TLabel').grid(row=0, column=1, padx=5, pady=2)
        ttk.Label(gesture_frame, text="Browse Library", style='Heading.TLabel').grid(row=0, column=2, padx=5, pady=2)

        directions_list = ['up', 'down', 'left', 'right', 'default']
        direction_icons = ['↑', '↓', '←', '→', '●']

        for i, (direction, icon) in enumerate(zip(directions_list, direction_icons)):
            row_num = i + 1

            # Direction label with icon
            dir_label = ttk.Label(gesture_frame, text=f"{icon} {direction.title()}")
            dir_label.grid(row=row_num, column=0, padx=5, pady=2, sticky='w')

            # Action entry
            action_var = tk.StringVar(value=directions.get(direction, ""))
            action_entry = ttk.Entry(gesture_frame, textvariable=action_var, width=40)
            action_entry.grid(row=row_num, column=1, padx=5, pady=2, sticky='ew')

            # Store reference for saving
            if not hasattr(self, 'gesture_entries'):
                self.gesture_entries = {}
            if hotkey not in self.gesture_entries:
                self.gesture_entries[hotkey] = {}
            self.gesture_entries[hotkey][direction] = action_var

            # Browse button
            browse_btn = ttk.Button(gesture_frame, text="Browse",
                                   command=lambda h=hotkey, d=direction: self.browse_hotkey_library(h, d))
            browse_btn.grid(row=row_num, column=2, padx=5, pady=2)

        # Configure column weights
        gesture_frame.columnconfigure(1, weight=1)
