# ==============================================================================
# Title            : GreenAbilityExplorer Data Pre-Processing
#
# Current Author   : David Stephen-Tammuz
#
# Previous Author  : None
#
# Date             : April 2nd, 2023
#
# Contact Info     : dstephentammuz@gmail.com
#
# Purpose          : Create a feature layer to be used in the ESRI Canada App Challenge
#                      ------------------------------------------------------
#                    The processing detailed below combines the following attributes in
#                    a single feature class so they can be easily filtered in the 
#                    GreenAbilityExplorer Application:
#                           1. Municipality
#                           2. Impermeability Index
#                           3. Planting Potential
#                           4. Land Use Description
#                           5. Distance to Parks
#                     The app will be used by city planners to identify sites which are in
#                     need of greening, and those with the highest greening potential
#
# =============================================================================

"""
Generated by ArcGIS ModelBuilder on : 2023-04-02 19:07:31
"""
import arcpy

def Model1():  # Model 1

    # To allow overwriting outputs change overwriteOutput option to True.
    arcpy.env.overwriteOutput = False

###############################################################################
# Raw Datasets Used 
# - From Metro Vancouver Open Data Portal (MVODP) or Government of Canada (GOC)
###############################################################################

    # Permeability (MVODP) - contains the impermeability index, planting potential index and municipality
    Permeability = "Z:\\AppChallengeFinal\\vancouver.gdb\\vancouver.gdb\\Permeability"
    # Landuse2016 (MVODP) - contains landuse descriptions
    Landuse2016 = "Z:\\AppChallengeFinal\\vancouver.gdb\\vancouver.gdb\\Landuse2016"
    # Parkland (GOC) - polygons of parks and greenspace across British Columbia
    Parkland = "Z:\\AppChallengeFinal\\vancouver.gdb\\vancouver.gdb\\Parkland"
    # metrovan (MVODP) - Municipal Boundaries in Metro Vancouver
    metrovan = "Z:\\AppChallengeFinal\\vancouver.gdb\\vancouver.gdb\\metrovan"

###############################################################################
# Pairwise Intersect (Pairwise Intersect) (analysis)
###############################################################################

# Intersects the Permeability and Landuse datasets in order to integrate 
# landuse descriptions into the permeability dataset (our working dataset)

    Output_Feature_Class = "Z:\\AppChallengeFinal\\vancouver.gdb\\vancouver.gdb\\Permeability_PairwiseInterse"
    arcpy.analysis.PairwiseIntersect(in_features=[Permeability, Landuse2016], out_feature_class=Output_Feature_Class, join_attributes="ALL", cluster_tolerance="", output_type="INPUT")

###############################################################################
# Select (Select) (analysis)
###############################################################################

# Removes polygons which are not of use
# First - remove road polygons, as they have no greening potential based on the
# definitions provided in metadata
# Second - removes polygons with areas under 100 sqm (after intersecting the 
# permeability and landuse datasets, some very small polygons were created)  

    PermeabilityLU_Final = "Z:\\AppChallengeFinal\\vancouver.gdb\\vancouver.gdb\\PermeabilityLU_Final"
    arcpy.analysis.Select(in_features=Output_Feature_Class, out_feature_class=PermeabilityLU_Final, where_clause="description <> 'Road Right-of-Way' And Shape_Area >= 100.327234491352")

###############################################################################
# Clip (Clip) (analysis)
###############################################################################

# The Province-Wide parks data is clipped to the size of Metro Vancouver using
# Metro Vancouver Municipal Boundaries Polygons
    Output_Features_or_Dataset = "Z:\\AppChallengeFinal\\vancouver.gdb\\vancouver.gdb\\Parkland_Clip"
    arcpy.analysis.Clip(in_features=Parkland, clip_features=metrovan, out_feature_class=Output_Features_or_Dataset, cluster_tolerance="")

###############################################################################
# Near (Near) (analysis)
###############################################################################

# Each site in our working dataset (intersect of permeability and landuse) is 
# used as the input feature
# Clipped Parkland is used as the near feature
# This creates an attribute in each polygon of distance to parklands
    Updated_Input_Features = arcpy.analysis.Near(in_features=PermeabilityLU_Final, near_features=[Output_Features_or_Dataset], search_radius="", location="NO_LOCATION", angle="NO_ANGLE", method="PLANAR", field_names=[["NEAR_FID", "NEAR_FID"], ["NEAR_DIST", "NEAR_DIST"]])[0]

if __name__ == '__main__':
    # Global Environment settings
    with arcpy.EnvManager(outputCoordinateSystem="PROJCS["NAD_1983_2011_UTM_Zone_10N",GEOGCS["GCS_NAD_1983_2011",DATUM["D_NAD_1983_2011",SPHEROID["GRS_1980",6378137.0,298.257222101]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]],PROJECTION["Transverse_Mercator"],PARAMETER["False_Easting",500000.0],PARAMETER["False_Northing",0.0],PARAMETER["Central_Meridian",-123.0],PARAMETER["Scale_Factor",0.9996],PARAMETER["Latitude_Of_Origin",0.0],UNIT["Meter",1.0]]", outputZValue=0, scratchWorkspace=r"Z:\AppChallengeFinal\vancouver.gdb\vancouver.gdb", 
                          workspace=r"Z:\AppChallengeFinal\vancouver.gdb\vancouver.gdb"):
        Model1()