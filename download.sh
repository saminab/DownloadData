#!/bin/bash

# Base URL of the S3 bucket (without the fragment)
BASE_URL="https://noaa-nos-ofs-pds.s3.amazonaws.com/lmhofs/netcdf"

# List of years and months you want to download data for
YEARS=("2022")
#MONTHS=("01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12")
MONTHS=("09" "10")

# Folder to download all files into
DOWNLOAD_DIR="./2022"
mkdir -p "$DOWNLOAD_DIR"

# Function to check if a file exists at the given URL
check_file_exists() {
    local url=$1
    # Check if the file exists by using curl with --head option
    curl --head --silent --fail "$url" > /dev/null
}

# Function to download data for a specific year and month
download_files() {
    local year=$1
    local month=$2
    
    # Calculate the number of days in the month
    if [[ "$month" == "01" || "$month" == "03" || "$month" == "05" || "$month" == "07" || "$month" == "08" || "$month" == "10" || "$month" == "12" ]]; then
        days_in_month=31
    elif [[ "$month" == "04" || "$month" == "06" || "$month" == "09" || "$month" == "11" ]]; then
        days_in_month=30
    elif [[ "$month" == "02" ]]; then
        days_in_month=29 # Leap year (assuming 29 days for simplicity)
    fi
    
    # Loop through each day and each time step (00z, 06z, 12z, 18z)
    for day in $(seq -f "%02g" 1 $days_in_month); do
        for time in "00" "06" "12" "18"; do
            # Construct the URL for the .nc file
            file_url="${BASE_URL}/${year}${month}/nos.lmhofs.fields.n000.${year}${month}${day}.t${time}z.nc"
            echo "Checking URL: $file_url"
            
            # Check if the file exists
            check_file_exists "$file_url"
            if [ $? -eq 0 ]; then
                # Download the file if it exists
                echo "File found, downloading: $file_url"
                wget --no-check-certificate -P "$DOWNLOAD_DIR" "$file_url" -v
                if [ $? -eq 0 ]; then
                    echo "Successfully downloaded ${year}-${month}-${day} t${time}z fields n000."
                else
                    echo "Error downloading ${year}-${month}-${day} t${time}z fields n000."
                fi
            else
                # Skip missing file
                echo "File ${year}-${month}-${day} t${time}z fields n000 not found, skipping."
            fi
        done
    done
}

# Loop through each year and month
for year in "${YEARS[@]}"; do
    for month in "${MONTHS[@]}"; do
        echo "Downloading files for ${year}-${month}..."
        download_files "$year" "$month"
    done
done

echo "Download complete!"