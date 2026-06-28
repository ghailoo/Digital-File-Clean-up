#!/bin/bash

# Digital File Cleanup - Xcode Setup Script
# This script copies the SwiftUI files to your Xcode project

echo "🚀 Digital File Cleanup - Xcode Setup"
echo "======================================"
echo ""

# Source directory (where the files are)
SOURCE_DIR="$HOME/Digital-File-Clean-up"

# Check if source files exist
echo "🔍 Checking source files..."
if [ ! -f "$SOURCE_DIR/ContentView.swift" ]; then
    echo "❌ Error: ContentView.swift not found in $SOURCE_DIR"
    echo "   Please run: cd $SOURCE_DIR && git pull origin main"
    exit 1
fi

if [ ! -f "$SOURCE_DIR/DigitalFileCleanupApp.swift" ]; then
    echo "❌ Error: DigitalFileCleanupApp.swift not found in $SOURCE_DIR"
    exit 1
fi

if [ ! -f "$SOURCE_DIR/Info.plist" ]; then
    echo "❌ Error: Info.plist not found in $SOURCE_DIR"
    exit 1
fi

echo "✅ All source files found!"
echo ""

# Target directory (where Xcode expects them)
TARGET_DIR="$HOME/Desktop/MacOS Project/DigitalFileCleanup/DigitalFileCleanup"

echo "📁 Target directory: $TARGET_DIR"

# Check if target directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo "❌ Error: Target directory does not exist!"
    echo "   Expected: $TARGET_DIR"
    echo ""
    echo "Please make sure your Xcode project is at:"
    echo "   $HOME/Desktop/MacOS Project/DigitalFileCleanup/"
    exit 1
fi

echo "✅ Target directory exists!"
echo ""

# Copy files
echo "📝 Copying files..."
cp "$SOURCE_DIR/ContentView.swift" "$TARGET_DIR/"
cp "$SOURCE_DIR/DigitalFileCleanupApp.swift" "$TARGET_DIR/"
cp "$SOURCE_DIR/Info.plist" "$TARGET_DIR/"

echo "✅ Files copied successfully!"
echo ""

# Verify files were copied
echo "🔍 Verifying copied files..."
if [ -f "$TARGET_DIR/ContentView.swift" ]; then
    echo "   ✅ ContentView.swift"
else
    echo "   ❌ ContentView.swift"
fi

if [ -f "$TARGET_DIR/DigitalFileCleanupApp.swift" ]; then
    echo "   ✅ DigitalFileCleanupApp.swift"
else
    echo "   ❌ DigitalFileCleanupApp.swift"
fi

if [ -f "$TARGET_DIR/Info.plist" ]; then
    echo "   ✅ Info.plist"
else
    echo "   ❌ Info.plist"
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. Open your Xcode project"
echo "2. Clean the build folder (Product > Clean Build Folder)"
echo "3. Build and run (Command + R)"
echo ""
echo "If you get build errors:"
echo "- Make sure 'import AVFoundation' is allowed"
echo "- Check that the Info.plist is added to your target"
echo "- Ensure the bundle identifier matches in Info.plist"
