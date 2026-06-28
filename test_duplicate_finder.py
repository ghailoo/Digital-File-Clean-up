#!/usr/bin/env python3
"""
Test script for DuplicateFileFinder (without GUI)
"""

import tempfile
import os
import sys

# Add src to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from file_cleanup import DuplicateFileFinder


def test_duplicate_finder():
    """Test the DuplicateFileFinder class."""
    print("Testing DuplicateFileFinder...")
    
    with tempfile.TemporaryDirectory() as tmpdir:
        # Create duplicate files
        file1 = os.path.join(tmpdir, 'file1.txt')
        file2 = os.path.join(tmpdir, 'file2.txt')
        file3 = os.path.join(tmpdir, 'file3.txt')
        file4 = os.path.join(tmpdir, 'subdir', 'file4.txt')
        
        # Create subdirectory
        os.makedirs(os.path.join(tmpdir, 'subdir'), exist_ok=True)
        
        with open(file1, 'w') as f:
            f.write('test content')
        with open(file2, 'w') as f:
            f.write('test content')  # Same as file1
        with open(file3, 'w') as f:
            f.write('different content')
        with open(file4, 'w') as f:
            f.write('test content')  # Same as file1 and file2
        
        finder = DuplicateFileFinder()
        duplicates = finder.find_duplicates(tmpdir)
        
        print(f'Found {len(duplicates)} duplicate groups')
        for i, group in enumerate(duplicates):
            print(f'Group {i+1}:')
            for filepath in group:
                print(f'  - {filepath}')
        
        # Verify results
        assert len(duplicates) == 1, f'Should find 1 duplicate group, found {len(duplicates)}'
        assert len(duplicates[0]) == 3, f'Group should have 3 files, found {len(duplicates[0])}'
        
        # Check that all files are in the group
        group_files = set(duplicates[0])
        expected_files = {file1, file2, file4}
        assert group_files == expected_files, f'Expected {expected_files}, got {group_files}'
        
        print("✓ All tests passed!")


if __name__ == "__main__":
    test_duplicate_finder()
