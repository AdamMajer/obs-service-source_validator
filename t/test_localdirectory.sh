#!/bin/bash
# Test for #!CreateAsset support in 20-files-present-and-referenced

set -e

# Path to the script to test
VALIDATOR="./20-files-present-and-referenced"
TEST_DATA_DIR="t/data/localdir_test"

# Create test data directory if it doesn't exist
rm -rf "$TEST_DATA_DIR"
mkdir -p "$TEST_DATA_DIR"

# Create a dummy spec file
cat > "$TEST_DATA_DIR/test.spec" <<EOF
Name: test
Version: 1.0
Release: 0
Summary: test
License: MIT
#!CreateArchive
Source1:       node_modules.tar.xz
%description
test
%prep
%setup -q
%build
%install
%files
EOF

# A git repository may provide a directory. This can be tar'd up at build time
# without that need to re-do the tar on each commit.
mkdir "$TEST_DATA_DIR/node_modules"
touch "$TEST_DATA_DIR/node_modules/some_file"

echo "Running validator on $TEST_DATA_DIR..."
./20-files-present-and-referenced --batchmode "$TEST_DATA_DIR" || exit 1

rm -rf "$TEST_DATA_DIR/node_modules"
./20-files-present-and-referenced --batchmode "$TEST_DATA_DIR" 2>/dev/null | grep -q "ERROR: node_modules.tar.xz mentioned in spec file does not exist." || exit 1

exit 0


