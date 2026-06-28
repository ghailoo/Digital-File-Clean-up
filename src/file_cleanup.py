#!/usr/bin/env python3
"""
Digital File Clean-up Tool
Finds duplicate files and allows you to delete one of them.
"""

import os
import hashlib


class DuplicateFileFinder:
    """Finds duplicate files based on content hash."""
    
    def __init__(self):
        self.file_hashes = {}
    
    def get_file_hash(self, filepath):
        """Calculate MD5 hash of a file."""
        hash_md5 = hashlib.md5()
        try:
            with open(filepath, "rb") as f:
                # Read in chunks to handle large files
                for chunk in iter(lambda: f.read(4096), b""):
                    hash_md5.update(chunk)
            return hash_md5.hexdigest()
        except (IOError, OSError):
            return None
    
    def find_duplicates(self, directory):
        """Find duplicate files in the given directory."""
        self.file_hashes = {}
        duplicates = []
        
        for root, _, files in os.walk(directory):
            for filename in files:
                filepath = os.path.join(root, filename)
                try:
                    file_hash = self.get_file_hash(filepath)
                    if file_hash:
                        if file_hash in self.file_hashes:
                            self.file_hashes[file_hash].append(filepath)
                        else:
                            self.file_hashes[file_hash] = [filepath]
                except Exception as e:
                    print(f"Error processing {filepath}: {e}")
        
        # Filter out hashes with only one file
        for hash_val, files in self.file_hashes.items():
            if len(files) > 1:
                duplicates.append(files)
        
        return duplicates


