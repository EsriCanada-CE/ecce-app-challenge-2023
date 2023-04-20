## TReecorder: An all-in-one solution for managing your community's urban forest

Team: Gabriel Diniz, Paramvir Singh, Ben Woodward (the Tree-O)

### Mission Statement

Healthy urban forests are indispensable for improving a community’s livability, promoting the health of community members, and providing habitat for urban wildlife. Urban forests cool cities through shade and transpiration, combating the urban heat island effect and making cities more resilient to climate change. Further, being surrounded by trees is widely recognized as beneficial to one’s mental health, and neighbourhoods with large trees have a distinct charm.  A healthy urban forest also reduces noise pollution and improves air quality, tackling some of the negative effects of vehicles on our cities. Finally, urban trees provide important habitat for wildlife, especially bird life and pollinators, helping certain species coexist with our urban landscapes.

All of these ecosystem services that urban trees provide - combined with the Government of Canada’s commitment to plant two billion trees in the next 10 years - make it worthwhile for planners and arbourists to consider urban forests while planning communities. This makes it essential for community officials to have tools to help plan biodiverse, native, and climate-resilient urban forests, while engaging community members in this process.

This is where Tree-corder comes in. **TReecorder is a suite of web and mobile apps, community surveys, and GIS analysis workflows that help planners and arborists manage and plan their community’s urban forest, and help community members connect with it.** TReecorder mobile allows citizens to identify and learn about street trees near them, and submit damage reports and wildlife sightings associated with each tree. TReecorder web allows arbourists to view these damage reports and wildlife sightings, and planners to see a variety of layers displaying tree density, diversity, native vs. non-native species, and climate change resilience. The suite is supported by python scripts which allow local governments to quickly and seamlessly ingest their current street tree data into TReecorder.

### The TReecorder Suite

#### TReecorder Mobile

*Purpose*

TReecorder mobile allows members of the public to engage with their community's urban forest by viewing information about urban trees near them, and uploading damage reports or wildlife sightings related to a particular tree. The app currently displays the City of Waterloo's street tree dataset, but it is compatible with any municipal street tree dataset that has been put through our ingestion and analysis workflow. 

When you open the app, you will be presented with a map that you can use to navigate outdoors, or pan around on indoors. If you click on the map, the app will return all the trees within a certain radius (by default, 50 m) of your point. From there, you can click "Details" to view information such as tree species and diameter at breast height (DBH), and open articles from the Ontario Forest Atlas to read more about the species (for most native species). You can also click buttons that allow you to submit damage reports and wildlife sightings using Survey123 forms.

*Set-up*
1. Download the ArcGIS AppStudio Player and ArcGIS Survey123 apps from the App Store or Google Play
2. Make sure that TReecorder Mobile has been shared with you on ArcGIS Online
3. Open AppStudio player and TReecorder Mobile should be visible. Click on it to open TReecorder Mobile
4. If TReecorder Mobile is not visible, click on your profile (top left corner), click "Scan QR Code", and scan the QR code below.
5. Explore the City of Waterloo's urban forest :)

![TReecorder QR Code](TReecorder%20Mobile%20QR%20Code.png)

*Dev Diaries*

This app was created using the "Nearby" template in ArcGIS AppStudio, which in turn uses the "Nearby" template in ArcGIS Instant Apps. From this template, the QML source code was modified to add the functionality where users can fill out Survey123 forms for a specific tree. In addition to adding the new buttons that are not in the template, the OBJECTID of the tree that the user clicks on in the app is automatically brought into ArcGIS Survey123, allowing the user to seamlessly submit a report related to that tree and preventing the forms from being used outside of the app.

#### TReecorder Web

TReecorder Web allows planners to get a broader view of their community's urban forest and arbourists to respond to tree damage reports and view wildlife sightings. The app is divided into three pages: "Urban Forest Profile", "Damage Reports", and "Wildlife Reports".

*Urban Forest Profile*

This web map provides planners with a birds-eye view of their urban forest so they can work to make it more biodiverse, native, and resilient to climate change. Several layers are available for planners to view, including diversity index tesselations (including Species Richness, the Shannon-Wiener Index, and a combination layer), a tree density layer, a tees layer with popups, a native vs. non-native trees layer, and a tree species at risk layer.

*Damage Reports*

This dashboard displays damage reports that have been submitted by members of the public using TReecorder Mobile. Arbourists can read the reports, zoom to the tree that the report is associated with, and view pictures of the damage.

*Wildlife Reports*

Similar to *Damage Reports*, this page allows arbourists to view wildlife sightings, zoom to associated trees, and view pictures of the animal in question, if available.

#### Ingestion and Analysis Workflows

*TReecorder Tree Species Table*

The TReecorder Tree Species table contains over 260 native and non-native tree species, genera, and cultivars found in Southwestern Ontario's urban forests. This table was developed using tree data from the cities of Waterloo, Kitchener, and Cambridge. For each species, the table includes information on whether it is native to Ontario, whether it is coniferous, whether it is a species at risk, along with entries about that tree from the Ontario Tree Atlas and Trees of Canada.

The table serves two main purposes in the TReecorder suite. First, it is used by our data ingestion workflow to convert latin/botanical tree species names to species IDs, which can be read by TReecorder web and mobile. Second, it is used to display information about each tree species in TReecorder Mobile so that community members can learn about the tree species near them.

*ingest-trees.py*

This python script/notebook helps convert municipal tree datasets into a schema compatible with TReecorder web and mobile. Most importantly, it converts the latin/botanical names of trees to species IDs.

**Before running this script:** Ensure latin/botanical names are spelled correctly and that no additional text appears before or after the latin name

**After running this script:** Edit your attribute table so that the only attributes that remain are "Species ID" and "Diameter at Breast Height" (DBH) in centimeters.

*generate-biodiversity-tess.py*

This python script/notebook generates a hexagonal (or other shape) tesselation to the extent of your tree points, and calculates various biodiversity indices (specifically species richness and the Shannon-Wiener index) for each cell using your tree data. The script allows you to easily change your cell size and shape to generate the tesselation of your choosing.

Species Richness is the number of unique tree species in an area (in this case your cell). This metric does not take into account the number of individuals of each species.

The Shannon-Wiener index considers both the number of unique species as well as the number of individuals of each species. For example, the index would consider a forest with 1 birch and 9 maple trees less diverse than one with 5 birch trees and 5 maple trees.

**Before running this script:** Be sure that you have run *ingest-trees.py* on your tree dataset, as species diversity is calculated using your species IDs.

### Open Data Sources

Table 1. Street Tree Datasets
| Source | Data Provider |
|---|---|
|Street Tree Inventory|City of Waterloo|
|Tree Inventory|City of Kitchener| 
|Street Trees|City of Cambridge|

### ArcGIS Tools used in this project
 - ArcGIS Online
 - Arcade Expressions (including globals)
 - Experience Builder
 - Instant Apps
 - AppStudio ("Nearby" template + custom code)
 - Survey123
 - StoryMaps and StoryMap Collections
 - ArcGIS Pro
 - Python Notebooks

### References
 - Benefits of Street Trees: https://cases.open.ubc.ca/how-street-trees-can-save-our-cities/#:~:text=Street%20trees%20remove%20pollutants%20such,are%20ozone%20and%20particulate%20matter.
 - Shannon-Wiener Index: https://www.ableweb.org/biologylabs/wp-content/uploads/volumes/vol-27/22_Nolan.pdf
