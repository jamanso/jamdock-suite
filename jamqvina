#!/bin/bash
# Author: José Antonio Manso García
# License: CC BY-NC 4.0
# This script is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License.
# It may not be used for commercial purposes without explicit permission from the author.
# More info: https://creativecommons.org/licenses/by-nc/4.0/

# Enter input parameters
echo "Enter the receptor file name (including .pdbqt extension):"
read receptor_file

echo "Enter the exhaustiveness value:"
read exhaustiveness

echo "Enter the maximum number of docking modes (num_modes):"
read num_modes

echo "Enter the energy range:"
read energy_range

echo "Enter the number of CPUs to use:"
read cpu

echo "Is the library an FDA library of compounds? (yes/no):"
read library_type

# Define directories and input files
WORKDIR="$(pwd)"

if [ "$library_type" == "yes" ]; then
    ligand_dir="$WORKDIR/fda_pdbqt_compounds"
else
    ligand_dir=$(find "$WORKDIR" -maxdepth 1 -type d -name "library_pdbqt_*" | head -n 1)
    if [ -z "$ligand_dir" ]; then
        echo "No custom library directory found. Please ensure the directory exists."
        exit 1
    fi
fi

config_file="$WORKDIR/grid.conf"
output_dir="$WORKDIR/docking_results"
mkdir -p "$output_dir"

# Count total ligands
total_ligands=$(find "$ligand_dir" -maxdepth 1 -name "*.pdbqt" -type f | wc -l)


# Initialize timer and counter
start_time=$(date +%s)
count=0

echo "Total compounds to process: $total_ligands"
echo "Starting docking..."

for ligand_file in "$ligand_dir"/*.pdbqt; do
    if [ -f "$ligand_file" ]; then
        ligand_name=$(basename "$ligand_file" .pdbqt)
        output_file="$output_dir/${ligand_name}_docking.pdbqt"

        qvina02 --config "$config_file" --receptor "$receptor_file" --ligand "$ligand_file" \
             --exhaustiveness "$exhaustiveness" --num_modes "$num_modes" \
             --energy_range "$energy_range" --cpu "$cpu" \
             --out "$output_file" > "$output_file.log" 2>&1

        ((count++))

        current_time=$(date +%s)
        elapsed=$((current_time - start_time))

        if [ "$elapsed" -gt 0 ]; then
            per_minute=$(echo "scale=2; $count / ($elapsed / 60)" | bc)
            per_hour=$(echo "scale=2; $per_minute * 60" | bc)
            per_day=$(echo "scale=2; $per_hour * 24" | bc)

            remaining=$((total_ligands - count))
            if (( $(echo "$per_minute > 0" | bc -l) )); then
                est_minutes_left=$(echo "scale=2; $remaining / $per_minute" | bc)
                est_seconds_left=$(echo "$est_minutes_left * 60" | bc)
                est_finish_epoch=$(echo "$current_time + $est_seconds_left" | bc | cut -d'.' -f1)
                est_finish_time=$(date -d "@$est_finish_epoch")
            else
                est_finish_time="calculating..."
            fi

            echo "Docking completed for $ligand_name ($count/$total_ligands)"
            echo "Rate: $per_minute comp/min | $per_hour comp/h | $per_day comp/day"
            echo "Estimated time remaining: ${est_minutes_left:-...} min"
            echo "Estimated finish time: $est_finish_time"
            echo "------------------------------------------------------"
        fi
    fi
done

echo "Docking process completed. Results saved in $output_dir"
