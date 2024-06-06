#!/bin/bash

# Function to recursively extract .tar and .tar.gz files
extract_files() {
    local archive_file="$1"
    local target_dir="${archive_file%.tar}"
    target_dir="${target_dir%.tar.gz}"

    # Create the target directory if it doesn't exist
    mkdir -p "$target_dir"

    # Determine the file type and extract accordingly
    case "$archive_file" in
        *.tar) tar -xf "$archive_file" -C "$target_dir" ;;
        *.tar.gz) tar -xzf "$archive_file" -C "$target_dir" ;;
        *) echo "Unsupported file type: $archive_file" ;;
    esac

    # Find all .tar and .tar.gz files in the target directory and extract them recursively
    find "$target_dir" -type f \( -name '*.tar' -o -name '*.tar.gz' \) | while read -r nested_archive; do
        extract_files "$nested_archive"
        rm "$nested_archive"  # Remove the nested archive file after extracting
    done
}

# Main script execution
for archive_file in *.tar *.tar.gz; do
    [ -e "$archive_file" ] || continue  # Skip if no .tar or .tar.gz files are found
    extract_files "$archive_file"
done
