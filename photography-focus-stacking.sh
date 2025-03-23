#!/bin/bash

# https://patdavid.net/2013/01/focus-stacking-macro-photos-enfuse/
# Create a focus stacked image by
# - align images
# - do focus stacking
# - export created TIFF
#
# Requires from Hugin 
# - 
#
# Scripy by Joram Ebinger

#####################################################################################

# Get name of first TIFF image
full_name=$(ls *.tif | head -1)
first_file_name="${full_name%%.*}"

# align images
if ls OUT* 1> /dev/null 2>&1; then
  echo "Aligned images already exist. Don't align them again. Continue."
  exit
else
  align_image_stack -m -a OUT *.tif
fi

#####################################################################################

# create unique file_name
get_unique_file_name () {
  counter=1
  
  # If the initial file already exists, increment counter
  if [[ -e "$output_name" ]]; then
    base_name=$(basename "$output_name" .tif)
    # Loop until a non-exsiting file name is found
    while [[ -e "$output_name" ]]; do
      # If the file exists, append a number to the filename
      output_name="../${base_name}-$counter.tif"
      counter=$((counter + 1))
    done
  fi
}

#####################################################################################
# focus stacking using different kinds of methods
# standard
output_name="../${first_file_name}-focus-stack.tif"
get_unique_file_name
enfuse --exposure-weight=0 --saturation-weight=0 --contrast-weight=1 --hard-mask --output=$output_name OUT*.tif

# different grayscale conversion
output_name="../${first_file_name}-focus-stack-different-grayscale-conversion.tif"
get_unique_file_name
enfuse --exposure-weight=0 --saturation-weight=0 --contrast-weight=1 --hard-mask --gray-projector=l-star --output=$output_name OUT*.tif

# increased contrast-window-size to reduce halos around high contrast edges
output_name="../${first_file_name}-focus-stack-increased-contrast-window.tif"
get_unique_file_name
enfuse --exposure-weight=0 --saturation-weight=0 --contrast-weight=1 --hard-mask --contrast-window-size=5 --output=$output_name OUT*.tif

# Laplacian Edge Detection (if details are smeared)
output_name="../${first_file_name}-focus-stack-laplacian-edge-detection.tif"
get_unique_file_name
enfuse --exposure-weight=0 --saturation-weight=0 --contrast-weight=1 --hard-mask --contrast-edge-scale=0.3 --output=$output_name OUT*.tif

#####################################################################################
