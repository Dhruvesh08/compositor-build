#!/usr/bin/env nu

def read_config [] {
    open config.yml
}

def build_standard_package [package] {
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


def build_custom_package [package] {
    let package_name = $package.name
    let git_url = $package.git_url
    let branch = $package.branch
    let version = $package.version

    print $"Building package ($package_name) ($version) from ($git_url) on branch ($branch)"

    let orig_tarball = $"($package_name)_($version).orig.tar.gz"
    let package_dir = $"($package_name)-($version)"

    wget $"($git_url)/archive/refs/heads/($branch).tar.gz" -O $orig_tarball
    mkdir $package_dir
    tar -xvf $orig_tarball -C $package_dir --strip-components=1

    let debian_dir = $package.package_config_dir | path expand
    cp -r $debian_dir $"($package_dir)/debian"

    cd $package_dir
    if (debuild -us -uc | complete).exit_code != 0 {
        print $"Error building package ($package_name)"
        return 1
    }

    cd ..
    print $"Package ($package_name) built successfully"
    return 0
}


def build_package [package] {
    match $package.build_type {
        "standard" => { build_standard_package $package }
        "custom" => { build_custom_package $package }
        _ => { print $"Unknown build type for package ($package.name)" }
    }
}


def main [] {
    let config = read_config

    for package in $config.packages {
        print $"Building package: ($package.name)"
        build_package $package
    }

    print "All packages built successfully"
}
