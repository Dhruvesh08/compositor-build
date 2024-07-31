#!/usr/bin/env nu

def read_config [] {
    open config.yml
}

def install_packages_in_directory [dir: string] {
    let deb_files = (ls $dir | where name =~ '\.deb$' | get name)
    if ($deb_files | length) > 0 {
        for file in $deb_files {
            print $"Installing package: ($file)"
            if (dpkg -i $file | complete).exit_code != 0 {
                print $"Error installing package ($file). Skipping dependency resolution."
            } else {
                print $"Successfully installed package: ($file)"
            }
        }
        print "Finished attempting to install all packages."
    } else {
        print "No .deb files found to install."
    }
    return 0
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



    cd ..
    install_packages_in_directory (pwd)

    cd ..

    print $"Done building Debian package: ($package.name)"
    return 0
}


def build_custom_package [package] {
    let package_name = $package.name
    let source_url = $package.url
    let branch = $package.branch
    let version = $package.version

    print $"Building package ($package_name) ($version) from ($source_url) on branch ($branch)"

    let orig_tarball = $"($package_name)_($version).orig.tar.gz"
    let package_dir = $"($package_name)-($version)"

    mkdri $package_name
    cd $package_name

    wget $source_url -O $orig_tarball
    mkdir $package_dir
    tar -xvf $orig_tarball -C $package_dir --strip-components=1

    # Copy the debian directory into the package
    let debian_source_dir = (pwd | path dirname | path dirname | path join $package.package_config_dir)
    if ($debian_source_dir | path exists) {
        cp -r $debian_source_dir debian
        print $"Copied debian files from ($debian_source_dir)"
    } else {
        print $"Error: Debian source directory ($debian_source_dir) not found"
        cd ../..
        return 1
    }
  

    cd $package_dir
    if (debuild -us -uc | complete).exit_code != 0 {
        print $"Error building package ($package_name)"
        return 1
    }

    cd ..
    install_packages_in_directory (pwd)

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
