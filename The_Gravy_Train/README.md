README.md
# Urban Forage (Built by The Gravy Train)
## Team members:
Jordan Lineker, Ganimul Singh, Delphis Lamarche
## View content
Urban Forage App: https://experience.arcgis.com/experience/da251a96256a4e958e764515c6ff1f89/page/Garden-and-Tree-Locator/
Story Maps: https://storymaps.arcgis.com/collections/a001169b8e2346bcba6e379c193f6afd
## Mission statement
In 2011, Vancouver City Council approved the Greenest City Action plan which outlines 10 goal areas to guide Vancouver towards becoming the greenest city in the world. The 7th goal for becoming a global leader in urban food systems was introduced with the target of increasing local food assets through community gardens. Community gardens play a vital role in strengthening our local food systems, as they provide access to fresh and local foods, increase community wellness and add green spaces to urban areas. Food systems are faced with widespread population growth and rapid urbanization, by bringing in community gardens we are ensuring underused urban areas are being utilized and increasing the resilience and sustainability of green spaces within Vancouver. 

As of 2020, the City of Vancouver has gone beyond their goal of having 3,340 food assets/plots, but what does that mean?  Urban Forage is designed for users to determine the locality of nearest community gardens and derive how many people a garden can feed within the local neighborhood. Community gardens are recognized for feeding their community but Urban Forage will help to visualize the pattern of where the gardens are able to feed the most and where more gardens are needed.


## Goals
The goal of Urban Forage is to help users find accessible local food in the Vancouver region. The app also provides insight on factors within each neighborhood that affects its ability to provide locally grown food. Showing nearby gardens and fruit trees can help increase community engagement and production of locally grown food. Users could also see which neighborhoods are not able to supply as much food, indicating regions that can benefit from more community gardens.

## App Features
The main features of the app are located on the top-right widgets, with two pages separating the simpler location-focused map to the thematic map. From right to left on the widget bar, there is a neighborhood zoom, garden and fruit tree filter, a nearby query, and the page menu.
* With zoom to neighborhood, users can select a bookmark to instantly zoom to the neighorhood of interest.
* In the filter widget, users can select fruits from a drop-down list. Tree points will then dissapear if they do not include the fruits listed. Users can also enter a number in the garden filter, which will show community gardens with the minimum number of plots.
* With the nearby query widget, users can select a point on the map and a buffer distance around the point. The app will show all community gardens within the search area and list them out for the user. Users can select a garden from the list that displays, which will focus onto the garden and flash its location.
* The last widget provides a menu, where users can switch to the thematic map page. The thematic map page contains the same features and additional layers and symbology.

In the thematic map, community gardens were symbolized with variable size based on the number of plots in the garden. This serves as an indicator of output. Neighborhoods were symbolized according to an estimated number of servings per person created by the community gardens (see below for calculations).
## Datasets
All datasets were acquired from the City of Vancouver's open data portal: 
* Community gardens and food trees. Last modified March 27, 2023). Imported as CSV, other file formats available
	* https://opendata.vancouver.ca/explore/dataset/community-gardens-and-food-trees/information/?sort=name&location=12,49.264,-123.11245

* Census local area profiles 2016. Last modified April 10, 2018. Imported as CSV
	* https://opendata.vancouver.ca/explore/dataset/census-local-area-profiles-2016/information/

* Local Area Boundary. Last modified March 8, 2019. Imported as shapefile. Other file formats available.
	* https://opendata.vancouver.ca/explore/dataset/local-area-boundary/information/?disjunctive.name

## Calculations
Vancouver census data (2016) was added to the local boundary vector layer through an attribute join on the neighbourhood names. 

Calculations estimating total plot size, output, and servings per person were generated based on the City of Vancouver's Urban Agriculture Garden Guide, as well as Cochran and Minaker's (2020) average estimate on output from community gardens.
* Cochran and Minaker (2020) found that average yield for community gardens of 3.15 lbs per square meter per growing season. They found this yield translates to 20.4 servings of produce (p.159).
* They also found that 13.76 ha of community garden land can serve annual the vegetable needs of 2900 people (p.159). This means one square meter can fully supplement the demand of 0.021 people.
* The City of Vancouver's urban agriculture guidelines suggests a  plot size of 2.2 square meters (Gočová, A, 2020, p.29). 

