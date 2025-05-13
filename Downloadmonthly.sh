#!/bin/bash

# Base URL of the S3 bucket (fixed domain name)
BASE_URL="https://noaa-nos-ofs-pds.s3.amazonaws.com/lmhofs/netcdf"

# Year and month you want to download data for
YEAR="2025"
MONTH="01"

# Folder to download all files into (you can change the folder name as needed)
DOWNLOAD_DIR="./downloaded_data"
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
    
    # Calculate the number of days in the month (for January, 31 days)
    days_in_month=31

    # Loop through each day (01-31) and download the required files
    for day in $(seq -f "%02g" 1 $days_in_month); do
        # Construct the directory URL for the specific day
        day_url="${BASE_URL}/${year}/${month}/${day}"

        # Loop through each time step (00z, 06z, 12z, 18z)
        for time in "00z" "06z" "12z" "18z"; do
            # Loop through the n-values (n000, n001, n002, ..., n006)
            for n in $(seq -f "%03g" 0 6); do
                # Construct the URL for the .nc file with the correct filename pattern for fields
                file_url="${day_url}/lmhofs.t${time}.${year}${month}${day}.fields.n${n}.nc"
                echo "Checking URL: $file_url"
                
                # Check if the file exists
                check_file_exists "$file_url"
                if [ $? -eq 0 ]; then
                    # Download the file if it exists
                    echo "File found, downloading: $file_url"
                    wget --no-check-certificate -P "$DOWNLOAD_DIR" "$file_url" -v
                    if [ $? -eq 0 ]; then
                        echo "Successfully downloaded ${year}-${month}-${day} t${time} fields n${n}."
                    else
                        echo "Error downloading ${year}-${month}-${day} t${time} fields n${n}."
                    fi
                else
                    # Skip missing file
                    echo "File ${year}-${month}-${day} t${time} fields n${n} not found, skipping."
                fi
            done

            # Download the "stations.forecast.nc" and "stations.nowcast.nc" files for each day and time step
            for station_file in "stations.forecast.nc" "stations.nowcast.nc"; do
                station_url="${day_url}/lmhofs.t${time}.${year}${month}${day}.${station_file}"
                echo "Checking URL: $station_url"
                
                # Check if the file exists
                check_file_exists "$station_url"
                if [ $? -eq 0 ]; then
                    # Download the file if it exists
                    echo "File found, downloading: $station_url"
                    wget --no-check-certificate -P "$DOWNLOAD_DIR" "$station_url" -v
                    if [ $? -eq 0 ]; then
                        echo "Successfully downloaded ${year}-${month}-${day} t${time} ${station_file}."
                    else
                        echo "Error downloading ${year}-${month}-${day} t${time} ${station_file}."
                    fi
                else
                    # Skip missing file
                    echo "File ${year}-${month}-${day} t${time} ${station_file} not found, skipping."
                fi
            done
        done
    done
}

# Download files for January 2025
echo "Downloading files for ${YEAR}-${MONTH}..."
download_files "$YEAR" "$MONTH"

echo "Download complete!"
