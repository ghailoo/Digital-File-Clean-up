//
//  ContentView.swift
//  DigitalFileCleanup
//
//  Created by Ghailen Ben Othman on 28/06/2026.
//

import SwiftUI
import UniformTypeIdentifiers
import AVFoundation
import Combine

// MARK: - File Item Model

struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let url: URL
    let size: Int64
    let sizeString: String
    let isDirectory: Bool
    let hasMetadata: Bool
    let lastModified: Date
    let fileExtension: String
    
    // For duplicate detection
    let contentHash: String?
    
    init(url: URL, size: Int64, isDirectory: Bool, hasMetadata: Bool, lastModified: Date, contentHash: String? = nil) {
        self.url = url
        self.name = url.lastPathComponent
        self.size = size
        self.sizeString = ByteCountFormatter().string(fromByteCount: size)
        self.isDirectory = isDirectory
        self.hasMetadata = hasMetadata
        self.lastModified = lastModified
        self.fileExtension = url.pathExtension.lowercased()
        self.contentHash = contentHash
    }
}

// MARK: - Filter Options

enum FileFilter: String, CaseIterable, Identifiable {
    case all = "All Files"
    case duplicates = "Duplicates Only"
    case noMetadata = "No Metadata"
    case audioFiles = "Audio Files"
    case largeFiles = "Large Files (>100MB)"
    case emptyFiles = "Empty Files"
    case directories = "Directories Only"
    
    var id: String { self.rawValue }
}

// MARK: - Sort Options

enum SortOption: String, CaseIterable, Identifiable {
    case nameAscending = "Name (A-Z)"
    case nameDescending = "Name (Z-A)"
    case sizeAscending = "Size (Small to Large)"
    case sizeDescending = "Size (Large to Small)"
    case dateAscending = "Date (Old to New)"
    case dateDescending = "Date (New to Old)"
    
    var id: String { self.rawValue }
}

// MARK: - Data Model for Environment

class FileData: ObservableObject {
    @Published var files: [FileItem] = []
}

// MARK: - Main Content View

struct ContentView: View {
    @State private var files: [FileItem] = []
    @State private var selectedDirectory: URL?
    @State private var showFileImporter = false
    @State private var alertMessage: String?
    @State private var isScanning = false
    @State private var scanProgress: Double = 0.0
    @State private var totalFilesFound = 0
    @State private var processedFiles = 0
    
    // Filter and sort states
    @State private var selectedFilter: FileFilter = .all
    @State private var selectedSort: SortOption = .nameAscending
    @State private var searchText: String = ""
    
    // Selection for batch operations
    @State private var selectedFileIDs: Set<UUID> = []
    
    // Preview state
    @State private var previewFile: FileItem?
    @State private var showPreview = false
    
    // Statistics
    @State private var totalSize: Int64 = 0
    @State private var duplicateCount = 0
    @State private var noMetadataCount = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with controls
                headerView
                
                // Divider
                Divider()
                
