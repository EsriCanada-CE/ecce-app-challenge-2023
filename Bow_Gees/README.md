# Canada’s Conservation Tracker by the Bow Gees

This repository hosts documentation and links to support the Bow Gees' web application created for the 2023 Esri Canada GIS Centres of Excellence App Challenge: **Canada’s Conservation Tracker**. 

Link to the application: https://www.arcgis.com/apps/dashboards/7309567cdbaa4611b737403349a199a2

## Introduction

The theme of the 2023 Esri Canada GIS Centres of Excellence App Challenge is Conservation and Protected Areas or Urban Ecology. These themes raise awareness about the destruction of natural landscapes and habitats. They also underscore the importance of nature outside the human environment and within our communities.

The United Nations Sustainable Development Goals 14 and 15 were created to promote the sustainable use and conservation of marine and terrestrial ecosystems (United Nations Department of Economic and Social Affairs, 2023). In support of these goals, the Government of Canada created national targets to conserve 25% of marine and terrestrial areas by 2025 (Employment and Social Development Canada, 2023a, 2023b). Team Bow Gees believes that empowering citizens to keep track of the contribution of the Government of Canada and various actors towards attaining these targets is of great importance.

Our app, Canada’s Conservation Tracker, provides information about protected and other conserved areas in Canada. Attributes pertain to geography, ownership, management, governance, level of protection, enlisted and delisted dates, and more. Overall, Canada’s Conservation Tracker provides this information in an easily accessible and understandable format to elicit discussions about the drivers of and contributors to conservation and protection of biodiversity in Canada.

## Mission Statement: Canada’s Conservation Tracker
The mission of Canada’s Conservation Tracker is to monitor Canada’s progress towards its 2025 conservation targets and allow users to investigate trends in conservation with respect to factors such as time, geography, and governance. Monitoring progress and investigating trends are essential tasks for decision-making and ensuring the goals are reached.

## Statement of Characteristics and App Functionality
Canada’s Conservation Tracker is an ArcGIS Dashboard which displays the Canadian Protected and Conserved Areas Database (CPCAD). The CPCAD, an open dataset maintained and released annually by Environment and Climate Change Canada, is the official source for the geography and attributes of Canada’s marine and terrestrial conserved areas. This is the most up-to-date database of the state of conservation in Canada up to and including December 2021 (Environment and Climate Change Canada, 2023).
Canada’s Conservation Tracker is centered on an interactive map which allows users to engage with the CPCAD. Clicking on a CPCAD polygon will open a pop-up containing its attributes. Field descriptions are available to the right of the map. The map also has functions to search by address or name, return to the original extent, toggle layer visibility, and change the basemap.
Complementary widgets surround the interactive map and display conservation metrics. To the left of the map are progress widgets – these show the proportion of Canada’s marine and terrestrial areas which are conserved. Importantly, they highlight that Canada is substantially behind its 2025 goals.
On the bottom and right of the dashboard are widgets that display conservation metrics in the form of charts and tables. These allow users to gain insights relative to conservation achievements per year since the late 1800s and the total area conserved by each governance type. Users are also shown important information about delisted areas: these areas were previously conserved, but lost their protective status between 2013–2021. Widgets show the total area delisted per year, governance type, and province or territory. Canada’s Conservation Tracker will be updated with the 2022 CPCAD, which is slated for release in late March 2023.

## Data Sources
### *Canadian Protected and Conserved Areas Database (CPCAD)*
The CPCAD contains the most up to date spatial and attribute data on marine and terrestrial protected areas and other effective area-based conservation measures in Canada. It is compiled and managed by Environment and Climate Change Canada, in collaboration with federal, provincial, and territorial jurisdictions. The geospatial data can be used with GIS software (Esri file geodatabase format: .gdb) or Google Earth™ (.kmz). It contains combined data from all Canadian jurisdictions. It is used by a wide range of organizations, including governments, ENGOs, academia, land managers, industry, and the public. We downloaded the Esri file geodatabase format of the CPCAD (Environment and Climate Change Canada, 2023).

## Methods and Tools
### *Data Cleaning*
ArcGIS Pro was used to add one new field to the CPCAD: Area (square kilometers). Then, the CPCAD was uploaded to a web map in ArcGIS Online. The display field names in the CPCAD were changed from abbreviations to full names (which were obtained from the 2021 CPCAD user manual).

### *App*
The web map with the cleaned CPCAD was used to create an ArcGIS Dashboard. We used ArcGIS Dashboard due to its strength in conveying information in an intuitive and interactive manner. The Dashboard was designed to include an interactive dynamic map and widgets which showcased relevant conservation metrics.

## References
Employment and Social Development Canada. (2023a). *Sustainable Development Goal 14: Life below water*. https://www.canada.ca/en/employment-social-development/programs/agenda-2030/life-below-water.html

Employment and Social Development Canada. (2023b). *Sustainable Development Goal 15: Life on land*. https://www.canada.ca/en/employment-social-development/programs/agenda-2030/life-on-land.html

Environment and Climate Change Canada. (2023). *Canadian Protected and Conserved Areas Database*. https://www.canada.ca/en/environment-climate-change/services/national-wildlife-areas/protected-conserved-areas-database.html

United Nations Department of Economic and Social Affairs. (2023). *Sustainable Development*. https://sdgs.un.org/goals
