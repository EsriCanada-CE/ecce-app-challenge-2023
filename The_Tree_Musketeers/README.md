App Goals and How To Use:

Goals of the Apps:

Greenspace and urban ecology are vital for the health of a city. Impermeable surfaces contribute to surface water pollution, flooding, and amplify the Urban Heat Island effect. To mitigate these effects, planners may decide to integrate more urban vegetation and permeable ground surfaces into future developments. Our main app, GreenAbilityExplorer, gives its users a streamlined method to identify sites within Metro Vancouver which are most in need of greening, and those which have the highest greening potential.

GreenSpaceFinder provides users with information about a greenspace of interest in the city of Vancouver. The app promotes public engagement with an embedded survey as users can give their input about greenspaces they visited and where they would like to see more greenspaces. The results may assist city planners with decision-making and implementation of new greenspaces.

This collaborative approach can foster a powerful partnership for urban centres to greatly improve their livability, sustainability, and resiliency. Improving greenspaces and increasing the overall permeable surface area will provide long-term measurable gains in strengthening urban ecosystems.

How To Use the Apps:

1. GreenAbilityExplorer:

Description

GreenAbilityExplorer allows city planners in Metro Vancouver to efficiently identify sites that have high planting potential for adding greenery or developing new greenspaces.

The user can filter sites by Municipality, Planting Potential Index, Impermeability Index, Land Use Type, and Distance Range from Existing Greenspace (see more information in the “Features” section below).  Dynamic Statistics are displayed to help the user refine their search. Note: When changing filter settings, press “enter” or click away from the input area in order to trigger zoom and render the newly selected features.

Once the desired features have been identified/displayed, the results can be exported as a GeoJSON, JSON or CSV file. This allows the user to store their results, or upload them to ArcGIS Pro for further analysis.

Features

Filters: (Note: Zoom occurs on filter change. If there is no zoom )

1. Municipality
- Anmore
- Belcarra
- Bowen Island
- Burnaby
- Coquitlam
- Delta
- Electoral Area A
- Langley City
- Langley Township
- Lions Bay
- Maple Ridge
- New Westminster
- North Vancouver City
- North Vancouver District
- Pitt Meadows
- Port Coquitlam
- Port Moody
- Richmond
- Surrey
- Tsawwassen
- Vancouver
- West Vancouver
- White Rock

2\. Environmental Characteristics

Choose a numeric value to filter:

-%Impermeable is at least {insert value between 0-100%}

-%Planting Potential is at least {insert value between 0-100%}

3\. Land Use

- Agriculture
- Cemetery
- Civic and Other Institutional
- Exhibition, Religious and Other Assembly
- Health and Education
- Hotels, Motels, Rooming Houses
- Industrial
- Lakes, Large Rivers and Other Water
- Mixed Residential (Low-rise Apartment) Commercial
- Office
- Parking
- Recreation, Open Space and Protected Natural Areas
- Residential - Low-rise Apartment
- Residential - Single Detached
- Residential - Townhouse
- Retail and Other Commercial
- Transit, Rail and Other Transportation
- Undeveloped and Unclassified

4\. Proximity to Existing Greenspaces

- Allows the user to specify a range of distances from an existing greenspace, eg. 0 & 100 (min and max values in meters).

Attribute Table:

- Lists all records that meet the filtered criteria as specified by the user inputs.
- Records include the following fields: Municipality, % Planting Potential, % Impermeable, Description (Land Use), and Area (Square Meters)
- The attribute table can be exported as a GeoJSON, JSON, or CSV file.

Dynamic Statistics Text:

The values produced displayed change based on filter criteria and map extent.

Values Displayed

Mean Planting Potential Index

Mean Impermeability Index

Buttons:

- Link to video tutorial for users
- Link to the Metro Vancouver “Regional Tree Canopy Cover and Impervious Surfaces” report
- Link to the Greenspace Survey results (connected to GreenSpaceFinder app)

Other Features:

- Basemap selection

2\. GreenSpaceFinder:

Description:

GreenSpaceFinder helps users navigate to greenspaces within Vancouver neighbourhoods and also provides additional information about a greenspace of interest. By selecting a greenspace, a pop-up is enabled and displays a table of fields including the name of the greenspace, Primary Use, and Additional Park Info. The user also has the option to provide input about a greenspace they visited and where they would like to see more greenspaces by submitting their answers in the Greenspace Survey (embedded as a widget within the GreenSpaceFinder app).

Features:

GreenSpaceFinder contains a variety of widgets:

- Directions: The user clicks inside the input box for the starting point. The user can then click on the map to gather the address of this starting point. Similarly, the user can click inside the next input box for the destination point. The user can click on the map to obtain an address for the desired greenspace location. A route is then calculated between the two points. Distance from the starting point to the destination point is given, as well as the time of arrival. The user can also specify their transportation type in the dropdown menu, as well as a departure time.
- Survey: The user can give feedback about the Greenspace they visited and identify areas in which they would like to see more greenspace. In our GreenAbilityExplorer app, a link to the results of the survey will be embedded on the interface, so that city planners can gain a sense of where the general public would like to see improvement of greenspace and/or where the community would like to see more greenspaces.
- Pop-ups: The pop-ups contain the name of the Greenspace, Primary Use, and Additional Park Info. The latter contains a hyperlink (View) which re-directs the user to the City of Vancouver website. This webpage shows additional information such as images, description, or recreational facilities found within the selected greenspace. The user can also click the Explore (Street View) hyperlink which re-directs them to Google Street Maps at the location of the selected greenspace.