Calculating per plot yield:

	Plot yield: 2.2m^2 * 3.15 = 6.93 lbs/plot
	Plot servings: 2.2m^2 * 20.4 = 44.88 servings/plot 
	
	Total servings: plot servings * number of plots in a community garden

Neighborhood servings per person were created by summing the number of plots within each neighborhood, and dividing this total by the census regions' total population

	Servings per person: (sum(number of plots in neighborhood)*20.4)/Total population

 
## References

City of Vancouver. (2020). Greenest City: 2020 Action Plan. Retrieved Mar 28, 2023 from: https://vancouver.ca/files/cov/urban-agriculture-garden-guide.pdf

Cochran, S., & Minaker, L. (2020). The Value in Community Gardens: A Return on Investment Analysis. Canadian Food Studies / La Revue Canadienne Des études Sur l’alimentation, 7(1), 154–177. https://doi.org/10.15353/cfs-rcea.v7i1.332

Gočová, A (2020). Urban Agriculture Garden Guide: Manual for Starting and Designing Urban Agriculture Projects. Retrieved Mar 28, 2023 from: https://vancouver.ca/files/cov/urban-agriculture-garden-guide.pdf

Indiana University Southeast (2023). What is urban ecology? Retrieved April 1, 2023 from: https://www.ius.edu/field-station/what-is-urban-ecology.php 
## Image/Video Reference
Vancouver Landscape of City (Why Community Gardens? - Story Map): https://en.wikipedia.org/wiki/Vancouver#/media/File:Concord_Pacific_Master_Plan_Area.jpg 

Community Garden on Davie Street (Why Community Gardens? - Story Map): https://en.wikipedia.org/wiki/Vancouver_Community_Gardens#/media/File:2010_Davie_Street_community_garden_Vancouver_BC_Canada_5045979145.jpg 

Above Ground Plots (Why Community Gardens? - Story Map): https://en.wikipedia.org/wiki/Community_gardening#/media/File:DSC02001_Ausschnitt_Mobiler_Gemeinschaftsgarten_Palette-Bigbag.JPG 

Sprouts (Why Community Gardens? - Story Map): https://www.pexels.com/photo/green-leafed-plant-bokeh-photography-767240/ 

Hands in Dirt (Learn About the Urban Forage - Story Map): https://www.pexels.com/photo/crop-photo-of-person-planting-seedling-in-garden-soil-4207910/ 

Plots (Cover for Splash Page - App): https://www.pexels.com/photo/variety-of-green-plants-1105019/ 

Palm tree symbol (fruit trees layer): https://www.flaticon.com/free-icons/coconut-tree

Seamless Looped Canvas (Urban Forage - video): https://elements.envato.com/seamless-looped-canvas-background-MLVPASD; Envato Elements

Crop farmer man picking green pepper in garden bed (Urban Forage - video): https://elements.envato.com/crop-farmer-man-picking-green-pepper-in-garden-bed-PT6PKAP; Envato Elements

Lemon Balm and Mint Growing Abundant in a Garden Bed (Urban Forage - video): https://elements.envato.com/lemon-balm-and-mint-growing-abundant-in-a-garden-b-Z3K75Z9; Envato Elements

Green lettuce leaves growing on garden bed (Urban Forage - video): https://elements.envato.com/green-lettuce-leaves-growing-on-garden-bed-VWPXDTD; Envato Elements

Dolly Video of Straight Rows of Fresh Vegetable Sprouts Growing on Garden Bed at Small Farm: https://elements.envato.com/dolly-video-of-straight-rows-of-fresh-vegetable-sp-6BV7BTQ; Envato Elements

The Close View of Green Tiny Seedlings Are in the Potting Soil Set on the Table (Urban Forage - video): https://elements.envato.com/the-close-view-of-green-tiny-seedlings-are-in-the--MM52G8W; Envato Elements

Team member headshots taken by Zorawar Singh. instagram: https://instagram.com/zrwr.zx?igshid=YmMyMTA2M2Y= 

Music: Green Lovers, performed by Yung Neil. https://open.spotify.com/artist/6412VPkfZEz04S51zYe6kA; Music and Lyrics by Jordan Lineker
