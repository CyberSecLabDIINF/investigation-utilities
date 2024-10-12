#!/bin/bash

# It needs to be run as root

# Example of usage:
# sudo su
# bash Automation/Scripts/script-preprocesado.sh -p (path to PCAPs folder) -d

# Function to show help
show_help() {
    echo "Usage: $0 [option...]"
    echo
    echo "   -h, --help             show help"
    echo "   -p, --path             path to the folder with the pcap files"
    echo "   -d, --dependencies     install python dependencies"
    #echo "   -l, --list             list the pcap files in the path"
    echo
    exit 1
}

# Function to show error
show_error() {
    echo "Error: $1"
    exit 1
}

# Activate the virtual environment
activate_virtual_environment() {
    echo "Activating the virtual environment"

    # Check if the folder is Thesis---ABVU
    while [[ $PWD != *Thesis---ABVU ]]; do
        cd ..
        echo $PWD
    done

    if [ ! -d "venv" ]; then
        show_error "Virtual environment directory not found"
    fi

    # It can be fixed by using "sudo su" before activating the venv
    #sudo su || show_error "Failed to switch to root user"
    source venv/bin/activate || show_error "Failed to activate virtual environment"
    
    if [ -n "$VIRTUAL_ENV" ]; then
        echo "Virtual environment activated: $VIRTUAL_ENV"
    else
        show_error "Failed to activate virtual environment"
    fi
}

# Function to install dependencies
install_dependencies() {
    echo "Installing python dependencies"
    apt install -y python3 || show_error "Failed to install python3"
    apt-get install -y python3-pip || show_error "Failed to install python3-pip"
    apt-get install -y python3-venv || show_error "Failed to install python3-venv"
    apt-get install -y python3-tk || show_error "Failed to install python3-tk"
    
    python3 -m venv venv || show_error "Failed to create virtual environment"
    
    if [ ! -d "venv" ]; then
        show_error "Virtual environment directory not found"
    fi
    
    activate_virtual_environment
    
    # If in the virtual environment, install the dependencies
    if [ -n "$VIRTUAL_ENV" ]; then
        echo "Installing dependencies"
        cd Automation || show_error "Failed to change directory"
        pip3 install -r requirements.txt || show_error "Failed to install dependencies"
    else
        show_error "Failed to activate virtual environment"
    fi
    
    deactivate
}

# Function to print the memory usage of the program
monitor_ram_usage() {
    local program_pid=$1
    while kill -0 $program_pid 2>/dev/null; do
        ps -p $program_pid -o %mem=,rss=,vsz=,comm=
        sleep 1
    done
}

# Definition of the action to do for each file
action() {
    file=$1
    echo "Processing $file"
    # Extract the name of the file
    name=$(basename $file $extension)
    # Execute the main script
    python3 main.py -p "$file" -ec -edc
    # Check if Automation/CSVs exists
    if [ ! -d Automation/CSVs ]; then
        mkdir Automation/CSVs
    fi
    # Once the file is processed, rename the file
    mv Downloads/connections.csv Automation/CSVs/"$name.csv"
    mv Downloads/details.csv Automation/CSVs/"details_$name.csv"
}

# Check the number of arguments
if [ $# -eq 0 ]; then
    show_error "No arguments supplied"
fi

# Default values
path=""
list_only=false
install_deps=false

# Parse the arguments
while getopts ":hp:dl" opt; do
    case ${opt} in
        h )
            show_help
            ;;
        p )
            path=$OPTARG
            ;;
        d )
            install_deps=true
            ;;
        l )
            list_only=true
            ;;
        \? )
            show_error "Invalid option: -$OPTARG"
            ;;
        : )
            show_error "Invalid option: -$OPTARG requires an argument"
            ;;
    esac
done

# Defining the extension of the files
extension=".pcap"

# Check if the path exists
if [ ! -d "$path" ]; then
    show_error "The path does not exist"
fi

# Check if the path is empty
if [ -z "$path" ]; then
    show_error "The path is empty"
fi

# Install dependencies if requested
if [ "$install_deps" = true ]; then
    install_dependencies
fi

# List files if requested
if [ "$list_only" = true ]; then
    echo "Listing the pcap files in the path"
    ls $path
fi

# Activate the virtual environment
activate_virtual_environment

which python3 || show_error "Python3 not found"

# Iterate over the files in the path
if [ "$list_only" = false ]; then
    echo "Iterating over the files in the path"
    for file in $path/*$extension; do
        echo "Processing $file"
        action $file &
        monitor_ram_usage $!
    done
fi

# Deactivate the virtual environment
echo "Deactivating the virtual environment"
deactivate

# Exit the script
echo "Done"
exit 0