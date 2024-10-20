#!/bin/bash

# Uso individual: bash automation.sh -p (path to PCAPs folder) -d

# Function to show help
show_help() {
    echo "Usage: $0 [option...]"
    echo
    echo "   -h, --help             show help"
    echo "   -d, --dependencies     install dependencies"
    echo "   -p, --path             path to the folder with the pcap files"
    echo
    exit 1
}

# Function to show error messages
show_error() {
    echo "Error: $1"
    exit 1
}

# Function to activate virtual environment
activate_virtual_environment() {
    echo "Activating the virtual environment"
    # Check if the virtual environment directory is found
    if [ ! -d "venv" ]; then
        show_error "Virtual environment directory not found"
    fi
    # Activate the virtual environment
    source venv/bin/activate || show_error "Failed to activate virtual environment"
    # Check if the virtual environment is activated
    if [ -n "$VIRTUAL_ENV" ]; then
        echo "Virtual environment activated: $VIRTUAL_ENV"
    else
        show_error "Failed to activate virtual environment"
    fi
}

# Function to install dependencies
install_dependencies() {
    echo "Installing python dependencies"
    # Create a virtual environment
    python3 -m venv venv || show_error "Failed to create virtual environment"
    # Check if the virtual environment directory is found
    if [ ! -d "venv" ]; then
        show_error "Virtual environment directory not found"
    fi
    # Activate the virtual environment
    activate_virtual_environment
    # If in the virtual environment, install the dependencies
    if [ -n "$VIRTUAL_ENV" ]; then
        pip3 install -r requirements.txt || show_error "Failed to install dependencies"
    else
        show_error "Failed to activate virtual environment"
    fi
    # Deactivate the virtual environment
    deactivate
}

# Action to be performed on each file
action() {
    file=$1
    echo "Processing file: $file"
    # Extract the name of the file
    name=$(basename "$file" .pcap)
    # Run the Python script with the provided arguments
    python3 nfs-preprocesser.py -i "$file" -o "CSVs/$name.csv"
}

# -------------------------------------- SCRIPT --------------------------------------

# Check if the number of arguments is zero
if [ $# -eq 0 ]; then
    show_help
fi

# Default values
pcaps_folder="PCAPs"
install_deps=false
file_extension=".pcap"

# Parse the command line arguments
while getopts ":hdp:" opt; do
    case ${opt} in
        h )
            show_help
            ;;
        d )
            install_deps=true
            ;;
        p )
            pcaps_folder=$OPTARG
            ;;
        \? )
            show_help
            ;;
    esac
done

# Check if the dependencies need to be installed
if [ "$install_deps" = true ]; then
    install_dependencies
fi

# Check if the PCAPs folder exists
if [ ! -d "$pcaps_folder" ]; then
    show_error "PCAPs folder not found"
fi

# Activate the virtual environment
activate_virtual_environment

# Process each file in the PCAPs folder
for file in "$pcaps_folder"/*"$file_extension"; do
    action "$file"
done

# Deactivate the virtual environment
deactivate

# End of script
echo "Done"
exit 0