#!/bin/bash
# Author: José Antonio Manso García
# License: CC BY-NC 4.0
# This script is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License.
# It may not be used for commercial purposes without explicit permission from the author.
# More info: https://creativecommons.org/licenses/by-nc/4.0/

# Display the menu
echo "Select the option you want to execute:"
echo "1) Generate a library of FDA-approved compounds"
echo "2) Generate a custom library"
read -p "Enter the option number: " option

# Verify the selected option
case $option in
    1)
        
# Define working directories
WORKDIR="$(pwd)"
DOWNLOAD_DIR="$WORKDIR/downloads"
MERGED_DIR="$WORKDIR/fda_sdf_compounds"
PDBQT_READY_TO_DOCK_DIR="$WORKDIR/fda_pdbqt_compounds"
FAILED_LOG="$WORKDIR/failed_pages.log"
REMAINING_FAILED_LOG="$WORKDIR/remaining_failed.log"

# Create necessary directories
mkdir -p "$DOWNLOAD_DIR" "$MERGED_DIR" "$PDBQT_READY_TO_DOCK_DIR"

# Clear previous failed log
> "$FAILED_LOG"
echo "Download in progress. This will take a while, please wait..."

# Download all 32 pages of the FDA-approved compounds from the catalog available in ZINC database
for i in {1..32}; do
    PAGE_DIR="$DOWNLOAD_DIR/page$i"
    mkdir -p "$PAGE_DIR"
    wget "https://zinc.docking.org/catalogs/fda/substances.sdf?page=$i" -O "$PAGE_DIR/page$i.sdf" 2>/dev/null
    
    # Check if download failed
    if [[ $? -ne 0 ]]; then
        echo "Page $i failed to download! The program will attempt to fix this later and complete the library." | tee -a "$FAILED_LOG"
        rm -rf "$PAGE_DIR"  # Remove incomplete folder
    fi
done

# Report failed downloads (if any)
if [[ -s "$FAILED_LOG" ]]; then
    echo "Some pages failed to download. The program will attempt to re-download the missing pages and complete the library."
else
    echo "All pages downloaded successfully!"
fi

# Split sdf files and energy minimization
echo "Splitting compounds and energy minimization"

for dir in "$DOWNLOAD_DIR"/page*; do
    if [[ -d "$dir" ]]; then
        page_name=$(basename "$dir")
        sdf_file="$dir/$page_name.sdf"
        if [[ -f "$sdf_file" ]]; then
            echo "Processing $sdf_file"
            obabel -isdf "$sdf_file" -osdf -O "$dir/mol.sdf" -m --minimize -f1 2>/dev/null
            
            # Remove the original SDF file after processing
            rm "$sdf_file"
            echo "Removed original file: $sdf_file"
        else
            echo "Skipping $dir: No SDF file found ($sdf_file)"
        fi
    fi
done

