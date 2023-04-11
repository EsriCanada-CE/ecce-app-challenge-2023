# Esri App Challenge 2023
## Centre of Geographic Sciences (COGS), Nova Scotia Community College (NSCC)
## Team: GeoCity Wizards
### Description: Submission for all ECCE App Challenge 2023 Material
### Contributors: François d'Entremont, Mohit Francis, Cindy Lu


# **App: CanadaConserves**

Hosted on ArcGIS Online:

- Experience Builder: [CanadaConserves](https://experience.arcgis.com/experience/87b5a9b72ac04505bf567b867f782b3a)


## Introduction

In Canada, populations of species at risk have declined by an average of 59 percent since 1970<sup>[1]</sup>. According to the Canadian Species Index, between 1970 and 2016, the population size of monitored mammal species decreased by 42 percent on average and fish species by 21 percent<sup>[2]</sup>.

To arrest further decline in biodiversity and habitat areas, decisive action is required from all stakeholders, from all levels of government, researchers, private enterprises, and the public. On 09 December 2022, at the 15th Conference of the Parties (COP15) to the United Nations Convention on Biological Diversity, the Government of Canada set the goal of conserving 25 percent of Canada’s land and water by 2025, and 30 percent by 2030 (colloquially referred to as the 30 by 30 Project)<sup>[3][4]</sup>.

To meet this ambitious target, novel approaches are required. But there is great debate on which approaches to take, and how to achieve the above goals <sup>[5][6][7]</sup>


## Mission Statement

CanadaConserves integrates existing ecoregions and key biodiversity areas (KBAs) in Canada, identifies and plots candidate protected areas or sites of KBAs, and seeks to assess whether these areas become newly created conservation areas.

This is tool is not for analysis. The goal of CanadaConserves is not to identify high-risk areas or candidate KBA sites. That is beyond the scope of this app, and there is a lot of time, money, and man-power poured into those efforts Not all of that data is publically accessible either.

Instead, this is a reporting, compliance, and awareness tool. This is a tool created for the sake of openness and transparency, which can be used by anyone for everyone, whether they work for the government, perform research on the field, own businesses, or are members of the public. The following questions are some of the questions we sought to answer with CanadaConserves:

- How well are all levels of government complying with the goals of the 30 by 30 Project?
- Will they achieve these goals?
- Where are existing protected areas?
- Where are current candidate sites?
- Where can more candidate sites be placed?
- If a new candidate site or area were to be created, how big should its area be?
- How will the creation of new protected areas contribute towards the progress of the project?
- How can the public holds its officials accountable?


## CanadaConserves

**Methods and Workflow**

Data from the Protected and Conserved Areas Database (CPCAD) were used to calculate examine the state of the ’30 by 30’ Project as of December 2021. 
Our key deliverable was to examine the current state of Protected and Conserved Areas (PCA) in each province and ecoregion. To ensure consistency of the calculations, the Albers Equal Area Conic projection was applied to all data. 

#### *Percent coverage by Province, Territory, and Marine area:*
•	Only PCAs categorized as terrestrial were considered when calculating percent coverage in each province and territory. The output of the summary statistics function with aggregated geometric areas and counts of PCAs for each province and territory was appended to the Province and Territories of Canada layer, and the percent coverage was then calculated using appropriate metrics. 

•	Marine PCA coverage was calculated using aggregated area of all PCAs categorized as marine and the area of the Canadian Marine Boundary polygon. 

#### *Percent coverage by Ecoregion:*
•	Offshore marine areas not captured in the ‘Terrestrial Ecoregions of Canada’ dataset were added as an unofficial category (Others-offshore marine). An overlay was performed to intersect the PCA and the updated Ecoregion layers, the aggregated area for each ecoregion was then summarized and joined with the Ecoregion layer to calculate the PCA percent coverage. 

#### *Potential Areas for Protection and Conservation:*
•	Key Biodiversity Areas and Important Bird Areas were included and referenced as potential sites. Note that some areas overlap with existing PCAs. 

•	In addition, a new polygon layer was created to host an inventory of potential areas for official protection and conservation designation. App users are encouraged to add and edit potential sites of significance to the inventory, or to view conservation efforts and seek collaboration opportunities around areas of interest.

#### *Other information:*
•	Sentinel-2 10m Land Use/Land Cover Change from 2018 to 2021 was added as reference to identify significant development from natural areas in the past.


**App Features:**

- Map of Current Status by Province
- Map of Current Status by Ecoregion
- Map of Current PCAs
- Add your own conservation areas


**How to use the App**

1. Clicking the layer icon in the interactive maps provides access to various conservation areas of study. 
2. Clicking on the basemap icon allows you to change the basemap.
3. Click on different ecoregions to learn about them
4. Click on Map Your Impact to add your own conservation areas and see how much of an impact it makes.
5. Click on Take Action to learn about how you can make a difference


**Data**

Data Layers

| Data Layer   | Data Source |
| ----------- | ----------- |
| Canadian Marine Boundary | [Flanders Marine Institute](https://www.marineregions.org/eezdetails.php?mrgid=8493) |
| Canadian Protected and Conserved Areas | [Canadian Wildlife Service](https://www.canada.ca/en/environment-climate-change/services/national-wildlife-areas/protected-conserved-areas-database.html) |
| Important Bird Areas | [Bird Studies Canada](http://www.ibacanada.org) |
| Key Biodiversity Areas | [Canada KBA](https://kbacanada.org/explore/map-viewer/) |
| Provinces and Territories of Canada     | [Esri Canada](https://www.arcgis.com/home/item.html?id=d3fef65386df4e63b02d6e23bb98a1ee), Natural Earth Vector       |
| Sentinel-2 Land Use/Land Cover Change from 2018 to 2021 | Impact Observatory, Microsoft, and [Esri](https://env1.arcgis.com/arcgis/rest/services/Sentinel_2_10m_Land_Cover_Change/ImageServer) |
| Terrestrial Ecoregions of Canada   | [Agriculture and Agri-Food Canada](https://open.canada.ca/data/en/dataset/ade80d26-61f5-439e-8966-73b352811fe6)  |

Additional Data

- Ecoregion Description from [Ecological Framework of Canada](http://www.ecozones.ca/), Environment Canada

## Video Presentation

All photos and videos in the first half of the video are free to use and were sourced from Pexels ([License](https://www.pexels.com/license/)).

All music used in the video is also free to use and was sourced from Pixabay ([License](https://pixabay.com/service/license/)).


[CanadaConservesVideo](https://nscc.sharepoint.com/:v:/r/sites/ECCEAppChallengeTeam/Shared%20Documents/General/videos/CanadaConserves.mp4?csf=1&web=1&e=FrtXcj)


## Documentation

[README.md](https://github.com/MohitFrancis/EsriAppChallenge2023/edit/main/README.md)



## Team Members
![Teamphoto](https://github.com/MohitFrancis/EsriAppChallenge2023/blob/main/images/team_collage_photo.png)
Left to right: François d'Entremont, Mohit Francis, Cindy Lu

**François d'Entremont:** Hi! I'm a geospatial data enthusiast, and my interests in math, programming, machine learning, spatial analysis, and chess led me to pursue a graduate certificate in Geospatial Data Analytics. One of the coolest projects I'm currently working on is classifying pottery shards from the Levant using machine learning models. It's a fascinating challenge that allows me to apply my spatial analysis and machine learning skills to real-world problems. As a curious and passionate learner, I'm always eager to take on new challenges and explore new opportunities in the exciting world of geospatial analysis. Whether it's using data to make informed decisions or developing innovative solutions to complex problems, I'm ready for whatever comes my way. 

When I'm not busy analyzing data, you'll likely find me watching hockey games, cheering for my favorite teams, and enjoying all the action on the ice!



**Mohit Francis:** Hello! My interests in human health, culture, and impacts (especially on the environment) led me to complete a Bachelor of Science in Human Biology and Evolutionary Anthropology, and a Certificate in Bioarchaeology from the University of Toronto. During my undergraduate studies, I learned of spatial analysis and the many methods of applying geographic information systems (GIS) technology. As someone who has always enjoyed analysing and working with big data, I wanted to learn more in the hopes of eventually working in a sector aligned with my interests. This led me to the Centre of Geographic Sciences (COGS), where I'm currently enrolled in the GIS graduate certificate program for the 2022-2023 academic year.

The themes of this year's ECCE App Challenge - Conservation and Protected Areas or Urban Ecology - dovetail perfectly with my interests. On the academic side, for my term-long project at COGS, I am researching coastal erosion on the North Shore of Nova Scotia caused by extreme weather events. On the personal side, one of my most memorable experiences was being part of the volunteer tree planting and stewardship program organised by the Parks, Forestry, and Recreation Department of the City of Toronto. Planting native tree species and removing invasive species is a common ecological management technique in urban areas, of course. Outside of my studies and work, I enjoy watching and playing football (*incorrectly* called 'soccer'), and I hope to see Arsenal lift the title (knock on wood!) this May! 



**Cindy Lu:** Hello! My GIS journey began with a curiosity for the world around me and a desire to understand how different factors interact and influence each other. While working at a conservation organization in beautiful British Columbia, I discovered the power of GIS to bridge knowledge gaps across time and space. With its versatility and compatibility with different types of data and industries, GIS quickly became a passion of mine. Currently, I am studying in the Geospatial Data Analytics program at COGS, building on my previous education with a Bachelor of Arts in Environment from McGill University. When I'm not glued to my computer screen, you can often find me exploring new hiking trails, checking out cozy local shops, or venturing off to far-off lands and waters. I hope our app will encourage you to learn a little more about the diversity of Canadian ecosystems and explore ways to protect and conserve the place we call home.






## Acknowledgments

We would like to acknowledge COGS faculty, Esri Canada Higher Education and Research staff, our family, and our friends for their advice, guidance, and support. Thank you all!


## References Cited

[1] Environment and Climate Change Canada (2023) Canadian Environmental Sustainability Indicators: Species at risk population trends. Consulted on February 27, 2023. Available at: www.canada.ca/en/environment-climate-change/services/environmental-indicators/species-risk-population-trends.html.

[2] Environment and Climate Change Canada (2019) Canadian Environmental Sustainability Indicators: Canadian species index. Consulted on February 27, 2023.
Available at: www.canada.ca/en/environment-climate-change/services/environmental-indicators/canadian-species-index.html.

[3] Sevunts, L. (2021, January 11). Canada calls on large nations to conserve 30% of their territory and waters. RCI | English. https://www.rcinet.ca/en/2020/09/28/canada-calls-on-large-nations-to-conserve-30-of-their-territory-and-waters/.

[4] Power, K. & Press Secretary, Office of the Minister of Environment and Climate Change. (2022, December 9). Government of Canada recognizing federal land and water to contribute to 30 by 30 nature conservation goals [Press release]. https://www.canada.ca/en/environment-climate-change/news/2022/12/government-of-canada-recognizing-federal-land-and-water-to-contribute-to-30-by-30-nature-conservation-goals.html.

[5] Buyting, S. & CBC Radio. (2021, January 15). Canada committed to protecting 30% of our territory by 2030. Which 30% should it be? CBC Radio - Quirks and Quarks. Retrieved February 27, 2023, from https://www.cbc.ca/radio/quirks/jan-16-snake-lasso-climbing-seeing-gravitational-waves-with-pulsars-soil-compaction-and-more-1.5873142/canada-committed-to-protecting-30-of-our-territory-by-2030-which-30-should-it-be-1.5873148.

[6] Mitchell, M. G., Schuster, R., Jacob, A. L., Hanna, D. E., Dallaire, C. O., Raudsepp-Hearne, C., ... & Chan, K. M. (2021). Identifying key ecosystem service providing areas to inform national-scale conservation planning. Environmental Research Letters, 16(1), 014038. https://iopscience.iop.org/article/10.1088/1748-9326/abc121/meta.

[7] Mitchell, M. (2021, April 20). How to meet the ambitious target of conserving 30 per cent of Earth by 2030 - Beyond. The Conversation. Retrieved February 27, 2023, from https://theconversation.com/how-to-meet-the-ambitious-target-of-conserving-30-per-cent-of-earth-by-2030-154987.