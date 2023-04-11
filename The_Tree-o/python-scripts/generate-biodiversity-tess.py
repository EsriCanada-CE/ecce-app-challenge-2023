"""
Biodiversity Tesselation Generator
Ben Woodward - 20230223 - For 2023 ECCE App Challenge
"""

#Import libraries and indicate workspace
import arcpy
from arcpy import env

#File path to the geodatabase containing your tree layers
env.workspace = r"C:\Users\bwman\OneDrive - University of Waterloo\ECCE\App Challenge 2023\Digestion\Digestion.gdb"

#Set the local parameters
#Name of trees layer
inFeatures = "Waterloo_Trees"

#Generate tesselation based on extent of tree points layer and save to your workspace
size_sqkm = 3
size_sqkm_string = str(size_sqkm) + " SquareKilometers"
desc = arcpy.da.Describe(inFeatures)
extent = desc['extent']

tess = arcpy.management.GenerateTessellation("Tess", extent, "HEXAGON", size_sqkm_string)
arcpy.management.AddField("Tess", "Spec_Richness", "Short")
arcpy.management.AddField("Tess", "Shannon_Index", "Double")
arcpy.management.AddField("Tess", "Tree_Count", "Short")

#For each cell in the tesselation, calculate Species Richness and Shannon's diversity index
tempTess = "tempTess"
tempFeatures = "tempFeatures"
species_ids = []
with arcpy.da.SearchCursor(tess, 'OBJECTID') as cursor:
    for row in cursor:
        obj_id = str(row[0])
        expression = "OBJECTID = " + obj_id
        arcpy.conversion.ExportFeatures("Tess", tempTess, expression)
        arcpy.analysis.Clip(inFeatures, tempTess, tempFeatures)
        count = int(str(arcpy.management.GetCount(tempFeatures)))
        if count > 0:
            with arcpy.da.SearchCursor(tempFeatures, 'SPECIES_ID') as cursor2:
                for row in cursor2:
                    if row[0] is not None:
                        species_ids.append(row[0])

            species_ids.sort()
            shannon = 0
            unique_ids = []
            ind_count = 0
            richness = 0
            if len(species_ids) > 0:
                for species_id in species_ids:
                    if species_id not in unique_ids:
                        if ind_count > 0:
                            shannon += (ind_count/len(species_ids))*math.log(ind_count/len(species_ids))
                        unique_ids.append(species_id)
                        ind_count = 1
                        richness += 1
                    else:
                        ind_count += 1
                shannon += (ind_count/len(species_ids))*math.log(ind_count/len(species_ids))
                shannon = -shannon
#                 print(richness)
#                 print(shannon)
#                 print(count)
            arcpy.management.SelectLayerByAttribute("Tess", "NEW_SELECTION", expression)
            arcpy.management.CalculateField("Tess", "Spec_Richness", richness)
            arcpy.management.CalculateField("Tess", "Shannon_Index", shannon)
            arcpy.management.CalculateField("Tess", "Tree_Count", count)
            arcpy.management.SelectLayerByAttribute("Tess", "CLEAR_SELECTION")
        species_ids = []
