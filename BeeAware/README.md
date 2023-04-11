# BeeAware 


## Mission Statement 
Our mission is to support bees and other urban pollinators by empowering Toronto residents to get involved with private and public pollinator garden projects.

Bees and other pollinators like butterflies, moths, and beetles play crucial roles in urban ecology. Their activities support plant life and vegetation, which in turn provide aesthetic and economic value, temperature moderation, wildlife habitats, food production, and a wide variety of other benefits to cities (1). Toronto is home to over 400 species of pollinators (2), but, as is the case throughout the world, bees and other pollinators are in decline.1 While the causes of and solutions to this decline are complex, one way that Toronto residents can support local pollinator populations is by planting a pollinator garden with native plants that attract, feed, and shelter them. 


## Application Description 
BeeAware is an informational tool that assists Toronto residents with planting pollinator gardens.  It is designed to work in tandem with the planting standards of the PollinateTO grant program, which has provided funding for over 400 community projects since 2019 (3).

BeeAware draws upon open data from PollinateTO and the City of Toronto to guide the user in making the right choices for their pollinator garden, whether that includes planting their own garden, finding an existing garden to support, or applying to PollinateTO for funding for a new project. 

BeeAware collects and visualizes data and standards for pollinator gardens provided by PollinateTO. Users can explore the app through an easy-to-use, visually appealing interface. The path they take through the app depends upon their own interests in pollinator gardens. Users will come away from the app with enhanced knowledge of pollinator gardens and their features in Toronto, as well as downloadable maps and visualizations that can be used to support bees and other pollinators in the city.

### Widgets 
1. About 
2. Legend 
3. Layer
4. Measurement 
5. Near Me: 
6. Zoom Slider
7. Search 
8. My Location 
9. Attribute Table 
10. Print  
11. Share

### Legend and Layers
1. PollinateTO Approved Projects (turned on)
2. PollinateTO Approved Parks (turned on)
3. Street Trees (turned off)
4. Neighbourhood Improvement Areas (turned on)
5. Neighbourhoods (turned on)
6. Slope 1-158 (turned off)

### Layer Methodology

#### PollinateTO Pre-Approved Parks Layer
Data was acquired from the PollinateTO Pre-Approved Parks webmap as a KML file, then converted to an Excel file. Columns and rows were edited for integration with ArcGIS and for display in the app. Layer geometry was derived from the City of Toronto Open Data Portal Municipal Addresses file, which was used to match addresses given in the PollinateTO map to latitude and longitude. This was then turned to XY point data. There was one exception to this, where the geometry was derived from the coordinates given on the PollinateTO map. This has been marked in the layer attribute table. These coordinates were then used to map the data.

**Data sources:** 
* PollinateTO. (2022, Aug. 18) Pre-Approved Parks Map. https://www.google.com/maps/d/u/0/viewer?ll=43.71463497462529%2C-79.41875219697822&z=11&mid=1NsjB7wd2lmSmiU9pjTD_KAOH19Blk70.
* City of Toronto Open Data Portal. (2022). Address Points (Municipal)- Toronto One Address Repository (September 2022) [Data set]. Information and Technology. https://open.toronto.ca/dataset/address-points-municipal-toronto-one-address-repository/.

#### PollinateTO Approved Projects Layer
Data was acquired from the PollinateTO Approved Projects webmap as a KML file, then converted to an Excel file. Columns and rows were edited for integration with ArcGIS and for display in the app. Layer geometry was derived from the City of Toronto Open Data Portal Municipal Addresses file (marked as MunAdd in the CoordSource field), which was used to match addresses given in the PollinateTO map to latitude and longitude. This was then turned to XY point data. There was one exception to this, where the geometry was derived from the coordinates given on the PollinateTO map (PTO in the CoordSource field). In some instances, location addresses are for the organization named in the approved project and may not indicate the exact location of the project itself. These have been marked in the layer attribute table.

**Data Sources:**
* PollinateTO. (2022, Oct. 25). Approved Projects Map. https://www.google.com/maps/d/u/0/viewer?ll=43.711303656857005%2C-79.3838484&z=12&mid=1zh8YEhYLJWKtGFTdnNg0G7sKPW5njnc
* City of Toronto Open Data Portal. (2022). Address Points (Municipal)- Toronto One Address Repository (September 2022) [Data set]. Information and Technology. https://open.toronto.ca/dataset/address-points-municipal-toronto-one-address-repository/. 

#### Slope 2 Degrees and Under Layer
Data was acquired from Natural Resource Canada’s High Resolution DEM, York2019 dataset, which has a resolution of 1 meter. Tiles were mosaiced and clipped to the study area using the City of Toronto Open Data Portal Regional Municipal Boundary file. Resolution was resampled to 2 meters for better processing ability. The slope was calculated using the “Slope” tool, then areas 2 degrees or less (good slope) and areas over 2 degrees were calculated using the “Con” tool. Good slope was given a value of 1, bad slope was given a value of 0. The resulting raster was then converted to polygons using “Raster to Polygon” and areas with a value of 1 were selected and exported into a “good slope” layer. This layer was then clipped by groups of neighbourhoods (in order of appearance in the Neighbourhood file, see below) for use in ArcOnline.

