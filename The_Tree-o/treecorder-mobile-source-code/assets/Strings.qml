import QtQuick 2.9

Item {
    id: root

    //NearbyMapPage
    readonly property string kClear: qsTr("CLEAR")
    readonly property string kBasemaps: qsTr("Basemaps")
    readonly property string kElevation: qsTr("Elevation")
    readonly property string kBookmarks: qsTr("Bookmarks")
    readonly property string kMapArea: qsTr("Offline Maps")
    readonly property string kMapDetails: qsTr("Map Details")
    readonly property string kLegend: qsTr("Legend")
    readonly property string kRefresh: qsTr("Refresh")
    readonly property string loading: qsTr("Loading...")
    readonly property string switching_layer: qsTr("Switching layer...")
    readonly property string tab_media: qsTr("Media")
    readonly property string tab_map: qsTr("Map")
    readonly property string tab_about: qsTr("About")
    readonly property string total: qsTr("Total")
    readonly property string no_features_available: qsTr("No features available.")
    readonly property string clear_search: qsTr("Clear Search")
    readonly property string identify_not_supported_on: qsTr("Identify not supported on:")
    readonly property string unsupported_item_type: qsTr("Unsupported Item Type")
    readonly property string cannot_open_item_of_type: qsTr("Cannot open item of type ")
    readonly property string layer_not_found: qsTr("Unable to find the layer with ID %1.")
    readonly property string object_not_found: qsTr("Unable to find the feature with ObjectID %1.")
    readonly property string app_not_found: qsTr("Unable to find the app.")
    readonly property string app_not_found_beforeSignIn: qsTr("Unable to find app. Please sign in.")
    readonly property string error: qsTr("Error")
    readonly property string search_notification_tooltip_on_start: qsTr("Find nearby points of interest by tapping on the map, address or place search, or using your current location.")
    readonly property string search_tooltip_on_search_by_extent: qsTr("Find nearby points of interest by searching this map area, address or place search, or using your current location.")

    readonly property string default_basemap: qsTr(" (Default) ")
    readonly property string no_nearby_found: qsTr("No results found. Tap on the map or search icon to lookup the nearby points of interest.")
    readonly property string no_results_found: qsTr("No results found.")
    readonly property string direction:qsTr("Directions")
    readonly property string open_in:qsTr("Open in")
    readonly property string search_this_area:qsTr("Search this area")
    readonly property string list:qsTr("List")
    readonly property string list_view:qsTr("List view")
    readonly property string search_time_out: qsTr("Unable to search at this moment, please try again later.")
    readonly property string search_extent:qsTr("Search results are calculated from the map center.")
    readonly property string appdescriptionText:qsTr(".")


    // SearchPage
    readonly property string count: qsTr("Count")

    //FilterPanel
    readonly property string filter:qsTr("Filters")
    readonly property string clear_filter:qsTr("Clear filters")
    readonly property string apply:qsTr("Apply")
    readonly property string reset:qsTr("Reset")
    readonly property string search_distance:qsTr("Search distance")
    readonly property string radius:qsTr("Radius")
    readonly property string distance:qsTr("Distance")
    readonly property string search_within:qsTr("Search within")
    readonly property string cancel:qsTr("Cancel")
    readonly property string alloperator: qsTr("Results will show ALL matching filters")
    readonly property string anyoperator: qsTr ("Results will show ANY matching filters")
    readonly property string start_date:qsTr("Start Date")
    readonly property string end_date:qsTr("End Date")
    readonly property string min: qsTr("Min:")
    readonly property string max: qsTr("Max:")

    // Calendar Dialog
    readonly property string cancel_string: qsTr("Cancel")
    readonly property string today_string: qsTr("Today")
    readonly property string ok_String: qsTr("Ok")
    readonly property string hrs: qsTr("hrs")

    //IdentifyPage
    readonly property string no_attributes: qsTr("There are no attributes configured.")
    readonly property string no_attachments: qsTr("No attachments.")
    readonly property string details: qsTr("Details")
     readonly property string elevation: qsTr("Elevation")
    readonly property string unknown: qsTr("Unknown")
    readonly property string size_unknown: qsTr("Size Unknown")
    readonly property string share: qsTr("Share")
    readonly property string attachment: qsTr("attachment")
    readonly property string open: qsTr("Open")
    readonly property string image_downloaded: qsTr("Image download completed")

    //RouteView
    readonly property string compute_directions:qsTr("Computing directions...")
    readonly property string fail_get_route: qsTr("Unable to initiate the routing service. Please check with your administrator.")

    //LayerSelectionPanel
    readonly property string select_a_layer: qsTr("Select a layer")

    //signin
    readonly property string not_signed_in: qsTr("Not Signed In")
    readonly property string clientID_missing_message:qsTr("Using AppStudio Desktop please upload the app to your ArcGIS organization and register the ArcGIS Client ID in the app Settings.")
    readonly property string clientID_missing:qsTr("Missing Client ID")
    readonly property string sign_in: qsTr("Sign In")
    readonly property string sign_out: qsTr("Sign Out")
    readonly property string no_nearbys_available:qsTr("No nearbys available")

    readonly property string loading_first_100:qsTr("Loading first hundred features in the current active layer.")
    readonly property string show_offline_message:qsTr("You're offline. Check your connection.")

    // NavigationShareSheet
    readonly property string in_app_directions: qsTr("In-app Directions")
    readonly property string google_maps: qsTr("Google Maps")
    readonly property string apple_maps: qsTr("Apple Maps")

    //units
    readonly property string km:qsTr("km")
    readonly property string mi:qsTr("mi")
    readonly property string m:qsTr("m")
    readonly property string ft:qsTr("ft")

    readonly property string meters:qsTr("Meters (m)")
    readonly property string miles:qsTr("Miles (mi)")
    readonly property string kilometers:qsTr("Kilometers (km)")
    readonly property string feet:qsTr("Feet (ft))")
    readonly property string yards:qsTr("Yards (yd)")

    //Geofence Menu
    readonly property string geofences:qsTr("Geofences")
    readonly property string geofencesMenu:qsTr("Geofences menu")
    readonly property string buffer:qsTr("Buffer")
    readonly property string bufferDistance:qsTr("Buffer Distance")
    readonly property string onEnter:qsTr("On Enter")
    readonly property string onExit:qsTr("On Exit")

    //Locator
    readonly property string locator_not_licensed:qsTr("ArcGIS runtime is not licensed to use the Street Map Extension")
    readonly property string locator_not_supported:qsTr("Locators created with the Create Address Locator tool are not supported")
    readonly property string locator_loading_error:qsTr("Error in loading locator")

    readonly property string hint_text:qsTr("Search for features")

    //CustomAuthenticationPage
    readonly property string sign_in_to_access_resource: qsTr("Please sign in to access this resource")


    readonly property string distance_units:qsTr("Distance (%1)")
    readonly property string elevation_units:qsTr("Elevation (%1)")
    readonly property string elevation_request_network_error:qsTr("Elevation request network error %L1.")
    readonly property string elevation_request_http_error: qsTr("Elevation request HTTP error %L1.")
    readonly property string elevation_request_json_error:qsTr("Elevation request JSON error.")
    readonly property string fetchdata_error:qsTr("Unable to fetch data from the elevation service.")
    readonly property string elevation_summary_request_network_error:qsTr("Elevation request network error %L1.")
    readonly property string elevation_summary_request_http_error: qsTr("Elevation request HTTP error %L1.")
    readonly property string elevation_summary_request_json_error :qsTr("Elevation summary service request JSON error.")
    readonly property string max_slope:qsTr("Max Slope")
    readonly property string min_slope:qsTr("Min Slope")
    readonly property string avg_slope:qsTr("Avg Slope")
    readonly property string max_elevation:qsTr("Max")
    readonly property string min_elevation:qsTr("Min")
    readonly property string gain:qsTr("Gain")
    readonly property string loss:qsTr("Loss")
    readonly property string trail_length:qsTr("Length")

    readonly property string location_outside_mapExtent:qsTr("Your current Location falls outside the map extent.")

    readonly property string zoom_current_location_search:qsTr("Zoom to current location and search")
    readonly property string zoom_current_location:qsTr("Zoom to current location")
    readonly property string on:qsTr("On")
    readonly property string off:qsTr("Off")
    readonly property string choose_options:qsTr("Choose one of the following options:")
}
