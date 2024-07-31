#!/usr/bin/env nu

def read_config [] {
    open config.yml
}

def build_debian_package [package] {
    let base_version = ($package.version | split row "-" | first)
    let dir_name = $package.name
    let inner_dir_name = $"($package.name)-($base_version)"
    
    # Check if directory exists and remove it if it does
    if ($dir_name | path exists) {
        print $"Directory ($dir_name) already exists. Removing it..."
        rm -rf $dir_name
    }

    # Create a directory for the package
    mkdir $dir_name
    cd $dir_name

    # Download and extract the package
    dget -u $package.url


    # List the files in the directory
    if (ls -la | length) > 0 {
        print "***********Listing files in the directory*********"
        print (ls -la)
    } else {
        print "No files found in the directory."
    }

    # Change to the inner directory
    cd $inner_dir_name
    if (pwd | path exists) {
        print "Changed to directory: $inner_dir_name"
    } else {
        print $"Error: Directory ($inner_dir_name) does not exist."
        return 1
    }


    # Build the package
    if (debuild -us -uc | complete).exit_code != 0 {
        print $"Error building package ($package.name)"
        return 1
    }

    cd ../..
    print $"Done building Debian package: ($package.name)"
    return 0
}

def main [] {
    let config = read_config

    for package in $config.packages {
        print $"Building package: ($package.name)"
        build_debian_package $package
    }

    print "All packages built successfully"
}
