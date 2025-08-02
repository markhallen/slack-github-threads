#!/bin/bash

# slack-github-threads Release Script
# Usage: ./scripts/release.sh [major|minor|patch]
# Example: ./scripts/release.sh minor

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Determine bump type
BUMP_TYPE=${1:-"auto"}

# If no argument provided, show preview and ask user
if [ "$BUMP_TYPE" = "auto" ]; then
    print_status "Analyzing commits to suggest release type..."

    if command -v bundle &> /dev/null; then
        bundle exec rake release:preview
    else
        rake release:preview
    fi

    echo
    echo "Release types:"
    echo "  major - Breaking changes (1.0.0 → 2.0.0)"
    echo "  minor - New features (1.0.0 → 1.1.0)"
    echo "  patch - Bug fixes (1.0.0 → 1.0.1)"
    echo
    read -p "Which type of release? [major/minor/patch]: " -r
    BUMP_TYPE=$REPLY
fi

# Validate bump type
if [[ ! "$BUMP_TYPE" =~ ^(major|minor|patch)$ ]]; then
    print_error "Invalid release type. Use: major, minor, or patch"
    echo "Usage: $0 [major|minor|patch]"
    exit 1
fi

print_status "Creating $BUMP_TYPE release..."

# Check if we're on the main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    print_warning "You are not on the main branch (current: $CURRENT_BRANCH)"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Aborted"
        exit 1
    fi
fi

# Check if working directory is clean
if [ -n "$(git status --porcelain)" ]; then
    print_error "Working directory is not clean. Please commit or stash your changes."
    git status --short
    exit 1
fi

# Use Rake task to create the release
print_status "Using Rake to create $BUMP_TYPE release (includes tests, changelog, and tagging)..."
if command -v bundle &> /dev/null; then
    bundle exec rake release:create[$BUMP_TYPE]
else
    rake release:create[$BUMP_TYPE]
fi

# Extract the version that was just created
VERSION=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//')
if [ -z "$VERSION" ]; then
    print_error "No tags found in the repository. Release creation may have failed."
    exit 1
fi
TAG="v$VERSION"

print_status "Release $VERSION created successfully!"
print_status "Now push the changes and tag to GitHub..."

echo
read -p "Push to GitHub now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Pushing changes and tag to GitHub..."
    git push origin "$CURRENT_BRANCH"
    git push origin "$TAG"

    print_status "🎉 Release $VERSION pushed to GitHub!"
    print_status "GitHub Actions will automatically create the release."
    print_status "Monitor progress at: https://github.com/markhallen/slack-github-threads/actions"
else
    print_status "Manual push required:"
    echo "  git push origin $CURRENT_BRANCH"
    echo "  git push origin $TAG"
fi

echo
print_status "Next steps:"
echo "  1. Monitor the GitHub Actions workflow"
echo "  2. Verify the release was created at: https://github.com/markhallen/slack-github-threads/releases"
echo "  3. Update any deployment configurations if needed"
