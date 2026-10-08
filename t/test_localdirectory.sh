#!/bin/bash
# Test for #!CreateArchive support in 20-files-present-and-referenced

set -e

# Path to the script to test
VALIDATOR="./20-files-present-and-referenced"
TEST_DATA_DIR="t/data/localdir_test"

cleanup() {
    rm -rf "$TEST_DATA_DIR"
}
trap cleanup EXIT

# 1. Test non-git directory
rm -rf "$TEST_DATA_DIR"
mkdir -p "$TEST_DATA_DIR"

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

mkdir "$TEST_DATA_DIR/node_modules"
touch "$TEST_DATA_DIR/node_modules/some_file"

echo "Running validator on non-git directory..."
"$VALIDATOR" --batchmode "$TEST_DATA_DIR" || exit 1

rm -rf "$TEST_DATA_DIR/node_modules"
"$VALIDATOR" --batchmode "$TEST_DATA_DIR" 2>/dev/null | grep -q "ERROR: node_modules.tar.xz mentioned in spec file does not exist." || exit 1

# 2. Test Git repository with tracked, untracked, and gitignored directory assets
rm -rf "$TEST_DATA_DIR"
mkdir -p "$TEST_DATA_DIR"
cd "$TEST_DATA_DIR"
git init -q
git config user.name "Test"
git config user.email "test@example.com"

cat > test.spec <<EOF
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

mkdir node_modules
touch node_modules/some_file
git add test.spec node_modules
git commit -q -m "initial commit"
cd - >/dev/null

echo "Running validator on Git repo with tracked directory asset..."
"$VALIDATOR" --batchmode "$TEST_DATA_DIR" || exit 1

# Test gitignored directory asset in Git repo
cd "$TEST_DATA_DIR"
echo "node_modules" > .gitignore
git rm -r -q --cached node_modules
git add .gitignore
git commit -q -m "ignore node_modules"
cd - >/dev/null

echo "Running validator on Git repo with gitignored directory asset (expected failure)..."
if "$VALIDATOR" --batchmode "$TEST_DATA_DIR" 2>/dev/null; then
    echo "ERROR: validator should have failed on gitignored directory asset"
    exit 1
fi

# Test untracked directory asset in Git repo
cd "$TEST_DATA_DIR"
git rm -q .gitignore
git commit -q -m "remove gitignore"
cd - >/dev/null

echo "Running validator on Git repo with untracked directory asset (expected failure)..."
if "$VALIDATOR" --batchmode "$TEST_DATA_DIR" 2>/dev/null; then
    echo "ERROR: validator should have failed on untracked directory asset"
    exit 1
fi

# 3. Test explicit custom directory name (#!CreateArchive: custom_dir)
rm -rf "$TEST_DATA_DIR"
mkdir -p "$TEST_DATA_DIR"
cd "$TEST_DATA_DIR"
git init -q
git config user.name "Test"
git config user.email "test@example.com"

cat > test.spec <<EOF
Name: test
Version: 1.0
Release: 0
Summary: test
License: MIT
#!CreateArchive: custom_dir
Source1:       custom_archive.tar.xz
%description
test
%prep
%setup -q
%build
%install
%files
EOF

mkdir custom_dir
touch custom_dir/file
git add test.spec custom_dir
git commit -q -m "custom dir commit"
cd - >/dev/null

echo "Running validator with #!CreateArchive: custom_dir..."
"$VALIDATOR" --batchmode "$TEST_DATA_DIR" || exit 1

# 4. Test archive with .tar in the filename stem (e.g. my.tar.ball-1.0.tar.xz)
rm -rf "$TEST_DATA_DIR"
mkdir -p "$TEST_DATA_DIR"
cd "$TEST_DATA_DIR"
git init -q
git config user.name "Test"
git config user.email "test@example.com"

cat > test.spec <<EOF
Name: test
Version: 1.0
Release: 0
Summary: test
License: MIT
#!CreateArchive
Source1:       my.tar.ball-1.0.tar.xz
%description
test
%prep
%setup -q
%build
%install
%files
EOF

mkdir "my.tar.ball-1.0"
touch "my.tar.ball-1.0/file"
git add test.spec "my.tar.ball-1.0"
git commit -q -m "tar in filename commit"
cd - >/dev/null

echo "Running validator with .tar in archive name..."
"$VALIDATOR" --batchmode "$TEST_DATA_DIR" || exit 1

exit 0
