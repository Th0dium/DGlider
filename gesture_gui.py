import json
import tkinter as tk
from tkinter import filedialog, messagebox

class GestureEditor:
    def __init__(self, root):
        self.root = root
        self.root.title("Gesture Config Editor")

        self.config_data = {}
        self.entries = {}

        self.frame = tk.Frame(root)
        self.frame.pack(padx=10, pady=10)

        self.load_button = tk.Button(root, text="Load Config", command=self.load_config)
        self.load_button.pack(pady=5)

        self.save_button = tk.Button(root, text="Save Config", command=self.save_config)
        self.save_button.pack(pady=5)

    def build_ui(self):
        for widget in self.frame.winfo_children():
            widget.destroy()

        self.entries.clear()

        for row, hotkey in enumerate(self.config_data):
            tk.Label(self.frame, text=hotkey, font=('Arial', 10, 'bold')).grid(row=row*2, column=0, sticky="w", pady=3)
            directions = ['up', 'down', 'left', 'right', 'default']
            self.entries[hotkey] = {}

            for col, dir in enumerate(directions):
                tk.Label(self.frame, text=dir).grid(row=row*2+1, column=col, sticky="w")
                entry = tk.Entry(self.frame, width=15)
                entry.insert(0, self.config_data[hotkey].get(dir, ""))
                entry.grid(row=row*2+2, column=col)
                self.entries[hotkey][dir] = entry

    def load_config(self):
        path = filedialog.askopenfilename(filetypes=[("JSON files", "*.json")])
        if not path:
            return
        try:
            with open(path, 'r', encoding='utf-8') as f:
                self.config_data = json.load(f)
            self.build_ui()
        except Exception as e:
            messagebox.showerror("Error", f"Failed to load config:\n{e}")

    def save_config(self):
        for hotkey in self.entries:
            for dir in self.entries[hotkey]:
                self.config_data[hotkey][dir] = self.entries[hotkey][dir].get()

        path = filedialog.asksaveasfilename(defaultextension=".json", filetypes=[("JSON files", "*.json")])
        if not path:
            return
        try:
            with open(path, 'w', encoding='utf-8') as f:
                json.dump(self.config_data, f, indent=4)
            messagebox.showinfo("Saved", "Configuration saved successfully.")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to save config:\n{e}")


if __name__ == "__main__":
    root = tk.Tk()
    app = GestureEditor(root)
    root.mainloop()
