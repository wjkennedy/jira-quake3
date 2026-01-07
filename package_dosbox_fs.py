#!/usr/bin/env python3
"""
Package DOSBox filesystem into Emscripten data file
"""

import os
import sys
import subprocess

def package_filesystem(source_dir, output_file):
    """Package a directory into Emscripten filesystem format"""
    
    if not os.path.exists(source_dir):
        print(f"Error: Source directory '{source_dir}' does not exist")
        sys.exit(1)
    
    print(f"Packaging {source_dir} into {output_file}...")
    
    # Use Emscripten file_packager tool
    cmd = [
        'file_packager',
        output_file,
        '--preload',
        f'{source_dir}@/',
        '--js-output=' + output_file.replace('.data', '.js')
    ]
    
    try:
        subprocess.run(cmd, check=True)
        print(f"✓ Successfully packaged filesystem")
    except subprocess.CalledProcessError as e:
        print(f"Error: Failed to package filesystem: {e}")
        sys.exit(1)
    except FileNotFoundError:
        print("Error: file_packager not found. Make sure Emscripten is installed and in PATH")
        sys.exit(1)

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: package_dosbox_fs.py <source_dir> <output_file>")
        sys.exit(1)
    
    package_filesystem(sys.argv[1], sys.argv[2])
