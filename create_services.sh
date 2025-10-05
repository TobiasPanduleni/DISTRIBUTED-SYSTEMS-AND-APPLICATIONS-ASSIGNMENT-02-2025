#!/bin/bash

# Smart Ticketing System - Service Creation Script
# Creates all Ballerina services using 'bal new' command only

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Service names
SERVICES=("Admin_Service" "Notification_service" "Passenger_service" "Payment_service" "Ticketing_service" "Transport_service")

# Function to print colored output
print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if Ballerina is installed
check_ballerina() {
    if ! command -v bal &> /dev/null; then
        print_error "Ballerina is not installed or not in PATH"
        exit 1
    fi
    print_success "Ballerina is installed"
}

# Create services directory
create_services_dir() {
    if [ ! -d "services" ]; then
        mkdir -p services
        print_success "Created services directory"
    else
        print_warning "Services directory already exists"
    fi
    
    cd services
}

# Create individual services using bal new
create_services() {
    for service in "${SERVICES[@]}"; do
        print_status "Creating $service..."
        
        if [ -d "$service" ]; then
            print_warning "$service already exists, skipping..."
            continue
        fi
        
        # Create service using bal new
        bal new "$service"
        
        if [ $? -eq 0 ]; then
            print_success "Successfully created $service"
        else
            print_error "Failed to create $service"
        fi
    done
}

# Main execution
main() {
    print_status "Starting Smart Ticketing System service creation..."
    
    # Check prerequisites
    check_ballerina
    
    # Create services directory and navigate
    create_services_dir
    
    # Create services
    create_services
    
    print_success "All services created successfully!"
    print_status "Project structure created:"
    echo ""
    tree .
}

# Run main function
main