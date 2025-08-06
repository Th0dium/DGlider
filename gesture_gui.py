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
                "Type Text": "fn:TypeText",
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

    # Event handlers and utility methods
    def on_mouse_button_change(self, event=None):
        """Handle mouse button selection change"""
        # This could be used to filter configurations by mouse button in the future
        pass

    def on_category_select(self, event=None):
        """Handle category selection in hotkey library"""
        selection = self.category_listbox.curselection()
        if not selection:
            return

        category = self.category_listbox.get(selection[0])

        # Clear and populate hotkey tree
        for item in self.hotkey_tree.get_children():
            self.hotkey_tree.delete(item)

        if category in self.hotkey_library:
            for name, hotkey in self.hotkey_library[category].items():
                self.hotkey_tree.insert('', 'end', values=(name, hotkey))

    def browse_hotkey_library(self, hotkey, direction):
        """Open hotkey library browser for specific gesture"""
        dialog = HotkeyBrowserDialog(self.root, self.hotkey_library)
        result = dialog.show()

        if result:
            if hasattr(self, 'gesture_entries') and hotkey in self.gesture_entries:
                self.gesture_entries[hotkey][direction].set(result)
                if self.auto_save_var.get():
                    self.save_current_config()

    def add_hotkey(self):
        """Add a new hotkey configuration"""
        dialog = HotkeyInputDialog(self.root)
        new_hotkey = dialog.show()

        if new_hotkey and new_hotkey not in self.config_data:
            self.config_data[new_hotkey] = {
                "up": "", "down": "", "left": "", "right": "", "default": ""
            }
            self.refresh_gesture_ui()
            self.refresh_preview()

    def remove_hotkey(self):
        """Remove selected hotkey configuration"""
        # Simple implementation - could be enhanced with selection UI
        if self.config_data:
            hotkeys = list(self.config_data.keys())
            if hotkeys:
                # For now, remove the last one - could be enhanced with proper selection
                last_hotkey = hotkeys[-1]
                result = messagebox.askyesno("Confirm Delete",
                                           f"Delete hotkey '{last_hotkey}'?")
                if result:
                    del self.config_data[last_hotkey]
                    self.refresh_gesture_ui()
                    self.refresh_preview()

    def add_category(self):
        """Add new category to hotkey library"""
        dialog = CategoryInputDialog(self.root)
        new_category = dialog.show()

        if new_category and new_category not in self.hotkey_library:
            self.hotkey_library[new_category] = {}
            self.category_listbox.insert(tk.END, new_category)

    def add_hotkey_to_library(self):
        """Add new hotkey to selected category"""
        selection = self.category_listbox.curselection()
        if not selection:
            messagebox.showwarning("No Category", "Please select a category first.")
            return

        category = self.category_listbox.get(selection[0])
        dialog = HotkeyDefinitionDialog(self.root)
        result = dialog.show()

        if result:
            name, hotkey = result
            self.hotkey_library[category][name] = hotkey
            self.on_category_select()  # Refresh the tree

    def edit_hotkey(self):
        """Edit selected hotkey in library"""
        selection = self.hotkey_tree.selection()
        if not selection:
            messagebox.showwarning("No Selection", "Please select a hotkey to edit.")
            return

        item = self.hotkey_tree.item(selection[0])
        name, hotkey = item['values']

        dialog = HotkeyDefinitionDialog(self.root, name, hotkey)
        result = dialog.show()

        if result:
            new_name, new_hotkey = result
            # Update in library
            category_selection = self.category_listbox.curselection()
            if category_selection:
                category = self.category_listbox.get(category_selection[0])
                if name in self.hotkey_library[category]:
                    del self.hotkey_library[category][name]
                self.hotkey_library[category][new_name] = new_hotkey
                self.on_category_select()  # Refresh the tree

    def delete_hotkey(self):
        """Delete selected hotkey from library"""
        selection = self.hotkey_tree.selection()
        if not selection:
            messagebox.showwarning("No Selection", "Please select a hotkey to delete.")
            return

        item = self.hotkey_tree.item(selection[0])
        name = item['values'][0]

        result = messagebox.askyesno("Confirm Delete", f"Delete hotkey '{name}'?")
        if result:
            category_selection = self.category_listbox.curselection()
            if category_selection:
                category = self.category_listbox.get(category_selection[0])
                if name in self.hotkey_library[category]:
                    del self.hotkey_library[category][name]
                    self.on_category_select()  # Refresh the tree

    def test_gesture(self):
        """Test gesture functionality"""
        messagebox.showinfo("Test Gesture",
                          "Gesture testing functionality would be implemented here.\n"
                          "This could include simulating mouse movements and testing actions.")

    def view_logs(self):
        """View gesture logs"""
        log_path = os.path.expanduser("~/Desktop/Log/gesture_log.txt")
        if os.path.exists(log_path):
            LogViewerDialog(self.root, log_path).show()
        else:
            messagebox.showinfo("No Logs", "No log file found at the expected location.")

    def clear_logs(self):
        """Clear gesture logs"""
        log_path = os.path.expanduser("~/Desktop/Log/gesture_log.txt")
        if os.path.exists(log_path):
            result = messagebox.askyesno("Clear Logs", "Are you sure you want to clear all logs?")
            if result:
                try:
                    with open(log_path, 'w') as f:
                        f.write(f"Log cleared at {datetime.now()}\n")
                    messagebox.showinfo("Success", "Logs cleared successfully.")
                except Exception as e:
                    messagebox.showerror("Error", f"Failed to clear logs: {e}")
        else:
            messagebox.showinfo("No Logs", "No log file found to clear.")

    def refresh_preview(self):
        """Refresh the configuration preview"""
        preview_text = self.generate_preview_text()
        self.preview_text.delete(1.0, tk.END)
        self.preview_text.insert(1.0, preview_text)

    def generate_preview_text(self):
        """Generate preview text for current configuration"""
        lines = []
        lines.append("=== DGlider Configuration Preview ===\n")
        lines.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        lines.append(f"Mouse Button: {self.selected_mouse_button.get()}")
        lines.append(f"Gesture Threshold: {self.gesture_threshold.get()} pixels\n")

        lines.append("=== Hotkey Mappings ===")
        for hotkey, directions in self.config_data.items():
            lines.append(f"\nHotkey: {hotkey}")
            for direction, action in directions.items():
                if action:
                    lines.append(f"  {direction.ljust(8)}: {action}")
                else:
                    lines.append(f"  {direction.ljust(8)}: (not set)")

        return "\n".join(lines)

    # File operations
    def new_config(self):
        """Create new configuration"""
        if self.config_data:
            result = messagebox.askyesno("New Config",
                                       "Current configuration will be lost. Continue?")
            if not result:
                return
        self.load_default_config()
        self.current_config_file = None
        self.current_config_label.config(text="Untitled")

    def load_config(self):
        """Load configuration from file"""
        file_path = filedialog.askopenfilename(
            title="Load Configuration",
            filetypes=[("JSON files", "*.json"), ("INI files", "*.ini"), ("All files", "*.*")]
        )

        if not file_path:
            return

        try:
            if file_path.endswith('.json'):
                with open(file_path, 'r', encoding='utf-8') as f:
                    self.config_data = json.load(f)
            elif file_path.endswith('.ini'):
                config = configparser.ConfigParser()
                config.read(file_path)
                self.config_data = {}
                for section in config.sections():
                    if section.startswith('Hotkey_'):
                        hotkey = section[7:]  # Remove 'Hotkey_' prefix
                        self.config_data[hotkey] = dict(config[section])

            self.current_config_file = file_path
            self.current_config_label.config(text=os.path.basename(file_path))
            self.refresh_gesture_ui()
            self.refresh_preview()
            messagebox.showinfo("Success", "Configuration loaded successfully.")

        except Exception as e:
            messagebox.showerror("Error", f"Failed to load configuration:\n{e}")

    def save_config(self):
        """Save current configuration"""
        if self.current_config_file:
            self.save_to_file(self.current_config_file)
        else:
            self.save_config_as()

    def save_config_as(self):
        """Save configuration to new file"""
        file_path = filedialog.asksaveasfilename(
            title="Save Configuration",
            defaultextension=".json",
            filetypes=[("JSON files", "*.json"), ("INI files", "*.ini")]
        )

        if file_path:
            self.save_to_file(file_path)
            self.current_config_file = file_path
            self.current_config_label.config(text=os.path.basename(file_path))

    def save_to_file(self, file_path):
        """Save configuration to specified file"""
        try:
            # Update config data from UI
            self.update_config_from_ui()

            if file_path.endswith('.json'):
                with open(file_path, 'w', encoding='utf-8') as f:
                    json.dump(self.config_data, f, indent=4)
            elif file_path.endswith('.ini'):
                config = configparser.ConfigParser()
                for hotkey, directions in self.config_data.items():
                    section_name = f'Hotkey_{hotkey}'
                    config[section_name] = directions
                with open(file_path, 'w', encoding='utf-8') as f:
                    config.write(f)

            messagebox.showinfo("Success", "Configuration saved successfully.")

        except Exception as e:
            messagebox.showerror("Error", f"Failed to save configuration:\n{e}")

    def save_current_config(self):
        """Save current configuration if auto-save is enabled"""
        if self.auto_save_var.get() and self.current_config_file:
            self.save_to_file(self.current_config_file)

    def update_config_from_ui(self):
        """Update config data from UI entries"""
        if hasattr(self, 'gesture_entries'):
            for hotkey, directions in self.gesture_entries.items():
                if hotkey not in self.config_data:
                    self.config_data[hotkey] = {}
                for direction, var in directions.items():
                    self.config_data[hotkey][direction] = var.get()

    def export_to_ahk(self):
        """Export configuration to AutoHotkey script"""
        file_path = filedialog.asksaveasfilename(
            title="Export to AutoHotkey",
            defaultextension=".ahk",
            filetypes=[("AutoHotkey files", "*.ahk")]
        )

        if not file_path:
            return

        try:
            self.update_config_from_ui()
            ahk_content = self.generate_ahk_script()

            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(ahk_content)

            messagebox.showinfo("Success", f"AutoHotkey script exported to:\n{file_path}")

        except Exception as e:
            messagebox.showerror("Error", f"Failed to export AHK script:\n{e}")

    def export_to_json(self):
        """Export configuration to JSON"""
        file_path = filedialog.asksaveasfilename(
            title="Export to JSON",
            defaultextension=".json",
            filetypes=[("JSON files", "*.json")]
        )

        if file_path:
            self.save_to_file(file_path)

    def export_to_ini(self):
        """Export configuration to INI"""
        file_path = filedialog.asksaveasfilename(
            title="Export to INI",
            defaultextension=".ini",
            filetypes=[("INI files", "*.ini")]
        )

        if file_path:
            self.save_to_file(file_path)

    def generate_ahk_script(self):
        """Generate AutoHotkey script from current configuration"""
        lines = []
        lines.append(";=== Generated by DGlider GUI ===")
        lines.append(f";Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        lines.append("#SingleInstance Force")
        lines.append("")
        lines.append(";=== Variables ===")
        lines.append("SysGet, screenWidth, 78")
        lines.append("SysGet, screenHeight, 79")
        lines.append(f"MoveThreshold := {self.gesture_threshold.get()}")
        lines.append("")
        lines.append(";=== Hotkey Bindings ===")

        for hotkey in self.config_data.keys():
            lines.append(f'{hotkey}::HandleMouseAction("{hotkey}")')

        lines.append("")
        lines.append(";=== Core Functions ===")
        lines.append("getAction(hotkey, direction) {")
        lines.append("    IniRead, value, %A_ScriptDir%\\gesture_config.ini, Hotkey_%hotkey%, %direction%,")
        lines.append("    return value")
        lines.append("}")
        lines.append("")

        # Add the main handler function (simplified version)
        lines.append("HandleMouseAction(hotkey) {")
        lines.append("    global MoveThreshold")
        lines.append("    MouseGetPos, x0, y0")
        lines.append("    StringTrimLeft, key, hotkey, 2")
        lines.append("    KeyWait, %key%")
        lines.append("    MouseGetPos, x1, y1")
        lines.append("    dx := x1 - x0")
        lines.append("    dy := y1 - y0")
        lines.append("")
        lines.append("    if (Abs(dx) > Abs(dy)) {")
        lines.append("        if (dx > MoveThreshold)")
        lines.append("            action := getAction(hotkey, \"right\")")
        lines.append("        else if (dx < -MoveThreshold)")
        lines.append("            action := getAction(hotkey, \"left\")")
        lines.append("        else")
        lines.append("            action := getAction(hotkey, \"default\")")
        lines.append("    } else {")
        lines.append("        if (dy > MoveThreshold)")
        lines.append("            action := getAction(hotkey, \"down\")")
        lines.append("        else if (dy < -MoveThreshold)")
        lines.append("            action := getAction(hotkey, \"up\")")
        lines.append("        else")
        lines.append("            action := getAction(hotkey, \"default\")")
        lines.append("    }")
        lines.append("")
        lines.append("    if (SubStr(action, 1, 3) = \"fn:\") {")
        lines.append("        funcName := SubStr(action, 4)")
        lines.append("        %funcName%()")
        lines.append("    } else if (action != \"\") {")
        lines.append("        Send, %action%")
        lines.append("    }")
        lines.append("}")
        lines.append("")
        lines.append(";=== Custom Functions ===")
        lines.append("TypeText() {")
        lines.append("    ; Hiển thị hộp thoại để người dùng nhập text")
        lines.append("    InputBox, userText, Type Text, Enter text to type:, , 400, 150")
        lines.append("    ")
        lines.append("    ; Kiểm tra nếu người dùng không hủy và có nhập text")
        lines.append("    if (ErrorLevel = 0 && userText != \"\") {")
        lines.append("        ; Ghi log")
        lines.append("        logDir := A_Desktop \"\\Log\"")
        lines.append("        IfNotExist, %logDir%")
        lines.append("            FileCreateDir, %logDir%")
        lines.append("        logFile := logDir \"\\gesture_log.txt\"")
        lines.append("        FileAppend, %A_Now% - TypeText function called - Text: %userText%`n, %logFile%")
        lines.append("        ")
        lines.append("        ; Gửi text ra bàn phím")
        lines.append("        SendRaw, %userText%")
        lines.append("    }")
        lines.append("}")

        return "\n".join(lines)

    def show_about(self):
        """Show about dialog"""
        about_text = """DGlider - Advanced Gesture Configuration

Version: 2.0
Developed by: DGlider Team

A modular mouse gesture engine that enhances productivity
through fully customizable directional gestures.

Built with AutoHotkey and Python.
"""
        messagebox.showinfo("About DGlider", about_text)

    def show_hotkey_reference(self):
        """Show hotkey reference dialog"""
        HotkeyReferenceDialog(self.root).show()


# Dialog Classes
class HotkeyBrowserDialog:
    def __init__(self, parent, hotkey_library):
        self.parent = parent
        self.hotkey_library = hotkey_library
        self.result = None

    def show(self):
        self.dialog = tk.Toplevel(self.parent)
        self.dialog.title("Browse Hotkey Library")
        self.dialog.geometry("500x400")
        self.dialog.transient(self.parent)
        self.dialog.grab_set()

        # Category selection
        ttk.Label(self.dialog, text="Category:").pack(pady=5)
        self.category_var = tk.StringVar()
        category_combo = ttk.Combobox(self.dialog, textvariable=self.category_var,
                                     values=list(self.hotkey_library.keys()), state='readonly')
        category_combo.pack(pady=5)
        category_combo.bind('<<ComboboxSelected>>', self.on_category_change)

        # Hotkey list
        ttk.Label(self.dialog, text="Hotkeys:").pack(pady=(10,5))

        frame = ttk.Frame(self.dialog)
        frame.pack(fill='both', expand=True, padx=10, pady=5)

        self.hotkey_listbox = tk.Listbox(frame)
        scrollbar = ttk.Scrollbar(frame, orient='vertical', command=self.hotkey_listbox.yview)
        self.hotkey_listbox.configure(yscrollcommand=scrollbar.set)

        self.hotkey_listbox.pack(side='left', fill='both', expand=True)
        scrollbar.pack(side='right', fill='y')

        # Buttons
        button_frame = ttk.Frame(self.dialog)
        button_frame.pack(fill='x', padx=10, pady=10)

        ttk.Button(button_frame, text="Select", command=self.select_hotkey).pack(side='right', padx=5)
        ttk.Button(button_frame, text="Cancel", command=self.dialog.destroy).pack(side='right')

        self.dialog.wait_window()
        return self.result

    def on_category_change(self, event=None):
        category = self.category_var.get()
        self.hotkey_listbox.delete(0, tk.END)

        if category in self.hotkey_library:
            for name, hotkey in self.hotkey_library[category].items():
                self.hotkey_listbox.insert(tk.END, f"{name} ({hotkey})")

    def select_hotkey(self):
        selection = self.hotkey_listbox.curselection()
        if selection:
            item = self.hotkey_listbox.get(selection[0])
            # Extract hotkey from "name (hotkey)" format
            if '(' in item and ')' in item:
                self.result = item.split('(')[1].rstrip(')')
            self.dialog.destroy()


class HotkeyInputDialog:
    def __init__(self, parent):
        self.parent = parent
        self.result = None

    def show(self):
        self.dialog = tk.Toplevel(self.parent)
        self.dialog.title("Add Hotkey")
        self.dialog.geometry("300x150")
        self.dialog.transient(self.parent)
        self.dialog.grab_set()

        ttk.Label(self.dialog, text="Enter hotkey combination:").pack(pady=10)

        self.entry_var = tk.StringVar()
        entry = ttk.Entry(self.dialog, textvariable=self.entry_var, width=30)
        entry.pack(pady=5)
        entry.focus()

        ttk.Label(self.dialog, text="Example: ^!1 (Ctrl+Alt+1)").pack(pady=5)

        button_frame = ttk.Frame(self.dialog)
        button_frame.pack(pady=10)

        ttk.Button(button_frame, text="OK", command=self.ok_clicked).pack(side='left', padx=5)
        ttk.Button(button_frame, text="Cancel", command=self.dialog.destroy).pack(side='left')

        self.dialog.bind('<Return>', lambda e: self.ok_clicked())
        self.dialog.wait_window()
        return self.result

    def ok_clicked(self):
        self.result = self.entry_var.get().strip()
        self.dialog.destroy()


class CategoryInputDialog:
    def __init__(self, parent):
        self.parent = parent
        self.result = None

    def show(self):
        self.dialog = tk.Toplevel(self.parent)
        self.dialog.title("Add Category")
        self.dialog.geometry("300x150")
        self.dialog.transient(self.parent)
        self.dialog.grab_set()

        ttk.Label(self.dialog, text="Enter category name:").pack(pady=10)

        self.entry_var = tk.StringVar()
        entry = ttk.Entry(self.dialog, textvariable=self.entry_var, width=30)
        entry.pack(pady=5)
        entry.focus()

        button_frame = ttk.Frame(self.dialog)
        button_frame.pack(pady=10)

        ttk.Button(button_frame, text="OK", command=self.ok_clicked).pack(side='left', padx=5)
        ttk.Button(button_frame, text="Cancel", command=self.dialog.destroy).pack(side='left')

        self.dialog.bind('<Return>', lambda e: self.ok_clicked())
        self.dialog.wait_window()
        return self.result

    def ok_clicked(self):
        self.result = self.entry_var.get().strip()
        self.dialog.destroy()


class HotkeyDefinitionDialog:
    def __init__(self, parent, name="", hotkey=""):
        self.parent = parent
        self.result = None
        self.initial_name = name
        self.initial_hotkey = hotkey

    def show(self):
        self.dialog = tk.Toplevel(self.parent)
        self.dialog.title("Define Hotkey")
        self.dialog.geometry("400x200")
        self.dialog.transient(self.parent)
        self.dialog.grab_set()

        # Name field
        ttk.Label(self.dialog, text="Action Name:").pack(pady=5)
        self.name_var = tk.StringVar(value=self.initial_name)
        name_entry = ttk.Entry(self.dialog, textvariable=self.name_var, width=40)
        name_entry.pack(pady=5)

        # Hotkey field
        ttk.Label(self.dialog, text="Hotkey/Function:").pack(pady=5)
        self.hotkey_var = tk.StringVar(value=self.initial_hotkey)
        hotkey_entry = ttk.Entry(self.dialog, textvariable=self.hotkey_var, width=40)
        hotkey_entry.pack(pady=5)

        # Help text
        help_text = "Examples:\n^c (Ctrl+C), !{Tab} (Alt+Tab), fn:SCI (Function call)"
        ttk.Label(self.dialog, text=help_text, foreground='gray').pack(pady=5)

        # Buttons
        button_frame = ttk.Frame(self.dialog)
        button_frame.pack(pady=10)

        ttk.Button(button_frame, text="OK", command=self.ok_clicked).pack(side='left', padx=5)
        ttk.Button(button_frame, text="Cancel", command=self.dialog.destroy).pack(side='left')

        name_entry.focus()
        self.dialog.bind('<Return>', lambda e: self.ok_clicked())
        self.dialog.wait_window()
        return self.result

    def ok_clicked(self):
        name = self.name_var.get().strip()
        hotkey = self.hotkey_var.get().strip()
        if name and hotkey:
            self.result = (name, hotkey)
        self.dialog.destroy()


class LogViewerDialog:
    def __init__(self, parent, log_path):
        self.parent = parent
        self.log_path = log_path

    def show(self):
        self.dialog = tk.Toplevel(self.parent)
        self.dialog.title("Gesture Logs")
        self.dialog.geometry("800x600")
        self.dialog.transient(self.parent)

        # Text area
        text_frame = ttk.Frame(self.dialog)
        text_frame.pack(fill='both', expand=True, padx=10, pady=10)

        self.text_area = ScrolledText(text_frame, wrap=tk.WORD)
        self.text_area.pack(fill='both', expand=True)

        # Load and display log content
        try:
            with open(self.log_path, 'r', encoding='utf-8') as f:
                content = f.read()
                self.text_area.insert(1.0, content)
        except Exception as e:
            self.text_area.insert(1.0, f"Error reading log file: {e}")

        # Buttons
        button_frame = ttk.Frame(self.dialog)
        button_frame.pack(fill='x', padx=10, pady=5)

        ttk.Button(button_frame, text="Refresh", command=self.refresh_logs).pack(side='left', padx=5)
        ttk.Button(button_frame, text="Close", command=self.dialog.destroy).pack(side='right')

    def refresh_logs(self):
        self.text_area.delete(1.0, tk.END)
        try:
            with open(self.log_path, 'r', encoding='utf-8') as f:
                content = f.read()
                self.text_area.insert(1.0, content)
        except Exception as e:
            self.text_area.insert(1.0, f"Error reading log file: {e}")


class HotkeyReferenceDialog:
    def __init__(self, parent):
        self.parent = parent

    def show(self):
        self.dialog = tk.Toplevel(self.parent)
        self.dialog.title("Hotkey Reference")
        self.dialog.geometry("600x500")
        self.dialog.transient(self.parent)

        # Create notebook for different reference sections
        notebook = ttk.Notebook(self.dialog)
        notebook.pack(fill='both', expand=True, padx=10, pady=10)

        # AutoHotkey syntax tab
        ahk_frame = ttk.Frame(notebook)
        notebook.add(ahk_frame, text="AutoHotkey Syntax")

        ahk_text = ScrolledText(ahk_frame, wrap=tk.WORD)
        ahk_text.pack(fill='both', expand=True, padx=5, pady=5)

        ahk_reference = """AutoHotkey Hotkey Reference:

Modifier Keys:
^ = Ctrl
! = Alt
+ = Shift
# = Windows Key

Special Keys:
{Tab} = Tab key
{Enter} = Enter key
{Esc} = Escape key
{Space} = Space bar
{F1}-{F12} = Function keys
{Up}, {Down}, {Left}, {Right} = Arrow keys
{Home}, {End}, {PgUp}, {PgDn} = Navigation keys

Examples:
^c = Ctrl+C (Copy)
!{Tab} = Alt+Tab (Switch windows)
^+{Esc} = Ctrl+Shift+Esc (Task Manager)
{LWin}d = Windows+D (Show desktop)

Function Calls:
fn:FunctionName = Call custom function
Example: fn:SCI = Call SCI() function
"""
        ahk_text.insert(1.0, ahk_reference)
        ahk_text.config(state='disabled')

        # Gesture directions tab
        gesture_frame = ttk.Frame(notebook)
        notebook.add(gesture_frame, text="Gesture Directions")

        gesture_text = ScrolledText(gesture_frame, wrap=tk.WORD)
        gesture_text.pack(fill='both', expand=True, padx=5, pady=5)

        gesture_reference = """Gesture Directions:

Available Directions:
↑ Up = Move mouse upward while holding hotkey
↓ Down = Move mouse downward while holding hotkey
← Left = Move mouse left while holding hotkey
→ Right = Move mouse right while holding hotkey
● Default = Release hotkey without moving mouse

How to Use:
1. Press and hold a configured hotkey (e.g., Ctrl+Alt+1)
2. Move mouse in desired direction
3. Release the hotkey
4. The corresponding action will be executed

Threshold:
The gesture threshold determines how far you need to move
the mouse before it registers as a directional gesture.
Default is 40 pixels.
"""
        gesture_text.insert(1.0, gesture_reference)
        gesture_text.config(state='disabled')

        # Close button
        ttk.Button(self.dialog, text="Close", command=self.dialog.destroy).pack(pady=10)


# Main application entry point
if __name__ == "__main__":
    root = tk.Tk()
    app = DGliderGUI(root)
    root.mainloop()