                // Main content area
                mainContentView
            }
            .navigationTitle("Digital File Cleanup")
            .alert("Message", isPresented: Binding(
                get: { alertMessage != nil },
                set: { if !$0 { alertMessage = nil } }
            )) {
                Button("OK", role: .cancel) { alertMessage = nil }
            } message: {
                Text(alertMessage ?? "")
            }
            .sheet(isPresented: $showPreview) {
                if let previewFile = previewFile {
                    FilePreviewView(file: previewFile, isPresented: $showPreview)
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.folder],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result: result)
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 12) {
            // Directory selection and scan controls
            HStack {
                // Directory selection
                HStack(spacing: 8) {
                    TextField(
                        "Select a directory...",
                        text: Binding(
                            get: { selectedDirectory?.path ?? "" },
                            set: { _ in }
                        )
                    )
                    .textFieldStyle(.roundedBorder)
                    .disabled(true)
                    
                    Button(action: { showFileImporter = true }) {
                        Image(systemName: "folder")
                            .font(.title3)
                    }
                    .help("Select Directory")
                }
                
                // Scan button
                Button(action: scanSelectedDirectory) {
                    if isScanning {
                        HStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Scanning...")
                        }
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                            Text("Scan")
                        }
                    }
                }
                .disabled(isScanning || selectedDirectory == nil)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                // Statistics
                if !isScanning && !files.isEmpty {
                    HStack(spacing: 20) {
                        Text("Total: \(files.count) files")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Size: \(ByteCountFormatter().string(fromByteCount: totalSize))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if duplicateCount > 0 {
                            Text("Duplicates: \(duplicateCount)")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        
                        if noMetadataCount > 0 {
                            Text("No Metadata: \(noMetadataCount)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            
            // Progress bar
            if isScanning {
                VStack(spacing: 4) {
                    ProgressView(value: scanProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    
                    HStack {
                        Text("Scanning files...")
                            .font(.caption)
                        
                        Spacer()
                        
                        Text("Processed: \(processedFiles)/\(totalFilesFound)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Filter and sort controls
            HStack {
                // Search
                TextField("🔍 Search files...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                    .onChange(of: searchText) {
                        // Filter will update automatically
                    }
                
                Spacer()
                
                // Filter picker
                Picker("Filter:", selection: $selectedFilter) {
                    ForEach(FileFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 150)
                
                // Sort picker
                Picker("Sort:", selection: $selectedSort) {
                    ForEach(SortOption.allCases) { sort in
                        Text(sort.rawValue).tag(sort)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 180)
            }
            
            // Batch operations toolbar
            if !filteredFiles.isEmpty {
                HStack {
                    Text("Selected: \(selectedFileIDs.count) files")
                        .font(.caption)
                    
                    Spacer()
                    
                    Button(action: selectAllFiles) {
                        Text("Select All")
                    }
                    .disabled(filteredFiles.isEmpty)
                    
                    Button(action: deselectAllFiles) {
                        Text("Deselect All")
                    }
                    .disabled(selectedFileIDs.isEmpty)
                    
                    Button(action: deleteSelectedFiles) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text("Delete Selected")
                        }
                    }
                    .disabled(selectedFileIDs.isEmpty)
                    .foregroundColor(.red)
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor))
    }
    
    // MARK: - Main Content View
    
    private var mainContentView: some View {
        Group {
            if isScanning {
                // Show loading state
                VStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(2)
                    Text("Scanning directory...")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else if filteredFiles.isEmpty && !searchText.isEmpty {
                // No search results
                VStack {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("No files match your search")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else if filteredFiles.isEmpty {
                // No files scanned yet
                VStack {
                    Spacer()
                    Image(systemName: "folder")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("Select a directory and click Scan")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("to find and organize your files")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                // File list
                fileListView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - File List View
    
    private var fileListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredFiles) { file in
                    FileRowView(
                        file: file,
                        isSelected: selectedFileIDs.contains(file.id),
                        onSelected: { isSelected in
                            if isSelected {
                                selectedFileIDs.insert(file.id)
                            } else {
                                selectedFileIDs.remove(file.id)
                            }
                        },
                        onPreview: { file in
                            previewFile = file
                            showPreview = true
                        },
                        onDelete: { file in
                            confirmDelete(file: file)
                        },
                        allFiles: files
                    )
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        selectedFileIDs.contains(file.id) ? 
                            Color.blue.opacity(0.1) : 
                            Color.clear
                    )
                    .cornerRadius(8)
                    .onTapGesture {
                        // Toggle selection on tap
                        if selectedFileIDs.contains(file.id) {
                            selectedFileIDs.remove(file.id)
                        } else {
                            selectedFileIDs.insert(file.id)
                        }
                    }
                    
                    Divider()
                        .padding(.horizontal, 8)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredFiles: [FileItem] {
        var result = files
        
        // Apply filter
        switch selectedFilter {
        case .all:
            break
        case .duplicates:
            // Find files that have the same content hash
            let hashCounts = Dictionary(grouping: result, by: { $0.contentHash }).mapValues { $0.count }
            result = result.filter { file in
                guard let hash = file.contentHash else { return false }
                return hashCounts[hash] ?? 0 > 1
            }
        case .noMetadata:
            result = result.filter { !$0.hasMetadata }
        case .audioFiles:
            let audioExtensions = ["mp3", "wav", "aiff", "aif", "flac", "m4a", "ogg", "wma"]
            result = result.filter { audioExtensions.contains($0.fileExtension) }
        case .largeFiles:
            result = result.filter { $0.size > 100 * 1024 * 1024 } // >100MB
        case .emptyFiles:
            result = result.filter { $0.size == 0 }
        case .directories:
            result = result.filter { $0.isDirectory }
        }
        
        // Apply search
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            result = result.filter { 
                $0.name.lowercased().contains(searchLower) || 
                $0.url.path.lowercased().contains(searchLower)
            }
        }
        
        // Apply sort
        switch selectedSort {
        case .nameAscending:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDescending:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .sizeAscending:
            result.sort { $0.size < $1.size }
        case .sizeDescending:
            result.sort { $0.size > $1.size }
        case .dateAscending:
            result.sort { $0.lastModified < $1.lastModified }
        case .dateDescending:
            result.sort { $0.lastModified > $1.lastModified }
        }
        
        return result
    }
    
    // MARK: - Actions
    
    private func scanSelectedDirectory() {
        guard let directory = selectedDirectory else {
            alertMessage = "Please select a directory first"
            return
        }
        
        scanDirectory(directory)
    }
    
    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let directoryURL = urls.first {
                selectedDirectory = directoryURL
                scanDirectory(directoryURL)
            }
        case .failure(let error):
            alertMessage = "Error: \(error.localizedDescription)"
        }
    }
    
    private func scanDirectory(_ directoryURL: URL) {
        isScanning = true
        files = []
        totalFilesFound = 0
        processedFiles = 0
        scanProgress = 0.0
        totalSize = 0
        duplicateCount = 0
        noMetadataCount = 0
        selectedFileIDs = []
        
        DispatchQueue.global(qos: .userInitiated).async {
            let fileManager = FileManager.default
            
            do {
                // Get all files recursively
                let enumerator = fileManager.enumerator(at: directoryURL, 
                                                         includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .contentModificationDateKey],
                                                         options: [.skipsHiddenFiles, .skipsPackageDescendants],
                                                         errorHandler: nil)
                
                // Collect all file URLs first for progress calculation
                var allFileURLs: [URL] = []
                while let fileURL = enumerator?.nextObject() as? URL {
                    allFileURLs.append(fileURL)
                }
                
                totalFilesFound = allFileURLs.count
                var processedCount = 0
                var tempFiles: [FileItem] = []
                
                // Process files in batches for better performance
                let batchSize = 50
                for chunk in allFileURLs.chunked(into: batchSize) {
                    var batchFiles: [FileItem] = []
                    
                    for fileURL in chunk {
                        do {
                            let resourceValues = try fileURL.resourceValues(forKeys: [
                                .fileSizeKey, 
                                .isDirectoryKey,
                                .contentModificationDateKey
                            ])
                            
                            let isDirectory = resourceValues.isDirectory ?? false
                            let fileSize = Int64(resourceValues.fileSize ?? 0)
                            let modDate = resourceValues.contentModificationDate ?? Date.distantPast
                            
                            // Check for metadata (only for audio/video files)
                            let hasMetadata = checkMetadata(for: fileURL)
                            
                            // Calculate content hash for duplicate detection (only for files, not directories)
                            var contentHash: String? = nil
                            if !isDirectory && fileSize > 0 && fileSize < 50 * 1024 * 1024 { // Only hash files < 50MB
                                contentHash = calculateFileHash(fileURL)
                            }
                            
                            let fileItem = FileItem(
                                url: fileURL,
                                size: fileSize,
                                isDirectory: isDirectory,
                                hasMetadata: hasMetadata,
                                lastModified: modDate,
                                contentHash: contentHash
                            )
                            
                            batchFiles.append(fileItem)
                            
                        } catch {
                            print("Error reading file: \(error.localizedDescription)")
                        }
                        
                        processedCount += 1
                    }
                    
                    // Update progress
                    DispatchQueue.main.async {
                        processedFiles = processedCount
                        scanProgress = Double(processedCount) / Double(totalFilesFound)
                        tempFiles.append(contentsOf: batchFiles)
                    }
                }
                
                // Calculate statistics
                let total = tempFiles.reduce(0) { $0 + $1.size }
                let noMetadata = tempFiles.filter { !$0.hasMetadata }.count
                
                // Count duplicates by content hash
                let hashCounts = Dictionary(grouping: tempFiles, by: { $0.contentHash }).mapValues { $0.count }
                let duplicates = hashCounts.filter { $0.value > 1 }.count
                
                // Update UI on main thread
                DispatchQueue.main.async {
                    files = tempFiles
                    totalSize = total
                    noMetadataCount = noMetadata
                    duplicateCount = duplicates
                    isScanning = false
                }
                
            } catch {
                DispatchQueue.main.async {
                    alertMessage = "Error scanning directory: \(error.localizedDescription)"
                    isScanning = false
                }
            }
        }
    }
    
    private func checkMetadata(for url: URL) -> Bool {
        // Only check audio/video files for metadata
        let audioExtensions = ["mp3", "wav", "aiff", "aif", "flac", "m4a", "ogg", "wma", "mp4", "mov", "avi"]
        
        if audioExtensions.contains(url.pathExtension.lowercased()) {
            // Use modern AVURLAsset API
            let asset = AVURLAsset(url: url)
            // Use async loading for metadata
            let semaphore = DispatchSemaphore(value: 0)
            var hasMetadata = false
            
            asset.load(.metadata) { status in
                hasMetadata = status == .loaded
                semaphore.signal()
            }
            
            _ = semaphore.wait(timeout: .now() + 1.0)
            return hasMetadata
        }
        
        // For other files, we'll just return true for now
        return true
    }
    
    private func calculateFileHash(_ url: URL) -> String? {
        do {
            let fileHandle = try FileHandle(forReadingFrom: url)
            defer { fileHandle.closeFile() }
            
            var hasher = Hasher()
            
            // Read in chunks to handle large files
            let chunkSize = 4096
            while autoreleasepool(invoking: {
                let data = fileHandle.readData(ofLength: chunkSize)
                if !data.isEmpty {
                    data.withUnsafeBytes { buffer in
                        hasher.combine(bytes: buffer)
                    }
                    return true
                }
                return false
            }) {}
            
            return "\(hasher.finalize())"
        } catch {
            print("Error calculating hash for \(url.lastPathComponent): \(error)")
            return nil
        }
    }
    
    private func confirmDelete(file: FileItem) {
        if file.isDirectory {
            alertMessage = "Cannot delete directory. Please delete files individually."
            return
        }
        
        // Delete without confirmation for now (simplified)
        do {
            try FileManager.default.removeItem(at: file.url)
            files.removeAll { $0.id == file.id }
            selectedFileIDs.remove(file.id)
            alertMessage = "File deleted successfully"
        } catch {
            alertMessage = "Error deleting file: \(error.localizedDescription)"
        }
    }
    
    private func deleteSelectedFiles() {
        guard !selectedFileIDs.isEmpty else { return }
        
        var deletedCount = 0
        var errors: [String] = []
        
        for file in files where selectedFileIDs.contains(file.id) {
            if !file.isDirectory {
                do {
                    try FileManager.default.removeItem(at: file.url)
                    deletedCount += 1
                } catch {
                    errors.append("\(file.name): \(error.localizedDescription)")
                }
            }
        }
        
        // Remove deleted files from list
        files.removeAll { selectedFileIDs.contains($0.id) }
        selectedFileIDs = []
        
        if errors.isEmpty {
            alertMessage = "Deleted \(deletedCount) file(s) successfully"
        } else {
            alertMessage = "Deleted \(deletedCount) file(s). Errors: \(errors.joined(separator: ", "))"
        }
    }
    
    private func selectAllFiles() {
        selectedFileIDs = Set(filteredFiles.map { $0.id })
    }
    
    private func deselectAllFiles() {
        selectedFileIDs = []
    }
}

// MARK: - File Row View

struct FileRowView: View {
    let file: FileItem
    let isSelected: Bool
    let onSelected: (Bool) -> Void
    let onPreview: (FileItem) -> Void
    let onDelete: (FileItem) -> Void
    let allFiles: [FileItem]
    
    private var filesWithSameHash: [FileItem] {
        guard let hash = file.contentHash else { return [] }
        return allFiles.filter { $0.contentHash == hash }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection checkbox
            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                .foregroundColor(isSelected ? .blue : .secondary)
                .onTapGesture {
                    onSelected(!isSelected)
                }
            
            // File icon
            fileIcon
                .font(.title2)
                .foregroundColor(fileIconColor)
            
            // File info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(file.name)
                        .font(.body)
                        .lineLimit(1)
                    
                    if file.isDirectory {
                        Text("Directory")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    if !file.hasMetadata && !file.isDirectory {
                        Text("No Metadata")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(4)
                    }
                    
                    if filesWithSameHash.count > 1 {
                        Text("Duplicate")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.8))
                            .cornerRadius(4)
                    }
                }
                
                HStack {
                    Text(file.sizeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(file.fileExtension)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Action buttons
            HStack(spacing: 8) {
                Button(action: { onPreview(file) }) {
                    Image(systemName: "eye")
                        .font(.caption)
                }
                .help("Preview")
                .disabled(file.isDirectory)
                
                Button(action: { onDelete(file) }) {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .help("Delete")
                .foregroundColor(.red)
            }
        }
        .padding(8)
        .contentShape(Rectangle())
    }
    
    private var fileIcon: some View {
        Group {
            if file.isDirectory {
                Image(systemName: "folder")
            } else {
                fileIconForExtension
            }
        }
    }
    
    private var fileIconForExtension: some View {
        let extensionIcons: [String: String] = [
            "mp3": "music.note",
            "wav": "waveform",
            "aiff": "music.note",
            "aif": "music.note",
            "flac": "music.note",
            "m4a": "music.note",
            "ogg": "music.note",
            "wma": "music.note",
            "mp4": "film",
            "mov": "film",
            "avi": "film",
            "jpg": "photo",
            "jpeg": "photo",
            "png": "photo",
            "gif": "photo",
            "pdf": "doc",
            "doc": "doc",
            "docx": "doc",
            "txt": "doc.text",
            "zip": "folder",
            "rar": "folder",
            "dmg": "folder"
        ]
        
        return Image(systemName: extensionIcons[file.fileExtension] ?? "doc")
    }
    
    private var fileIconColor: Color {
        if file.isDirectory {
            return .blue
        }
        
        let extensionColors: [String: Color] = [
            "mp3": .purple,
            "wav": .purple,
            "aiff": .purple,
            "aif": .purple,
            "flac": .purple,
            "m4a": .purple,
            "ogg": .purple,
            "wma": .purple,
            "mp4": .teal,
            "mov": .teal,
            "avi": .teal,
            "jpg": .orange,
            "jpeg": .orange,
            "png": .orange,
            "gif": .orange,
            "pdf": .red,
            "doc": .blue,
            "docx": .blue,
            "txt": .gray,
            "zip": .yellow,
            "rar": .yellow,
            "dmg": .yellow
        ]
        
        return extensionColors[file.fileExtension] ?? .gray
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: file.lastModified)
    }
}

// MARK: - File Preview View

struct FilePreviewView: View {
    let file: FileItem
    @Binding var isPresented: Bool
    
    @State private var metadata: [String: String] = [:]
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("File Preview")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                }
            }
            .padding(.bottom, 8)
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Basic info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Basic Information")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        InfoRow(label: "Name", value: file.name)
                        InfoRow(label: "Path", value: file.url.path)
                        InfoRow(label: "Type", value: file.isDirectory ? "Directory" : "File")
                        InfoRow(label: "Size", value: file.sizeString)
                        InfoRow(label: "Extension", value: file.fileExtension.isEmpty ? "None" : file.fileExtension)
                        InfoRow(label: "Modified", value: formattedDate)
                    }
                    
                    Divider()
                    
                    // Metadata
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Metadata")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        if isLoading {
                            ProgressView()
                                .padding(.vertical, 8)
                        } else if metadata.isEmpty {
                            Text("No metadata found")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(metadata.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                InfoRow(label: key, value: value)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Quick actions
                    HStack {
                        Spacer()
                        
                        Button(action: { 
                            // Open in Finder
                            NSWorkspace.shared.selectFile(file.url.path, inFileViewerRootedAtPath: file.url.deletingLastPathComponent().path)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "folder")
                                Text("Show in Finder")
                            }
                        }
                        
                        Button(action: { isPresented = false }) {
                            Text("Close")
                        }
                        .keyboardShortcut(.escape)
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(width: 500, height: 400)
        .onAppear {
            loadMetadata()
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: file.lastModified)
    }
    
    private func loadMetadata() {
        DispatchQueue.global(qos: .userInitiated).async {
            var tempMetadata: [String: String] = [:]
            
            // Try to get metadata for audio/video files
            if !file.isDirectory {
                let audioExtensions = ["mp3", "wav", "aiff", "aif", "flac", "m4a", "ogg", "wma", "mp4", "mov", "avi"]
                
                if audioExtensions.contains(file.fileExtension.lowercased()) {
                    // Use modern AVURLAsset API
                    let asset = AVURLAsset(url: file.url)
                    let semaphore = DispatchSemaphore(value: 0)
                    
                    asset.load(.metadata) { status in
                        if status == .loaded {
                            for item in asset.metadata {
                                if let key = item.commonKey?.rawValue {
                                    // Use load(.value) for modern API
                                    item.load(.value) { valueStatus in
                                        if valueStatus == .loaded, let value = item.value as? String {
                                            tempMetadata[key] = value
                                        }
                                        semaphore.signal()
                                    }
                                } else if let key = item.key as? String {
                                    item.load(.value) { valueStatus in
                                        if valueStatus == .loaded, let value = item.value as? String {
                                            tempMetadata[key] = value
                                        }
                                        semaphore.signal()
                                    }
                                }
                            }
                        }
                        semaphore.signal()
                    }
                    
                    _ = semaphore.wait(timeout: .now() + 2.0)
                }
                
                // Get file attributes
                do {
                    let attributes = try FileManager.default.attributesOfItem(atPath: file.url.path)
                    if let creationDate = attributes[.creationDate] as? Date {
                        let formatter = DateFormatter()
                        formatter.dateStyle = .medium
                        formatter.timeStyle = .medium
                        tempMetadata["Created"] = formatter.string(from: creationDate)
                    }
                } catch {
                    print("Error loading attributes: \(error)")
                }
            }
            
            DispatchQueue.main.async {
                metadata = tempMetadata
                isLoading = false
            }
        }
    }
}

// MARK: - Helper Views

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text("\(label):")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
    }
}

// MARK: - Extensions

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