def main_gui():
    """Main GUI entry point - only import tkinter when needed."""
    import tkinter as tk
    from tkinter import ttk, messagebox, filedialog
    import datetime
    
    class DuplicateFileCleanupApp:
        """GUI application for finding and deleting duplicate files."""
        
        def __init__(self, root):
            self.root = root
            self.root.title("Digital File Clean-up")
            self.root.geometry("1000x600")
            
            self.duplicate_finder = DuplicateFileFinder()
            self.duplicates = []
            self.current_duplicate_index = -1
            
            # Create main containers
            self.create_widgets()
        
        def create_widgets(self):
            """Create all GUI widgets."""
            # Left panel - Directory selection and duplicate list
            left_panel = ttk.Frame(self.root, width=400, padding=10)
            left_panel.pack(side=tk.LEFT, fill=tk.Y, expand=False)
            
            # Directory selection
            ttk.Label(left_panel, text="Select Directory:").pack(anchor=tk.W, pady=(0, 5))
            
            self.dir_frame = ttk.Frame(left_panel)
            self.dir_frame.pack(fill=tk.X, pady=(0, 10))
            
            self.dir_entry = ttk.Entry(self.dir_frame)
            self.dir_entry.pack(side=tk.LEFT, fill=tk.X, expand=True)
            
            ttk.Button(
                self.dir_frame, 
                text="Browse", 
                command=self.browse_directory
            ).pack(side=tk.RIGHT, padx=(5, 0))
            
            # Scan button
            ttk.Button(
                left_panel, 
                text="Scan for Duplicates", 
                command=self.scan_duplicates
            ).pack(fill=tk.X, pady=(0, 10))
            
            # Duplicate list
            ttk.Label(left_panel, text="Duplicate Files:").pack(anchor=tk.W, pady=(0, 5))
            
            self.duplicate_listbox = tk.Listbox(
                left_panel, 
                height=20,
                activestyle='none',
                selectbackground='#e1e1e1',
                selectborderwidth=0
            )
            self.duplicate_listbox.pack(fill=tk.BOTH, expand=True)
            self.duplicate_listbox.bind('<<ListboxSelect>>', self.on_duplicate_selected)
            
            # Scrollbar for listbox
            scrollbar = ttk.Scrollbar(self.duplicate_listbox)
            scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
            self.duplicate_listbox.config(yscrollcommand=scrollbar.set)
            scrollbar.config(command=self.duplicate_listbox.yview)
            
            # Right panel - File details and delete options
            right_panel = ttk.Frame(self.root, padding=10)
            right_panel.pack(side=tk.RIGHT, fill=tk.BOTH, expand=True)
            
            # Title for right panel
            ttk.Label(
                right_panel, 
                text="Duplicate File Details",
                font=('Helvetica', 12, 'bold')
            ).pack(anchor=tk.W, pady=(0, 10))
            
            # Frame for file 1
            self.file1_frame = ttk.LabelFrame(right_panel, text="File 1", padding=10)
            self.file1_frame.pack(fill=tk.X, pady=(0, 10))
            
            self.file1_path_label = ttk.Label(self.file1_frame, text="", wraplength=400)
            self.file1_path_label.pack(anchor=tk.W)
            
            self.file1_size_label = ttk.Label(self.file1_frame, text="")
            self.file1_size_label.pack(anchor=tk.W)
            
            self.file1_modified_label = ttk.Label(self.file1_frame, text="")
            self.file1_modified_label.pack(anchor=tk.W)
            
            # Frame for file 2
            self.file2_frame = ttk.LabelFrame(right_panel, text="File 2", padding=10)
            self.file2_frame.pack(fill=tk.X, pady=(0, 10))
            
            self.file2_path_label = ttk.Label(self.file2_frame, text="", wraplength=400)
            self.file2_path_label.pack(anchor=tk.W)
            
            self.file2_size_label = ttk.Label(self.file2_frame, text="")
            self.file2_size_label.pack(anchor=tk.W)
            
            self.file2_modified_label = ttk.Label(self.file2_frame, text="")
            self.file2_modified_label.pack(anchor=tk.W)
            
            # Delete buttons
            button_frame = ttk.Frame(right_panel)
            button_frame.pack(fill=tk.X, pady=(20, 0))
            
            ttk.Button(
                button_frame,
                text="Delete File 1",
                command=lambda: self.delete_file(0),
                style='Danger.TButton'
            ).pack(side=tk.LEFT, padx=(0, 10))
            
            ttk.Button(
                button_frame,
                text="Delete File 2",
                command=lambda: self.delete_file(1),
                style='Danger.TButton'
            ).pack(side=tk.LEFT, padx=(0, 10))
            
            # Status label
            self.status_label = ttk.Label(right_panel, text="", foreground="blue")
            self.status_label.pack(anchor=tk.W, pady=(10, 0))
            
            # Configure styles
            self.configure_styles()
        
        def configure_styles(self):
            """Configure custom styles."""
            style = ttk.Style()
            style.configure('Danger.TButton', foreground='red')
        
        def browse_directory(self):
            """Open directory browser dialog."""
            directory = filedialog.askdirectory()
            if directory:
                self.dir_entry.delete(0, tk.END)
                self.dir_entry.insert(0, directory)
        
        def scan_duplicates(self):
            """Scan the selected directory for duplicate files."""
            directory = self.dir_entry.get()
            if not directory or not os.path.isdir(directory):
                messagebox.showerror("Error", "Please select a valid directory")
                return
            
            self.status_label.config(text="Scanning for duplicates...", foreground="blue")
            self.root.update()
            
            self.duplicates = self.duplicate_finder.find_duplicates(directory)
            
            # Update listbox
            self.duplicate_listbox.delete(0, tk.END)
            
            if not self.duplicates:
                self.status_label.config(text="No duplicates found!", foreground="green")
                self.clear_file_details()
                return
            
            for i, dup_group in enumerate(self.duplicates):
                # Show first two files in the group
                display_text = f"Group {i+1}: {os.path.basename(dup_group[0])} + {len(dup_group)-1} more"
                self.duplicate_listbox.insert(tk.END, display_text)
            
            self.status_label.config(
                text=f"Found {len(self.duplicates)} duplicate groups", 
                foreground="green"
            )
        
        def on_duplicate_selected(self, event):
            """Handle selection of a duplicate group."""
            selection = self.duplicate_listbox.curselection()
            if not selection:
                return
            
            index = selection[0]
            if 0 <= index < len(self.duplicates):
                self.current_duplicate_index = index
                self.display_duplicate_details(self.duplicates[index])
        
        def display_duplicate_details(self, file_list):
            """Display details of the selected duplicate files."""
            self.clear_file_details()
            
            if len(file_list) >= 1:
                self.display_file_info(self.file1_frame, self.file1_path_label, 
                                      self.file1_size_label, self.file1_modified_label,
                                      file_list[0])
            
            if len(file_list) >= 2:
                self.display_file_info(self.file2_frame, self.file2_path_label,
                                      self.file2_size_label, self.file2_modified_label,
                                      file_list[1])
            
            # If there are more than 2 files, show in title
            if len(file_list) > 2:
                self.file2_frame.config(text=f"File 2 (+{len(file_list)-2} more)")
            else:
                self.file2_frame.config(text="File 2")
        
        def display_file_info(self, frame, path_label, size_label, modified_label, filepath):
            """Display information about a single file."""
            path_label.config(text=filepath)
            
            try:
                file_size = os.path.getsize(filepath)
                size_label.config(text=f"Size: {self.format_size(file_size)}")
            except OSError:
                size_label.config(text="Size: Unknown")
            
            try:
                modified_time = os.path.getmtime(filepath)
                modified_date = datetime.datetime.fromtimestamp(modified_time).strftime('%Y-%m-%d %H:%M:%S')
                modified_label.config(text=f"Modified: {modified_date}")
            except OSError:
                modified_label.config(text="Modified: Unknown")
        
        def clear_file_details(self):
            """Clear all file detail displays."""
            self.file1_path_label.config(text="")
            self.file1_size_label.config(text="")
            self.file1_modified_label.config(text="")
            
            self.file2_path_label.config(text="")
            self.file2_size_label.config(text="")
            self.file2_modified_label.config(text="")
            
            self.file2_frame.config(text="File 2")
        
        def format_size(self, size_bytes):
            """Format file size in human-readable format."""
            for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
                if size_bytes < 1024.0:
                    return f"{size_bytes:.2f} {unit}"
                size_bytes /= 1024.0
            return f"{size_bytes:.2f} PB"
        
        def delete_file(self, file_index):
            """Delete the selected file (0 for file1, 1 for file2)."""
            if self.current_duplicate_index < 0 or self.current_duplicate_index >= len(self.duplicates):
                messagebox.showerror("Error", "No duplicate selected")
                return
            
            dup_group = self.duplicates[self.current_duplicate_index]
            
            if file_index >= len(dup_group):
                messagebox.showerror("Error", "Invalid file selection")
                return
            
            filepath = dup_group[file_index]
            
            # Confirm deletion
            confirm = messagebox.askyesno(
                "Confirm Delete",
                f"Are you sure you want to delete:\n{filepath}?"
            )
            
            if confirm:
                try:
                    os.remove(filepath)
                    self.status_label.config(
                        text=f"Deleted: {filepath}", 
                        foreground="red"
                    )
                    
                    # Remove this file from the duplicates list
                    dup_group.pop(file_index)
                    
                    # If no more files in this group, remove the group
                    if len(dup_group) < 2:
                        self.duplicates.pop(self.current_duplicate_index)
                        self.duplicate_listbox.delete(self.current_duplicate_index)
                        self.current_duplicate_index = -1
                        self.clear_file_details()
                    else:
                        # Update the display
                        self.display_duplicate_details(dup_group)
                        # Update the listbox item
                        display_text = f"Group {self.current_duplicate_index+1}: {os.path.basename(dup_group[0])} + {len(dup_group)-1} more"
                        self.duplicate_listbox.delete(self.current_duplicate_index)
                        self.duplicate_listbox.insert(self.current_duplicate_index, display_text)
                    
                    # Update status
                    if self.duplicates:
                        self.status_label.config(
                            text=f"Found {len(self.duplicates)} duplicate groups", 
                            foreground="green"
                        )
                    else:
                        self.status_label.config(
                            text="No more duplicates!", 
                            foreground="green"
                        )
                    
                except OSError as e:
                    messagebox.showerror("Error", f"Failed to delete file: {e}")
    
    root = tk.Tk()
    app = DuplicateFileCleanupApp(root)
    root.mainloop()


if __name__ == "__main__":
    main_gui()