**Data Sources:**
* Natural Resources Canada (NRCAN). (2019). High Resolution Digital Elevation Model (HRDEM)-York2019. [Dataset]. CanElevation Series. https://search.open.canada.ca/openmap/957782bf-847c-4644-a757-e383c0057995. 
* City of Toronto Open Data Portal. (2019). Regional Municipal Boundary (July 23, 2019) [Dataset]. Information and Technology. https://open.toronto.ca/dataset/regional-municipal-boundary/.
* City of Toronto Open Data Portal. (2022). Neighbourhoods (June 27, 2022) [Dataset]. Social Development, Finance and Administration. https://open.toronto.ca/dataset/neighbourhoods/. 

#### Street Tree Pollinators Layer
Data on trees known to the City of Toronto was acquired from the Open Data Portal “Street Trees” layer. Fields were edited for display in the app. Trees were selected according to their appearance in the PollinateTO list of suggested native trees (given a code of 1) or according to whether they were cultivars of those trees and/or were mentioned as pollinators in the Ontario Tree Atlas, a resource suggested by PollinateTO (given a code of 0). These selections were used to form their own feature layer.

**Data Sources:**
* City of Toronto. (4 Feb. 2023). Street Tree Data [Dataset]. https://open.toronto.ca/dataset/street-tree-data/
* Government of Ontario. (n.d.). Ontario Tree Atlas: South Central Region. Retrieved February 26, 2023 from: https://www.ontario.ca/page/tree-atlas/ontario-southcentral?id=7E-4
* PollinateTO. (n.d.). PollinateTO Grants: Native flowers, trees, and shrubs list. Retrieved February 26, 2023 from: https://www.toronto.ca/services-payments/water-environment/environmental-grants-incentives/pollinateto-community-grants/.

#### Neighbourhood Improvement Areas Layer
Data acquired from the City of Toronto Open Data Portal Neighbourhood Improvement Areas file. Fields were modified for simplified display in the app.

**Data Source:**
* City of Toronto Open Data Portal (2022). Neighbourhood Improvement Areas (December 19, 2022) [Dataset]. https://open.toronto.ca/dataset/neighbourhood-improvement-areas/.

#### Neighbourhoods Layer
Data acquired from the City of Toronto Open Data Portal Neighbourhoods file. Fields were modified for simplified display in the app.

**Data Source:**
* City of Toronto Open Data Portal. (2022). Neighbourhoods (June 27, 2022) [Dataset]. Social Development, Finance and Administration. https://open.toronto.ca/dataset/neighbourhoods/. 


## App Characteristics 

### Interested in getting involved with an existing community garden? 
* Use the Near Me tool to search for community gardens within a certain distance of your address. Activate the PollinateTO Approved Projects layer and click it to see a list of gardens and their distances from you.

### Interested in planting your own private pollinator garden? 
* Help decide on what pollinator plants you may need by activating the Street Tree Pollinator layer, searching for your address, and setting the distance to 2 miles (which is just above the average foraging distance for some bees) (4). The results will show the locations of native pollinator trees which are either recommended by PollinateTO (PTO code of 1) or other Ontario government sources (PTO code of 0). You can also use the Attribute Table to filter results for certain trees!

### Interested in applying to PollinateTO for funding for a new project? 
* This is where the app really shines! Depending on the type of project you want to propose, various layers can be combined in different ways. 

* PollinateTO prioritizes neighbourhoods designated as “neighbourhood improvement areas”. Use the Neighborhood Improvement Area layer to see if your proposed site falls into that category. 

* If you want to propose a garden on a city boulevard (the space between the sidewalk and the street), use the Slope layer to check if your boulevard will likely meet the PollinateTO standards of 2 degree slope or below. 

* Want to propose a pollinator garden for a city park? Use the Pre-Approved Parks layer to see which parks have been designated as potential pollinator garden sites and the Distance tool to check how far away your parks of choice are. 

* You can also use the Approved Projects layer to see if your project will fill a current lack of projects in your area, and the Pollinator Trees layer to see if existing trees can support your application. 

* Finally, your resulting maps of your proposed site and the features around it can be downloaded and submitted to PollinateTO in support of your application.


_Disclaimer: BeeAware is not affiliated with PollinateTO or the City of Toronto. Use of the app does not guarantee that your grant application will be accepted. Additional standards and conditions apply for applications, and it is the responsibility of the user to check and fulfil any and all requirements._


## References  
1. Government of Ontario. (2023, Jan. 10). Pollinator Health. https://www.ontario.ca/page/pollinator-health.
2. City of Toronto. (n.d.). Pollinator Protector Strategy. Retrieved February 25, 2023 from: https://www.toronto.ca/services-payments/water-environment/environmentally-friendly-city-initiatives/reports-plans-policies-research/draft-pollinator-strategy/
3. PollinateTO. (n.d.). PollinateTO Grants: Native flowers, trees, and shrubs list. Retrieved February 26, 2023 from: https://www.toronto.ca/services-payments/water-environment/environmental-grants-incentives/pollinateto-community-grants/.
4. Government of British Columbia, Ministry of Agriculture, Food, and Fisheries. (2020). Apiculture Factsheet. https://www2.gov.bc.ca/assets/gov/farming-natural-resources-and-industry/agriculture-and-seafood/animals-and-crops/animal-production/bees-assets/api_fs219.pdf.


Please be sure to also check out the resources compiled by the City of Toronto for more information on how to support native pollinators: https://www.toronto.ca/services-payments/water-environment/live-green-toronto/tips-to-create-a-pollinator-friendly-garden/


