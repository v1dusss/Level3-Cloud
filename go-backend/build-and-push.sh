#!/bin/bash

# Docker Build and Push Automation Script
# This script builds your Go application Docker image and pushes it to your Docker repository

set -e  # Exit on any error

# Configuration
DOCKER_USERNAME="v1dusss"
IMAGE_NAME="go-backend"
DOCKER_REPO="${DOCKER_USERNAME}/${IMAGE_NAME}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to get next version
get_next_version() {
    local current_version=$1
    local version_type=$2
    
    # Extract version numbers
    IFS='.' read -ra VERSION_PARTS <<< "${current_version#v}"
    major=${VERSION_PARTS[0]}
    minor=${VERSION_PARTS[1]}
    patch=${VERSION_PARTS[2]}
    
    case $version_type in
        "major")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        "minor")
            minor=$((minor + 1))
            patch=0
            ;;
        "patch"|*)
            patch=$((patch + 1))
            ;;
    esac
    
    echo "v${major}.${minor}.${patch}"
}

# Function to get current version from main.go
get_current_version_from_code() {
    if [ -f "main.go" ]; then
        # Extract version from the response string in main.go
        version=$(grep -o 'v1dusss/go-backend:v[0-9]*\.[0-9]*\.[0-9]*' main.go | head -1 | sed 's/.*://')
        if [ -n "$version" ]; then
            echo "$version"
        else
            echo "v1.0.0"
        fi
    else
        echo "v1.0.0"
    fi
}

# Function to update version in main.go
update_version_in_code() {
    local new_version=$1
    if [ -f "main.go" ]; then
        # Update the version in the HTTP response
        sed -i "s|v1dusss/go-backend:v[0-9]*\.[0-9]*\.[0-9]*|v1dusss/go-backend:${new_version}|g" main.go
        print_status "Updated version in main.go to ${new_version}"
    fi
}

# Check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_success "Docker is running"
}

# Login to Docker Hub
docker_login() {
    print_status "Checking Docker Hub authentication..."
    
    if ! docker info | grep -q "Username"; then
        print_warning "Not logged in to Docker Hub. Attempting to log in..."
        if ! docker login; then
            print_error "Failed to log in to Docker Hub"
            exit 1
        fi
    fi
    print_success "Docker Hub authentication confirmed"
}

# Build Docker image
build_image() {
    local tag=$1
    print_status "Building Docker image: ${DOCKER_REPO}:${tag}"
    
    # Check if we're on macOS for platform specification
    if [[ "$OSTYPE" == "darwin"* ]]; then
        print_status "Detected macOS - building for linux/amd64 platform"
        if ! docker buildx build --platform linux/amd64 -t "${DOCKER_REPO}:${tag}" -t "${DOCKER_REPO}:latest" .; then
            print_error "Failed to build Docker image"
            exit 1
        fi
    else
        if ! docker build -t "${DOCKER_REPO}:${tag}" -t "${DOCKER_REPO}:latest" .; then
            print_error "Failed to build Docker image"
            exit 1
        fi
    fi
    
    print_success "Docker image built successfully: ${DOCKER_REPO}:${tag}"
}

# Push Docker image
push_image() {
    local tag=$1
    print_status "Pushing Docker image: ${DOCKER_REPO}:${tag}"
    
    if ! docker push "${DOCKER_REPO}:${tag}"; then
        print_error "Failed to push Docker image with tag: ${tag}"
        exit 1
    fi
    
    print_status "Pushing latest tag..."
    if ! docker push "${DOCKER_REPO}:latest"; then
        print_error "Failed to push Docker image with latest tag"
        exit 1
    fi
    
    print_success "Docker image pushed successfully: ${DOCKER_REPO}:${tag}"
}

# Main function
main() {
    print_status "Starting Docker build and push automation..."
    
    # Check if we're in the right directory
    if [ ! -f "main.go" ] || [ ! -f "Dockerfile" ]; then
        print_error "main.go or Dockerfile not found. Please run this script from the project root directory."
        exit 1
    fi
    
    # Parse command line arguments
    VERSION_TYPE="patch"
    CUSTOM_VERSION=""
    SKIP_VERSION_UPDATE=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --major)
                VERSION_TYPE="major"
                shift
                ;;
            --minor)
                VERSION_TYPE="minor"
                shift
                ;;
            --patch)
                VERSION_TYPE="patch"
                shift
                ;;
            --version)
                CUSTOM_VERSION="$2"
                shift 2
                ;;
            --skip-version-update)
                SKIP_VERSION_UPDATE=true
                shift
                ;;
            --help)
                echo "Usage: $0 [options]"
                echo "Options:"
                echo "  --major              Increment major version (x.0.0)"
                echo "  --minor              Increment minor version (x.y.0)"
                echo "  --patch              Increment patch version (x.y.z) [default]"
                echo "  --version VERSION    Use specific version (e.g., v1.2.3)"
                echo "  --skip-version-update Don't update version in main.go"
                echo "  --help               Show this help message"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Determine version to use
    if [ -n "$CUSTOM_VERSION" ]; then
        NEW_VERSION="$CUSTOM_VERSION"
        if [[ ! "$NEW_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            print_error "Invalid version format. Use format: v1.2.3"
            exit 1
        fi
    else
        CURRENT_VERSION=$(get_current_version_from_code)
        NEW_VERSION=$(get_next_version "$CURRENT_VERSION" "$VERSION_TYPE")
    fi
    
    print_status "Current version: $(get_current_version_from_code)"
    print_status "New version: $NEW_VERSION"
    
    # Update version in code if not skipped
    if [ "$SKIP_VERSION_UPDATE" = false ]; then
        update_version_in_code "$NEW_VERSION"
    fi
    
    # Run the build and push process
    check_docker
    docker_login
    build_image "$NEW_VERSION"
    push_image "$NEW_VERSION"
    
    print_success "Build and push completed successfully!"
    print_success "Image: ${DOCKER_REPO}:${NEW_VERSION}"
    print_success "Latest: ${DOCKER_REPO}:latest"
    
    echo
    print_status "You can now deploy this image using:"
    echo "docker run -p 8080:8080 ${DOCKER_REPO}:${NEW_VERSION}"
}

# Run main function with all arguments
main "$@"
