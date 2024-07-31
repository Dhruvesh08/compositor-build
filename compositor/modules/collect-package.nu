#!/usr/bin/env nu

export def collect_artifacts [package_name: string, source_dir: string] {
    let assets_dir = "assets"
    let package_assets_dir = $"($assets_dir)/($package_name)"
    
    # Create assets directory if it doesn't exist
    if not ($assets_dir | path exists) {
        mkdir $assets_dir
    }
    
    # Create package-specific directory in assets
    if not ($package_assets_dir | path exists) {
        mkdir $package_assets_dir
    }

    print $"Collecting artifacts from ($source_dir)"
    # Take absolute path of source_dir
    let abs_source_dir = (realpath $source_dir)
    print $"Absolute source directory: ($abs_source_dir)"

    # Copy .deb files
    let deb_files = (ls $abs_source_dir | where name =~ '\.deb$' | get name)
    if ($deb_files | length) > 0 {
        for file in $deb_files {
            let file_path = $"($abs_source_dir)/($file)"
            if ($file_path | path exists) {
                cp $file_path $package_assets_dir
                print $"Copied ($file) to ($package_assets_dir)"
            } else {
                print $"File not found: ($file_path)"
            }
        }
    } else {
        print $"No .deb files found in ($abs_source_dir)"
    }
}