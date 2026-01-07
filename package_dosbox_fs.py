#!/usr/bin/env python3
"""
Package DOSBox filesystem into Emscripten data file
"""

import os
import sys
import subprocess

def find_file_packager():
    """Find the file_packager tool in Emscripten SDK"""
    
    # Try common locations
    locations = [
        'file_packager',
        'file_packager.py',
        os.path.join(os.environ.get('EMSDK', ''), 'upstream', 'emscripten', 'tools', 'file_packager.py'),
    ]
    
    # Also check EMSDK environment variable
    emsdk_path = os.environ.get('EMSDK')
    if emsdk_path:
        locations.append(os.path.join(emsdk_path, 'upstream', 'emscripten', 'tools', 'file_packager.py'))
        locations.append(os.path.join(emsdk_path, 'emscripten', 'incoming', 'tools', 'file_packager.py'))
    
    # Check if emcc is in PATH and find its directory
    try:
        emcc_path = subprocess.check_output(['which', 'emcc'], text=True).strip()
        emscripten_dir = os.path.dirname(emcc_path)
        locations.append(os.path.join(emscripten_dir, 'tools', 'file_packager.py'))
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass
    
    for loc in locations:
        if os.path.exists(loc):
            return loc
    
    return None

def package_filesystem(source_dir, output_file):
    """Package a directory into Emscripten filesystem format"""
    
    if not os.path.exists(source_dir):
        print(f"Error: Source directory '{source_dir}' does not exist")
        sys.exit(1)
    
    # Find file_packager
    packager = find_file_packager()
    if not packager:
        print("Error: file_packager not found. Make sure Emscripten is installed and in PATH")
        print("")
        print("You can find it at:")
        print("  $EMSDK/upstream/emscripten/tools/file_packager.py")
        print("")
        print("Make sure to activate Emscripten SDK:")
        print("  source $EMSDK/emsdk_env.sh")
        sys.exit(1)
    
    print(f"Using file_packager: {packager}")
    print(f"Packaging {source_dir} into {output_file}...")
    
    cmd = [
        'python3',
        packager,
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
        print(f"Error: Python 3 not found or file_packager missing")
        sys.exit(1)

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: package_dosbox_fs.py <source_dir> <output_file>")
        sys.exit(1)
    
    package_filesystem(sys.argv[1], sys.argv[2])
