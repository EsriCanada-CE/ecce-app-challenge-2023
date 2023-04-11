"""
ECCE App Challenge 2023: Normalized Euclidean Distance to Features Script

Created on: March 4th, 2023

Description: This script performs Euclidean Distance, Extract by Mask, and normalization on a list of input datasets.
The output rasters are saved to the specified output directory. This script was created for the 2023 ECCE App Challenge.

Requirements:
- arcpy 

Usage:
- Run the script in a Python environment with the required dependencies installed.
- Set the input parameters in the script (e.g. dataset_list, clip_fc, output_dir).
- Run the script.

Outputs:
- Euclidean distance raster files for each input dataset.
- Clipped raster files for each input dataset.
- Normalized raster files for each input dataset.
"""

import os
import arcpy

# Set the workspace
arcpy.env.workspace = "C:/ECCE/GeoTrio.gdb"
output_dir = "C:/ECCE/GeoTrio.gdb"

# Enable overwriting existing output files
arcpy.env.overwriteOutput = True


def euclidean_distance(fc, output_dir):
    """
    Performs Euclidean distance analysis on a feature class and saves the output raster
    in the specified output directory.

    Parameters:
    -----------
    fc : str
        The name of the input feature class to use for the distance analysis.
    output_dir : str
        The directory where the output raster will be saved.
    """

    print(f'Euclidean Distance analysis for {fc}')
    out_raster = arcpy.sa.EucDistance(fc)
    out_name = os.path.splitext(os.path.basename(fc))[0]
    out_raster.save(f"{output_dir}/D_{out_name}")


def clip_raster(raster, clip_fc, output_dir):
    """
    Clips a raster using Extract By Mask and a feature class. Saves the output raster
    in the specified output directory.

    Parameters:
    -----------
    raster : str
        The name of the input raster to be clipped.
    clip_fc : str
        The name of the feature class used to clip the input raster.
    output_dir : str
        The directory where output files will be saved.
    """

    print(f'Clipping raster {raster} using {clip_fc}')
    out_raster = arcpy.sa.ExtractByMask(raster, clip_fc)
    out_raster.save(f"{output_dir}/Clip_{os.path.splitext(os.path.basename(raster))[0]}")


def normalize_raster(raster, output_dir):
    """
    Normalizes a raster using max-min normalization and saves the output raster
    in the specified output directory.

    Parameters:
    -----------
    raster : str
        The input raster to be normalized.
    output_dir : str
        The output directory to save the normalized raster.
    """

    print(f'Normalizing raster {raster}')
    out_raster = (raster - raster.minimum) / (raster.maximum - raster.minimum)
    out_raster.save(f"{output_dir}/Norm_{os.path.splitext(os.path.basename(raster.name))[0]}")


def process_datasets(dataset_list, clip_fc, output_dir):
    """
    Performs Euclidean distance, Extract By Mask, and normalization on a list of input datasets.

    Parameters:
    -----------
    dataset_list : list
        A list of vector dataset names to process.
    clip_fc : str
        The name of the feature class used to clip the input datasets.
    output_dir : str
        The directory where output files will be saved.
    """

    for fc in dataset_list:
        fc_path = os.path.join(output_dir, f"{fc}.shp")
        euclidean_distance(fc_path, output_dir)
        clip_raster(f"{output_dir}/D_{fc.split('.')[0]}", clip_fc, output_dir)
        normalized_raster = arcpy.sa.Raster(f"{output_dir}/Clip_D_{fc.split('.')[0]}")
        normalize_raster(normalized_raster, output_dir)


if __name__ == '__main__':
    clip_fc = "CalgaryBoundary"  # Clipping feature
    distance_lst = ["ParkPathway", "MajorRoads", "Bikepaths", "TransitStops",
                    "StreetCenterline", "Natural_Areas", "ParkSites"]  # List of feature classes to perform analysis on

    process_datasets(distance_lst, clip_fc, output_dir)
