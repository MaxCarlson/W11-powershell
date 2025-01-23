import tkinter as tk
import json
import os
from pynput import keyboard
import pygetwindow as gw
import threading

class ShortcutOverlay:
    def __init__(self, shortcuts_folder="./Shortcuts"):
        self.root = None
        self.overlay_visible = False
        self.shortcuts = self.load_shortcuts(shortcuts_folder)
        self.listener = None  # Listener for hotkeys
        self.running = True  # Control the listener's running state

    def load_shortcuts(self, shortcuts_folder):
        """Load all shortcuts from JSON files in the specified folder."""
        all_shortcuts = {}
        if not os.path.exists(shortcuts_folder):
            print(f"Shortcuts folder '{shortcuts_folder}' not found. Please create it and add JSON files.")
            return {"default": []}

        for filename in os.listdir(shortcuts_folder):
            if filename.endswith(".json"):
                filepath = os.path.join(shortcuts_folder, filename)
                try:
                    with open(filepath, "r") as f:
                        data = json.load(f)
                        all_shortcuts.update(data)
                except json.JSONDecodeError:
                    print(f"Error decoding JSON file: {filepath}")
        return all_shortcuts

    def get_active_window_program(self):
        """Retrieve the active window's program or use 'default'."""
        try:
            window = gw.getActiveWindow()
            return window.title or "default"
        except:
            return "default"

    def create_key_block(self, canvas, x, y, width, height, text, is_plus=False):
        """Render an individual key block or a '+' symbol."""
        if is_plus:
            canvas.create_text(x + width / 2, y + height / 2, text=text, font=("Arial", 12, "bold"), fill="white")
        else:
            canvas.create_rectangle(x, y, x + width, y + height, fill="blue", outline="white", width=2)
            canvas.create_text(x + width / 2, y + height / 2, text=text, font=("Arial", 12, "bold"), fill="white")

    def create_shortcut_visual(self, canvas, x, y, keys, action):
        """Render a full shortcut visual with individual key blocks."""
        key_width, key_height, spacing = 50, 50, 5  # Reduced spacing for compact layout
        current_x = x
        for key in keys:
            if key == "+":
                self.create_key_block(canvas, current_x, y, key_width // 2, key_height, key, is_plus=True)
                current_x += key_width // 2 + spacing
            else:
                self.create_key_block(canvas, current_x, y, key_width, key_height, key)
                current_x += key_width + spacing
        # Render the action to the right of the keys
        canvas.create_text(current_x + 20, y + key_height / 2, text=action, font=("Arial", 10), fill="white", anchor="w")

    def toggle_overlay(self):
        """Toggle the visibility of the overlay."""
        if self.overlay_visible:
            if self.root:
                self.root.destroy()
            self.overlay_visible = False
        else:
            self.overlay_visible = True
            self.root = tk.Tk()
            self.root.attributes("-topmost", True, "-alpha", 0.85)
            self.root.geometry("1920x1080")
            self.root.configure(bg="black")
            self.root.overrideredirect(True)

            canvas = tk.Canvas(self.root, bg="black", highlightthickness=0)
            canvas.pack(fill=tk.BOTH, expand=True)

            active_program = self.get_active_window_program()
            shortcuts = self.shortcuts.get(active_program, self.shortcuts["default"])

            x, y = 50, 50
            for shortcut in shortcuts:
                self.create_shortcut_visual(canvas, x, y, shortcut["keys"], shortcut["action"])
                y += 100  # Adjust spacing for multiple shortcuts

            self.root.mainloop()

    def on_hotkey_press(self, key):
        """Handle hotkey presses."""
        try:
            # Check for the Ctrl + Shift + H combination
            if (
                (key == keyboard.Key.ctrl_l or key == keyboard.Key.ctrl_r)
                or key == keyboard.Key.shift
                or (hasattr(key, "char") and key.char.lower() == "h")
            ):
                self.toggle_overlay()
        except AttributeError:
            pass  # Ignore non-character key errors

    def run_listener(self):
        """Start the keyboard listener."""
        def stop_listener():
            input("Press ENTER to stop the listener...\n")
            self.running = False
            if self.listener:
                self.listener.stop()

        listener_thread = threading.Thread(target=stop_listener)
        listener_thread.daemon = True
        listener_thread.start()

        with keyboard.Listener(on_press=self.on_hotkey_press) as listener:
            self.listener = listener
            while self.running:
                pass

        print("Listener stopped.")


# Start the shortcut overlay
overlay = ShortcutOverlay("./Shortcuts")
overlay.run_listener()

