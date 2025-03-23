#!/bin/bash

# https://patdavid.net/2013/07/automatic-exposure-blending-with-enfuse/
# Create a HDR image by
# - align images
# - do HDR fusion
# - export created TIFF
#
# Requires from Hugin 
# - align_image_stack
# - enfuse
# 
# Script by Joram Ebinger


#####################################################################################

# Get name of first TIFF image
full_name=$(ls *.tif | head -1)
first_file_name="${full_name%%.*}"

# align images
if ls OUT* 1> /dev/null 2>&1; then
  echo "Aligned images already exist. Don't align them again. Continue."
else
  echo "Aligning images ..."
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
output_name="../${first_file_name}-hdr.tif"
get_unique_file_name
enfuse --output=$output_name OUT*.tif

# # save mask
# output_name="../${first_file_name}-hdr-mask.tif"
# get_unique_file_name
# enfuse --save-masks=%f-softmask.png OUT*.tif 


#####################################################################################
