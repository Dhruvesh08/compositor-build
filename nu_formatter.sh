#!/bin/bash

if [ $# -eq 0 ]; then
    echo "No files provided. Usage: nu_formatter.sh <file1.nu> <file2.nu> ..."
    exit 1
fi

for file in "$@"; do
    awk '
    BEGIN { indent = 0 }
    /^\s*def/ { indent = 0 }
    /^\s*for/ { indent += 4 }
    /^\s*if/ { indent += 4 }
    /^\s*else/ { indent -= 4 }
    {
        line = $0
        gsub(/\t/, "    ", line)
        printf "%*s%s\n", indent, "", line
    }
    ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
done