# Merge and renumber the compounds
counter=1  
for page in "$DOWNLOAD_DIR"/page*/; do
    if [ -d "$page" ]; then  
        for file in "${page}"/*.sdf; do  
            if [ -f "$file" ]; then  
                mv "$file" "$MERGED_DIR/${counter}.sdf"  
                ((counter++))  
            fi  
        done  
    fi  
done  

echo "Merging complete: $((counter - 1)) files moved to $MERGED_DIR"

# Convert merged SDF files to PDBQT format
echo PDBQT conversion in progress...

for file in "$MERGED_DIR"/*.sdf; do
    if [ -f "$file" ]; then
        filename=$(basename "$file" .sdf)
        output_file="$PDBQT_READY_TO_DOCK_DIR/$filename.pdbqt"
        obabel -isdf "$file" -opdbqt -O "$output_file" --partialcharge gasteiger --minimize 2>/dev/null
    fi
done

echo "Conversion complete. PDBQT files saved in $PDBQT_READY_TO_DOCK_DIR"

# Final check: Verify the number of PDBQT files
NUM_PDBQT_FILES=$(ls "$PDBQT_READY_TO_DOCK_DIR"/*.pdbqt 2>/dev/null | wc -l)

if [[ $NUM_PDBQT_FILES -eq 3200 ]]; then
    echo "FDA-approved compounds library is ready to dock! ($NUM_PDBQT_FILES compounds prepared)"
else
    echo "Warning: Expected 3200 PDBQT files, but found $NUM_PDBQT_FILES."
fi

# Function to check if a page is already downloaded
is_page_downloaded() {
    local page_number=$1
    local PAGE_DIR="$DOWNLOAD_DIR/page$page_number"
    local SDF_FILE="$PAGE_DIR/page$page_number.sdf"
    
    [[ -f "$SDF_FILE" && -s "$SDF_FILE" ]]
}

# Function to download a single page
download_page() {
    local page_number=$1
    local PAGE_DIR="$DOWNLOAD_DIR/page$page_number"
    local SDF_FILE="$PAGE_DIR/page$page_number.sdf"

    if is_page_downloaded "$page_number"; then
        echo "Page $page_number is already downloaded. Skipping."
        return 0
    fi

    mkdir -p "$PAGE_DIR"
    wget "https://zinc.docking.org/catalogs/fda/substances.sdf?page=$page_number" -O "$SDF_FILE" 2>/dev/null

    if is_page_downloaded "$page_number"; then
        echo "Page $page_number downloaded successfully!"
        return 0
    else
        echo "Page $page_number failed to download! The program will attempt to fix this later and complete the library." | tee -a "$REMAINING_FAILED_LOG"
        rm -rf "$PAGE_DIR"
        return 1
    fi
}

# Loop until all failed pages are successfully downloaded
while true; do
    if [[ -s "$FAILED_LOG" ]]; then
        echo "Retrying failed downloads..."
        > "$REMAINING_FAILED_LOG"

        while read -r line; do
            page_number=$(echo "$line" | grep -oE '[0-9]+')

            if [[ -n "$page_number" ]]; then
                download_page "$page_number"
            fi
        done < "$FAILED_LOG"

        mv "$REMAINING_FAILED_LOG" "$FAILED_LOG"

        if [[ ! -s "$FAILED_LOG" ]]; then
            echo "All failed pages successfully downloaded!"
            rm "$FAILED_LOG"
            break
        fi

        echo "Waiting 10 seconds before next retry..."
        sleep 10
    else
        echo "No failed downloads to retry. Exiting."
        break
    fi
done

# Post-processing steps after successful download
echo "Starting energy minimization for downloaded files..."

for dir in "$DOWNLOAD_DIR"/page*; do
    if [[ -d "$dir" ]]; then
        page_name=$(basename "$dir")
        sdf_file="$dir/$page_name.sdf"

        if [[ -f "$sdf_file" ]]; then
            echo "Processing $sdf_file"
            obabel -isdf "$sdf_file" -osdf -O "$dir/mol.sdf" -m --minimize -f1 2>/dev/null

            rm "$sdf_file"
        fi
    fi
done

echo "Energy minimization complete!"

# Merge and append new files without overwriting
echo "Merging newly processed files into the main directory..."

	# Find the highest existing file number in MERGED_DIR
	if ls "$MERGED_DIR"/*.sdf &>/dev/null; then
    		max_number=$(ls "$MERGED_DIR"/*.sdf | grep -oE '[0-9]+' | sort -n | tail -1)
		else
    		max_number=0  # If no files exist, start from 0
	fi

counter=$((max_number + 1))  # Continue numbering from last file

for page in "$DOWNLOAD_DIR"/page*/; do
    if [[ -d "$page" ]]; then  
        for file in "$page"/*.sdf; do  
            if [[ -f "$file" ]]; then  
                mv "$file" "$MERGED_DIR/${counter}.sdf"  
                ((counter++))  
            fi  
        done  
    fi  
done  

echo "Merging complete: $((counter - 1 - max_number)) new files added. Total files: $((counter - 1))"

# Convert merged SDF files to PDBQT format
echo "Starting SDF to PDBQT conversion..."
for file in "$MERGED_DIR"/*.sdf; do
    if [[ -f "$file" ]]; then
        filename=$(basename "$file" .sdf)
        output_file="$PDBQT_READY_TO_DOCK_DIR/$filename.pdbqt"
        obabel -isdf "$file" -opdbqt -O "$output_file" --partialcharge gasteiger --minimize  2>/dev/null
    fi
done

echo "Conversion complete. PDBQT files saved in $PDBQT_READY_TO_DOCK_DIR"

# Verify the number of PDBQT files
NUM_PDBQT_FILES=$(ls "$PDBQT_READY_TO_DOCK_DIR"/*.pdbqt 2>/dev/null | wc -l)

if [[ $NUM_PDBQT_FILES -eq 3200 ]]; then
    echo "FDA Library is ready to dock! ($NUM_PDBQT_FILES compounds prepared)"
else
    echo "Warning: Expected 3200 PDBQT files, but found $NUM_PDBQT_FILES."
fi
        ;;
    2)
    
    echo "Running custom library script..."
# Define working directories
WORKDIR="$(pwd)"

# Function to request user input
show_menu() {
    echo "Enter the range of MW (e.g., 300 450 for MW 300 to 450):"
    read -r min_mw max_mw
    echo "Enter the range of LogP (e.g., -1 2 for LogP -1 to 2):"
    read -r min_logp max_logp
    echo "Enter the number of compounds for the library (total):"
    read -r num_compounds
}

# 121 groups (tranches) based on MW and LogP
declare -A tranche_mapping=(
    [AA]="200 250 -1"
    [BA]="250 300 -1"
    [CA]="300 325 -1"
    [DA]="325 350 -1"
    [EA]="350 375 -1"
    [FA]="375 400 -1"
    [GA]="400 425 -1"
    [HA]="425 450 -1"
    [IA]="450 500 -1"
    [JA]="500 550 -1"
    [KA]="550 9999 -1"
    [AB]="200 250 0"
    [BB]="250 300 0"
    [CB]="300 325 0"
    [DB]="325 350 0"
    [EB]="350 375 0"
    [FB]="375 400 0"
    [GB]="400 425 0"
    [HB]="425 450 0"
    [IB]="450 500 0"
    [JB]="500 550 0"
    [KB]="550 9999 0"
    [AC]="200 250 1"
    [BC]="250 300 1"
    [CC]="300 325 1"
    [DC]="325 350 1"
    [EC]="350 375 1"
    [FC]="375 400 1"
    [GC]="400 425 1"
    [HC]="425 450 1"
    [IC]="450 500 1"
    [JC]="500 550 1"
    [KC]="550 9999 1"
    [AD]="200 250 2"
    [BD]="250 300 2"
    [CD]="300 325 2"
    [DD]="325 350 2"
    [ED]="350 375 2"
    [FD]="375 400 2"
    [GD]="400 425 2"
    [HD]="425 450 2"
    [ID]="450 500 2"
    [JD]="500 550 2"
    [KD]="550 9999 2"
    [AE]="200 250 2.5"
    [BE]="250 300 2.5"
    [CE]="300 325 2.5"
    [DE]="325 350 2.5"
    [EE]="350 375 2.5"
    [FE]="375 400 2.5"
    [GE]="400 425 2.5"
    [HE]="425 450 2.5"
    [IE]="450 500 2.5"
    [JE]="500 550 2.5"
    [KE]="550 9999 2.5"
    [AF]="200 250 3"
    [BF]="250 300 3"
    [CF]="300 325 3"
    [DF]="325 350 3"
    [EF]="350 375 3"
    [FF]="375 400 3"
    [GF]="400 425 3"
    [HF]="425 450 3"
    [IF]="450 500 3"
    [JF]="500 550 3"
    [KF]="550 9999 3"
    [AG]="200 250 3.5"
    [BG]="250 300 3.5"
    [CG]="300 325 3.5"
    [DG]="325 350 3.5"
    [EG]="350 375 3.5"
    [FG]="375 400 3.5"
    [GG]="400 425 3.5"
    [HG]="425 450 3.5"
    [IG]="450 500 3.5"
    [JG]="500 550 3.5"
    [KG]="550 9999 3.5"
    [AH]="200 250 4"
    [BH]="250 300 4"
    [CH]="300 325 4"
    [DH]="325 350 4"
    [EH]="350 375 4"
    [FH]="375 400 4"
    [GH]="400 425 4"
    [HH]="425 450 4"
    [IH]="450 500 4"
    [JH]="500 550 4"
    [KH]="550 9999 4"
    [AI]="200 250 4.5"
    [BI]="250 300 4.5"
    [CI]="300 325 4.5"
    [DI]="325 350 4.5"
    [EI]="350 375 4.5"
    [FI]="375 400 4.5"
    [GI]="400 425 4.5"
    [HI]="425 450 4.5"
    [II]="450 500 4.5"
    [JI]="500 550 4.5"
    [KI]="550 9999 4.5"
    [AJ]="200 250 5"
    [BJ]="250 300 5"
    [CJ]="300 325 5"
    [DJ]="325 350 5"
    [EJ]="350 375 5"
    [FJ]="375 400 5"
    [GJ]="400 425 5"
    [HJ]="425 450 5"
    [IJ]="450 500 5"
    [JJ]="500 550 5"
    [KJ]="550 9999 5"
    [AK]="200 250 5+"
    [BK]="250 300 5+"
    [CK]="300 325 5+"
    [DK]="325 350 5+"
    [EK]="350 375 5+"
    [FK]="375 400 5+"
    [GK]="400 425 5+"
    [HK]="425 450 5+"
    [IK]="450 500 5+"
    [JK]="500 550 5+"
    [KK]="550 9999 5+"
)

# List of groups to download
groups=("AAML" "AAMM" "AAMN" "AAMO" "AAMP" "AARL" "AARM" "AARN" "AARO" "AARP"
        "ABML" "ABMM" "ABMN" "ABMO" "ABMP" "ABRL" "ABRM" "ABRN" "ABRO" "ABRP"
        "BAML" "BAMM" "BAMN" "BAMO" "BARL" "BARM" "BARN" "BARO" "BARP"
        "BBML" "BBMM" "BBMN" "BBMO" "BBMP" "BBRL" "BBRM" "BBRN" "BBRO" "BBRP"
        "CAML" "CAMM" "CAMN" "CAMO" "CAMP" "CARL" "CARM" "CARN" "CARO" "CARP"
        "CBML" "CBMM" "CBMN" "CBMO" "CBMP" "CBRL" "CBRM" "CBRN" "CBRO" "CBRP"
        "EAML" "EAMM" "EAMN" "EAMO" "EAMP" "EARL" "EARM" "EARN" "EARO" "EARP"
        "EBML" "EBMM" "EBMN" "EBMO" "EBMP" "EBRL" "EBRM" "EBRN" "EBRO" "EBRP")

# Function to select the tranches based on MW and LogP ranges
select_tranches() {
    tranches_to_download=()
    for tranche_code in "${!tranche_mapping[@]}"; do
        # Extract the MW and LogP range
        mw_range=(${tranche_mapping[$tranche_code]})
        min_tranche_mw=${mw_range[0]}
        max_tranche_mw=${mw_range[1]}
        tranche_logp_raw=${mw_range[2]}

        # If the value contains the '+' character (e.g., "5+"), this is converted to a numeric value (e.g., 5.1)
        if [[ $tranche_logp_raw == *"+" ]]; then
            tranche_logp=$(echo "$tranche_logp_raw" | sed 's/+//')
            tranche_logp=$(echo "$tranche_logp + 0.1" | bc)
        else
            tranche_logp=$tranche_logp_raw
        fi

        # Compare ranges using bc (expressions should return 1 for true)
        cmp_mw=$(echo "($min_mw <= $max_tranche_mw) && ($max_mw >= $min_tranche_mw)" | bc)
        cmp_logp=$(echo "($min_logp <= $tranche_logp) && ($max_logp >= $tranche_logp)" | bc)
        if [ "$cmp_mw" -eq 1 ] && [ "$cmp_logp" -eq 1 ]; then
            tranches_to_download+=("$tranche_code")
        fi
    done
}

# Main execution
show_menu
select_tranches

if [ ${#tranches_to_download[@]} -eq 0 ]; then
    echo "No valid tranches found for the selected MW and LogP range."
    exit 1
fi

echo "Download in progress... Please wait. This may take a few minutes or even hours"

# Initialize the list of files to extract
files_to_extract=()
for tranche in "${tranches_to_download[@]}"; do
    for group in "${groups[@]}"; do
        group_dir="$tranche/$group"
        mkdir -p "$group_dir"
        
        file_path="$group_dir/$tranche$group.xaa.sdf.gz"
        
        curl --fail --remote-time --create-dirs -o "$file_path" \
             "http://files.docking.org/3D/$tranche/$group/$tranche$group.xaa.sdf.gz" \
             --progress-bar 2>/dev/null

        # Only add file if it actually exists
        [[ -f "$file_path" ]] && files_to_extract+=("$file_path")
    done
done

echo "Download completed!"

# Back up original folders and extract .gz files
for tranche in "${tranches_to_download[@]}"; do
    for group in "${groups[@]}"; do
        folder="$tranche/$group"
        if [ -d "$folder" ]; then
            backup_folder="${folder}_backup"
            if [ ! -d "$backup_folder" ]; then
                echo "Creating backup: $backup_folder"
                cp -r "$folder" "$backup_folder"
            else
                echo "Backup already exists: $backup_folder (Skipping)"
            fi

            echo "Processing folder: $folder"
            find "$folder" -type f -name "*.gz" -exec gunzip {} \;
        else
            echo "Warning: Folder $folder does not exist!"
        fi
    done
done

# Process sdf files (energy minimization)
for tranche in "${tranches_to_download[@]}"; do
    for group in "${groups[@]}"; do
        folder="$tranche/$group"
        if [ -d "$folder" ]; then
            find "$folder" -type f -name "*.sdf" -exec sh -c '
                for file do
                    base=$(basename "$file" .sdf)
                    obabel -isdf "$file" -osdf -O "$file" -m --ff MMFF94 --steps 1500 2>/dev/null
                done
            ' sh {} +
        fi
    done
done

# Merge and rename a random selection of compounds and convert them to PDBQT
library_sdf_folder="library_sdf_${num_compounds}"
mkdir -p "$library_sdf_folder"
library_pdbqt_folder="library_pdbqt_${num_compounds}"
mkdir -p "$library_pdbqt_folder"

sdf_files=()
for tranche in "${tranches_to_download[@]}"; do
    for group in "${groups[@]}"; do
        folder="$tranche/$group"
        if [ -d "$folder" ]; then
            while IFS= read -r -d '' file; do
                sdf_files+=("$file")
            done < <(find "$folder" -type f -name "*.sdf" -print0)
        fi
    done
done

if [ ${#sdf_files[@]} -eq 0 ]; then
    echo "No SDF files found for selection."
    exit 1
fi

# Shuffle and select the required number of compounds
shuffled_files=($(printf "%s\n" "${sdf_files[@]}" | shuf | head -n "$num_compounds"))

counter=1

    echo "PDBQT conversion in progress..."
for file in "${shuffled_files[@]}"; do
    new_sdf_file="${library_sdf_folder}/${counter}.sdf"
    cp "$file" "$new_sdf_file"
    new_pdbqt_file="${library_pdbqt_folder}/${counter}.pdbqt"
    obabel -isdf "$new_sdf_file" -opdbqt -O "$new_pdbqt_file" --partialcharge gasteiger --minimize 2>/dev/null
    counter=$((counter + 1))
done

echo "Library created: $library_sdf_folder with ${#shuffled_files[@]} compounds."
echo "PDBQT conversion completed: $library_pdbqt_folder."

# Check if directory exists
directory=("$WORKDIR"/library_pdbqt_*)
if [[ ! -d "$directory" ]]; then
  echo "Directory $directory does not exist."
  exit 1
fi

# Cleaning: Find and remove invalid files
find "$directory" -type f \( -size +10000c -o -size 0c \) -exec rm {} \;

# Count the remaining valid .pdbqt files
final_count=$(find "$directory" -type f -name "*.pdbqt" | wc -l)

echo "After cleaning a library with $final_count compounds is ready to dock!"

        ;;
    *)
        echo "Invalid option. Exiting..."
        exit 1
        ;;
esac
