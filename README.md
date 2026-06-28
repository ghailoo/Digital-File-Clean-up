# Digital File Clean-up

A GUI application for finding and deleting duplicate files.

## Features

- Scan directories for duplicate files based on content (MD5 hash)
- View duplicate files side-by-side
- Delete unwanted duplicates with confirmation
- See file details (path, size, modification date)

## Requirements

- Python 3.x
- Tkinter (usually included with Python)

## Installation

```bash
pip install -r requirements.txt
```

## Usage

```bash
python src/file_cleanup.py
```

1. Click "Browse" to select a directory to scan
2. Click "Scan for Duplicates" to find duplicate files
3. Click on a duplicate group in the left panel
4. View the files in the right panel
5. Click "Delete File 1" or "Delete File 2" to remove the unwanted file

## How It Works

The application:
1. Recursively scans the selected directory
2. Calculates MD5 hashes for all files
3. Groups files with identical hashes as duplicates
4. Displays the duplicates in a list
5. Shows details of selected duplicates in the right panel
6. Allows deletion of unwanted files
