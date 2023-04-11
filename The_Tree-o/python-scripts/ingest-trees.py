"""
TReecorder Tree-Point Ingestion
Ben Woodward - 20230223 - For 2023 ECCE App Challenge
"""

#Import libraries and indicate workspace
import arcpy
from arcpy import env

#File path to the geodatabase containing your tree layers
env.workspace = r"C:\Users\bwman\OneDrive - University of Waterloo\ECCE\App Challenge 2023\Digestion\Digestion.gdb"



#Set the local parameters
#Tree points feature class name
inFeatures = "Cambridge_Trees"

#Latin name field in your tree points feature class
latinName = "BOTANICAL_"

#Table name of TReecorder species table (must be in same geodatabase as your tree points)
joinTable = "Tree_Species"

#Create a species ID field in your tree points feature class.
arcpy.management.AddField(inFeatures, "Species_ID", "Short")

#Change latin names to lowercase in your tree points feature class to improve matching.
expression = "!" + latinName + "!.replace(\"\'\",\"\").lower()"
arcpy.management.SelectLayerByAttribute(inFeatures, "CLEAR_SELECTION")
arcpy.management.CalculateField(inFeatures, latinName, expression)

#Assign species IDs based on latin name
fields = ["Latin_Name", "Species_ID"]
with arcpy.da.SearchCursor(joinTable, fields) as cursor:
    for row in cursor:
        if row[0] is not None:
            species_name = row[0].replace("\'","").lower()
            print(species_name)
            expression = latinName + " = \'" + species_name + "\'"
            arcpy.management.SelectLayerByAttribute(inFeatures, "NEW_SELECTION", expression)
            print(arcpy.management.GetCount(inFeatures))
            if int(str(arcpy.management.GetCount(inFeatures))) > 0:
                arcpy.management.CalculateField(inFeatures, "Species_ID", row[1])


#Select trees that weren't assigned a species ID
arcpy.management.SelectLayerByAttribute(inFeatures, "NEW_SELECTION", "SPECIES_ID IS NULL")
#Count number of trees that weren't assigned a species ID
print(str(arcpy.management.GetCount(inFeatures)) + ' trees were not assigned a species')
