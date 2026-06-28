# Digital File Cleanup

A powerful macOS application for organizing, finding duplicates, and cleaning up your digital files.

## Features

### 🔍 File Scanning
- Recursively scan directories and subdirectories
- Real-time progress tracking
- Display file sizes, types, and modification dates
- Automatic duplicate detection using content hashing

### 🎯 Smart Filtering
- **All Files**: View all scanned files
- **Duplicates Only**: Show only files with identical content
- **No Metadata**: Find files missing metadata (perfect for audio/video files)
- **Audio Files**: Filter to show only audio files (MP3, WAV, AIFF, FLAC, etc.)
- **Large Files**: Find files larger than 100MB
- **Empty Files**: Identify zero-byte files
- **Directories Only**: Show only folders

### 📊 Sorting Options
- Sort by name (A-Z or Z-A)
- Sort by size (small to large or large to small)
- Sort by date (old to new or new to old)

### 🗑️ Batch Operations
- Select multiple files for batch deletion
- Select all / deselect all functionality
- Confirmation before deletion
- Error handling with detailed messages

### 👁️ File Preview
- View detailed file information
- Display metadata for audio/video files
- Show creation and modification dates
- Quick actions (Show in Finder)

### 📈 Statistics
- Total file count
- Total size of all files
- Duplicate count
- Files without metadata count

## Requirements

- macOS 12.0 (Monterey) or later
- Xcode 14.0 or later

## Installation

1. Clone this repository
2. Open the Xcode project
3. Build and run the application

## Usage

1. Click the folder icon to select a directory
2. Click "Scan" to start scanning
3. Use the filter and sort options to find specific files
4. Select files and use the delete button to remove unwanted files
5. Use the preview feature to inspect file details

## Keyboard Shortcuts

- **Escape**: Close preview window
- **Command + A**: Select all files (when in list view)
- **Command + D**: Deselect all files

## Technologies Used

- **SwiftUI**: Modern declarative UI framework
- **AVFoundation**: For metadata extraction from audio/video files
- **UniformTypeIdentifiers**: For file type handling
- **FileManager**: For file system operations

## Screenshots

*(Add screenshots here once the app is complete)*

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.
