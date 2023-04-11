import QtQuick 2.7
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1

import ArcGIS.AppFramework.Platform 1.0

import Esri.ArcGISRuntime 100.14

import "../controls" as Controls

//Controls.PopupPage {
Item{
    id: searchPage

    property MapView mapView
    property string searchType:"bufferSearch"

    property string kUseMapExtent: qsTr("Use map extent")
    property string kWithinExtent: qsTr("Within Map Extent")
    property string kOutsideExtent: qsTr("Outside Map Extent")
    property alias tabBar:tabBar
    property bool isLoaded:false
    property var  searchResultTitleText:""
    //property alias searchMyPlacesView:searchPlacesView.searchPlaceView
    property var searchFieldNames:({})

    property var mapProperties:({})
    signal clearSearch()

    property var searchTabs: {
        let tabs = []
        if (locatorTask) tabs.push(app.tabNames.kPlaces)
        if (featureSearchProperties.searchConfigurationLoaded && featureSearchProperties.layerProperties.length > 0)
            tabs.push(app.tabNames.kFeatures)
        return tabs
    }

    property int transitionDuration: 200
    property real pageExtent: 0
    property real base: searchPage.height
    property string transitionProperty: "y"
    property string currentPlaceSearchText: ""
    property string currentFeatureSearchText: ""
    property alias sizeState: screenSizeState.name
    property bool hasLocationPermission: app.hasLocationPermission
    property bool screenWidth: app.isLandscape
    property bool willDockToBottom:false
    property var searchText:""
    property string activeTab:app.activeSearchTab.toUpperCase() === app.tabNames.kPlaces?app.tabNames.kPlaces:app.tabNames.kFeatures
    property string locatorError:""

    //property bool visible: false

    signal geocodeSearchCompleted ()
    signal featureSearchCompleted ()

    signal hideSearchPage()
    signal dockToBottom()
    signal dockToLeft()
    signal dockToTop()

    property var lyrNames:{
        var searchLayers = []
        return searchLayers
    }

    function makePlaceSearchTabActive()
    {
        mapView.identifyProperties.clearHighlight(function () {
            swipeView.currentView = searchPlacesView
            if (mapView.geocodeModel.count) {
                displayPlaceResultsCount(mapView.geocodeModel.count)
            }

            if (currentFeatureSearchText !== currentPlaceSearchText) {
                mapView.geocodeModel.clearAll()
                if(currentFeatureSearchText > "")
                    searchPlaces(currentFeatureSearchText)
            } else{
                mapView.geocodeModel.clearAll()
                if (currentPlaceSearchText)
                    searchPlaces(currentPlaceSearchText)
            }
        })
    }

    onClearSearch: {
        textField.properties.text = ""
    }

    onScreenWidthChanged: {
        if ( !app.isLandscape ){
            dockToTop()
        } else {
            willDockToBottom = false
            dockToLeft()
        }
    }

    onActiveTabChanged: {
        if(searchPage.searchTabs.length > 1)
        {
            if(activeTab.toUpperCase() === app.tabNames.kPlaces)
            {

                swipeView.currentIndex = 0
            }
            else
            {

                swipeView.currentIndex = 1
            }
        }
    }

    onFeatureSearchCompleted: {
        mapView.searchfeaturesModel.sortByStringAttribute("layerName")
        if (swipeView.currentItem.item.objectName === "searchFeaturesView") {
            var count = mapView.searchfeaturesModel.count
            displayFeatureResultsCount(count)
        }
    }


    onGeocodeSearchCompleted: {
        mapView.withinExtent.sortByNumberAttribute("numericalDistance", "desc")
        mapView.outsideExtent.sortByNumberAttribute("numericalDistance", "desc")
        mapView.geocodeModel.appendModelData(mapView.withinExtent)
        mapView.geocodeModel.appendModelData(mapView.outsideExtent)
        if (swipeView.currentItem.item.objectName === "searchPlacesView") {
            var count = mapView.geocodeModel.count
            displayPlaceResultsCount(count)
        }
    }


    Item {
        id: screenSizeState

        property string name: state

        states: [
            State {
                name: "LARGE"
                when: app.isLandscape

                PropertyChanges {
                    target: searchPage
                    pageExtent: height
                    height: parent.height
                    width:parent.width
                }
            },
            State {
                name: "SMALL"
                when: !app.isLandscape

                PropertyChanges {
                    target: searchPage
                    pageExtent: height
                    height: app.height
                    width:parent.width
                    y:0
                }
            }
        ]

    }

    height: app.height
    width:parent.width

    Controls.BasePage {
        anchors.fill: parent
        Material.background: "transparent"
        LayoutMirroring.enabled: app.isRightToLeft
        LayoutMirroring.childrenInherit: app.isRightToLeft

        header: ToolBar {
            id: searchBar

            property real tabBarHeight: 0.8 * app.headerHeight
            property real searchBoxHeight: app.headerHeight
            Material.background: app.primaryColor
            Material.foreground: app.subTitleTextColor
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            //height: searchBoxHeight + tabBarHeight + app.defaultMargin
            height: searchBoxHeight + tabBarHeight + app.defaultMargin + app.notchHeight
            topPadding: app.notchHeight


            LayoutMirroring.enabled: app.isRightToLeft
            LayoutMirroring.childrenInherit: app.isRightToLeft

            Rectangle {
                anchors {
                    fill: parent
                    margins: 0.5 * app.defaultMargin
                }
                radius: app.units(2)

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    Pane {
                        Material.background: "transparent"
                        Layout.preferredHeight: searchBar.tabBarHeight
                        Layout.preferredWidth: parent.width
                        Layout.topMargin: 0.5 * app.defaultMargin
                        leftPadding: app.defaultMargin
                        rightPadding: app.defaultMargin
                        topPadding: 0
                        bottomPadding: 0

                        TabBar {
                            id: tabBar
                            width: parent.width
                            height: searchBar.tabBarHeight
                            padding: 0

                            Repeater {
                                id: tabView

                                model: searchPage.searchTabs

                                delegate:TabButton {
                                    id: tabButton
                                    checked:modelData === activeTab.toUpperCase() ? true:false
                                    contentItem: Controls.BaseText {
                                        text: modelData
                                        color: tabButton.checked ? app.primaryColor : app.subTitleTextColor
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    padding: 0
                                    width: Math.max(app.units(64), tabBar.width/tabView.model.length)
                                    height: 0.8 * parent.height
                                    onClicked: {
                                        activeTab = modelData
                                    }

                                    Keys.onReleased: {
                                        if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape){
                                            event.accepted = true
                                            backButtonPressed ()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        spacing: 0
                        LayoutMirroring.enabled: app.isRightToLeft
                        LayoutMirroring.childrenInherit: app.isRightToLeft

                        Controls.Icon {
                            imageSource: "../images/back.png"
                            maskColor: app.subTitleTextColor
                            rotation: app.isRightToLeft ? 180 : 0

                            onClicked: {
                                app.activeSearchTab = activeTab
                                mapView.searchText = textField.properties.text
                                searchPage.close()
                            }
                        }

                        Controls.CustomTextField {
                            id: textField

                            Material.accent: app.baseTextColor
                            Material.foreground: app.subTitleTextColor
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            Layout.leftMargin: app.baseUnit
                            Layout.rightMargin: app.baseUnit
                            properties.placeholderText: qsTr("Search")
                            properties.focusReason: Qt.PopupFocusReason
                            properties.color: app.baseTextColor
                            properties.font.pointSize: app.baseFontSize
                            properties.text:searchText

                            onAccepted: {
                                mapView.searchText = textField.properties.text
                                searchPage.search(textField.properties.text)
                            }

                            onBackButtonPressed: {
                                app.backButtonPressed()
                            }

                            Connections {
                                target: textField.properties

                                function onDisplayTextChanged() {
                                    if(isLoaded){
                                        mapView.geocodeModel.clearAll()
                                        if (!textField.properties.displayText) {
                                            currentPlaceSearchText = ""
                                            mapView.searchfeaturesModel.clearAll()
                                            currentFeatureSearchText = ""
                                            swipeView.currentItem.item.reset()
                                            searchBusyIndicator.visible = false
                                        }

                                        if ( locatorTask && locatorTask.suggestions ) {
                                            locatorTask.suggestions.searchText = textField.properties.displayText
                                        }

                                        if ( locatorTask && locatorTask.loadError !== null){
                                            locatorError = locatorTask.loadError.message
                                            searchBusyIndicator.visible = false
                                        }
                                    }
                                }
                            }

                            onCloseButtonClicked: {
                                textField.properties.text = ""
                                mapView.searchText = textField.properties.text
                                searchResultTitleText = ""
                            }
                        }
                    }
                }
            }
        }

        contentItem: SwipeView {
            id: swipeView

            property QtObject currentView
            property QtObject itemModel
            property QtObject itemDelegate
            property string sectionProperty

            //currentIndex: tabBar.currentIndex
            interactive: false
            clip: true

            anchors {
                top: searchBar.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                bottomMargin: sizeState === "" ? app.heightOffset : 0
            }

            Repeater {
                model: tabView.model?tabView.model.length:null

                Loader {
                    id:searchPageLoader

                    sourceComponent: swipeView.currentView
                }
            }

            onCurrentIndexChanged: {
                let currenttab = activeTab.toUpperCase()
                if(tabView.model[currentIndex] !== currenttab)
                    currentIndex = currenttab === app.tabNames.kFeatures? 1:0
                switch (tabView.model[currentIndex]) {
                case app.tabNames.kFeatures:
                    mapView.hidePin(function () {
                        swipeView.currentView = searchFeaturesView
                        if(currentFeatureSearchText)
                            displayFeatureResultsCount (mapView.searchfeaturesModel.count)
                        if (currentFeatureSearchText !== currentPlaceSearchText) {
                            if(currentPlaceSearchText)
                                performFeatureSearch(currentPlaceSearchText)
                            else
                                performFeatureSearch(currentFeatureSearchText)
                        } else if (mapView.searchfeaturesModel.currentIndex >= 0) {
                            //swipeView.currentItem.item.searchResultSelected(mapView.searchfeaturesModel.features[mapView.searchfeaturesModel.currentIndex], mapView.searchfeaturesModel.currentIndex, false)
                        }
                    })
                    break
                case app.tabNames.kPlaces:
                    if(mapView){
                        makePlaceSearchTabActive()
                    }
                    break
                }
            }
        }
    }

    Component {
        id: searchPlacesView



        SearchPlacesView {
            id:searchPlaceView
            searching: searchBusyIndicator.visible
            listView.model: mapView.geocodeModel
            suggestionsModel: locatorTask ? locatorTask.suggestions : ListModel


            onSearchResultSelected: {
                searchBusyIndicator.visible = false
                mapView.selectedSearchDistanceMode = "bufferCenter"
                if(feature)
                {
                    if(mapProperties.isMapArea)
                    {
                        let homeExtent = mapView.map.initialViewpoint.extent
                        let isCurrentLocationInsideHomeExtent = GeometryEngine.contains(homeExtent, feature.displayLocation)
                        if(!isCurrentLocationInsideHomeExtent)
                        {
                            toastMessage.show(strings.location_outside_mapExtent)
                        }

                    }
                    else{


                        if (closeSearchPageOnSelection) {
                            searchPage.close()
                        }


                        if(searchType === "bufferSearch")
                        {
                            mapView.zoomToPoint(feature.displayLocation)
                        }
                        else
                        {
                            mapView.setViewpointCompleted.connect(mapView.doSearch)
                            mapView.zoomToPoint(feature.displayLocation,mapView.mapScale)
                        }

                        mapView.showPin(feature.displayLocation)

                        if(searchType === "bufferSearch")
                            mapView.findFeaturesInBuffer(feature.displayLocation, mapView.bufferDistance, mapView.measureUnits,mapView.layerSpatialSearch)


                    }
                }
            }


            onSearchSuggestionSelected: {
                textField.properties.text = suggestion
                searchPage.search(textField.properties.text)
            }
        }
    }

    Component {
        id: searchFeaturesView

        SearchFeaturesView {
            searching: searchBusyIndicator.visible
            listView.model: mapView.searchfeaturesModel
            defaultSearchViewTitleText: featureSearchProperties.hintText
            onSearchResultSelected: {
                searchBusyIndicator.visible = false
                mapView.selectedSearchDistanceMode = "bufferCenter"

                var extent = feature.geometry
                if (closeSearchPageOnSelection) {
                    searchPage.close()
                }

                // Find the center point for searching features
                let centerPoint;

                /* Determine type of search used (buffer vs extent)
                * Further, finds the centerPoint of Point, Polygon or Polyline to be used as center of buffer search
                * Zooms, shows the pin at the correct center point and finds the features around the point with the set buffer radius
                */
                if ( searchType === "bufferSearch" ){
                    if ( feature.geometry.objectType === "Polygon" || feature.geometry.objectType === "Polyline" ){
                        centerPoint = feature.geometry.extent.center;
                    } else if ( feature.geometry.objectType === "Point" ){
                        centerPoint = feature.geometry;
                    }

                    mapView.zoomToPoint(centerPoint);
                    mapView.showPin(centerPoint);
                    mapView.findFeaturesInBuffer(centerPoint, mapView.bufferDistance, mapView.measureUnits, mapView.layerSpatialSearch);
                } else{
                    if ( feature.geometry.objectType === "Polygon" || feature.geometry.objectType === "Polyline" )
                        centerPoint = feature.geometry.extent.center;
                    else{
                        centerPoint = feature.geometry;
                    }

                    mapView.setViewpointCompleted.connect(mapView.doSearch);
                    mapView.zoomToPoint(centerPoint,mapView.mapScale);
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            mapView.isIdentifyTool = false
            featureSearchProperties.hintText = featureSearchProperties.getHintText()
            if (mapView.searchfeaturesModel.features.length && tabView.model[tabBar.currentIndex] === app.tabNames.kFeatures) {
                swipeView.currentItem.item.searchResultSelected(mapView.searchfeaturesModel.features[mapView.searchfeaturesModel.currentIndex], mapView.searchfeaturesModel.currentIndex, false)
            } else if (mapView.geocodeModel.features.length && tabView.model[tabBar.currentIndex] === app.tabNames.kPlaces) {
                swipeView.currentItem.item.searchResultSelected(mapView.geocodeModel.features[mapView.geocodeModel.currentIndex], mapView.geocodeModel.currentIndex, false)
            } else {
                swipeView.currentView = searchPlacesView;
            }

            textField.focus = true
        } else {
            if (sizeState !== "") {
                if(!mapView.isIdentifyTool)
                {
                    mapView.identifyProperties.clearHighlight()
                }
            }
            searchBusyIndicator.visible = false
        }
    }

    QueryParameters {
        id: featureParameters
        maxFeatures: 10
    }

    GeocodeParameters {
        id: geocodeParameters

        maxResults: 25
        forStorage: false
        minScore: 90
        preferredSearchLocation: mapView ? mapView.center:null
        outputSpatialReference: mapView && mapView.map ? mapView.map.spatialReference : null
        outputLanguageCode: Qt.locale().name
        resultAttributeNames: ["Place_addr"]
    }

    Connections {
        target: locatorTask

        onGeocodeStatusChanged: {
            searchBusyIndicator.visible = true
            try{
                if (locatorTask.geocodeStatus === Enums.TaskStatusCompleted && mapView.map) {
                    if (locatorTask.geocodeResults.length > 0) {
                        var deviceLocation = CoordinateFormatter.fromLatitudeLongitude("%1 %2".arg(mapView.devicePositionSource.position.coordinate.latitude).arg(mapView.devicePositionSource.position.coordinate.longitude), mapView.spatialReference)
                        for (var i=0; i<locatorTask.geocodeResults.length; i++) {
                            if (locatorTask.geocodeResults[i].label > "") {
                                let distance = GeometryEngine.distance(deviceLocation, locatorTask.geocodeResults[i].displayLocation)
                                let distanceInMiles = (distance/1609.34) < 100 ?  parseFloat((distance/1609.34).toPrecision(3)).toLocaleString(Qt.locale()) : "100+"
                                let unitsinMiles = strings.mi
                                let distanceInMiles_str = `${distanceInMiles} ${unitsinMiles}`
                                let distanceInKm = (distance/1000.0) < 100 ?  parseFloat((distance/1000.0).toPrecision(3)).toLocaleString(Qt.locale()) : "100+"
                                let unitsinKm = strings.km
                                let distanceInKm_str = `${distanceInKm} ${unitsinKm}`
                                let distanceLabel = Qt.locale().measurementSystem === Locale.MetricSystem ? distanceInKm_str : distanceInMiles_str
                                let initialMapExtent = GeometryEngine.project(mapView.map.initialViewpoint.extent, mapView.map.spatialReference)
                                let resultExtent = GeometryEngine.contains(initialMapExtent, locatorTask.geocodeResults[i].displayLocation) ? kWithinExtent : kOutsideExtent
                                let linearUnit  = ArcGISRuntimeEnvironment.createObject("LinearUnit", {linearUnitId: Enums.LinearUnitIdMillimeters})
                                let angularUnit = ArcGISRuntimeEnvironment.createObject("AngularUnit", {angularUnitId: Enums.AngularUnitIdDegrees})
                                let geodeticInfo = GeometryEngine.distanceGeodetic(deviceLocation, locatorTask.geocodeResults[i].displayLocation, linearUnit, angularUnit, Enums.GeodeticCurveTypeGeodesic),
                                results = {
                                    "score": locatorTask.geocodeResults[i].score,
                                    "extent": locatorTask.geocodeResults[i].extent,
                                    "resultExtent": resultExtent,
                                    "place_label": locatorTask.geocodeResults[i].label,
                                    "place_addr": locatorTask.geocodeResults[i].attributes.Place_addr,
                                    "showInView": true,
                                    "initialIndex": i,
                                    "hasNavigationInfo": deviceLocation ? true : false,
                                    "numericalDistance": distance,
                                    "distance": distanceLabel,
                                    "degrees": geodeticInfo.azimuth1
                                }

                                mapView.geocodeModel.features.push(locatorTask.geocodeResults[i])

                                if (resultExtent === kWithinExtent) {
                                    withinExtent.append(results)
                                } else {
                                    outsideExtent.append(results)
                                }
                            }
                        }
                    }
                    geocodeSearchCompleted ()
                    searchBusyIndicator.visible = false
                }
                if (locatorTask.geocodeStatus === Enums.TaskStatusErrored)
                {
                    locatorError = locatorTask.loadError.message
                    geocodeSearchCompleted ()
                    searchBusyIndicator.visible = false

                }
            }
            catch(ex)
            {
                geocodeSearchCompleted ()
                searchBusyIndicator.visible = false
            }
        }
    }

    property alias textField: textField
    property LocatorTask locatorTask: app.isOnline ? onlineLocatorTask : null
    LocatorTask {
        id: onlineLocatorTask

        url: "https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer"

        suggestions.suggestParameters: SuggestParameters {
            maxResults: 10
            preferredSearchLocation: mapView?mapView.currentCenter():null
        }
    }

    QtObject {
        id: featureSearchProperties

        property bool searchConfigurationLoaded:false
        property var layerProperties: []
        property string hintText: qsTr("Search for features")
        property bool ready: {
            try {
                return (mapView.map.loadStatus === Enums.LoadStatusLoaded) && layerProperties.length && mapView.contentListModel.count > 0
            } catch (err) {
                return false
            }
        }

        onReadyChanged: {
            if (ready) {
                hintText = getHintText()
            }
        }

        function getHintText () {
            var hint = strings.hint_text
            if (searchConfigurationLoaded) {
                hint = ""

                for (var i=0; i<layerProperties.length; i++) {
                    var lyrinfo = layerProperties[i]

                    if(lyrinfo.placeholder > "")
                    {
                        hint += `${lyrinfo.placeholder} in ${lyrinfo.name}`

                        if (i !== layerProperties.length - 1  && layerProperties[i + 1].placeholder > "") {
                            hint += ", "
                        }
                    }
                }
            }

            if(hint > "")
                return hint
            else
                return strings.hint_text
        }

    }

    Connections {
        target: mapView ? mapView.map : null
        function onLoadStatusChanged() {
            if (mapView.map) {
                switch (mapView.map.loadStatus) {
                case Enums.LoadStatusLoaded:
                    try {
                        var appdataJson = viewerJsonDict[app.currentAppId]
                        var searchconfig = appdataJson.searchConfig

                        featureSearchProperties.layerProperties = mapView.map.json.applicationProperties.viewing.search.layers || []
                    } catch (err) {

                    }
                    break
                }
            }
        }
    }

    function updateFeatureSearchProperties(_searchconfigSources){
        try{
            let _appdataJson = viewerJsonDict[app.currentAppId]
            let k = 0

            _searchconfigSources.forEach(function(source){
                if (source.flayerId || source.layer){
                    k +=1

                    //supports featureSearch
                    var lyrProp = {}
                    lyrProp.name = source.name
                    lyrProp.id = source.flayerId || source.layer.id
                    lyrProp.searchFields = source.searchFields
                    lyrProp.exactMatch = source.exactMatch
                    lyrProp.maxResults = source.maxResults
                    lyrProp.outFields = source.outFields
                    lyrProp.displayField = source.displayField
                    lyrProp.popupTemplate = source.popupTemplate
                    lyrProp.placeholder = source.placeholder

                    if(source.popupTemplate !== null && source.popupTemplate !== undefined){
                        if( _appdataJson.draft && _appdataJson.draft.searchConfiguration && _appdataJson.draft.searchConfiguration.sources ){
                            var popupTemplate = _appdataJson.draft.searchConfiguration.sources[k-1].popupTemplate
                            lyrProp.popupTemplate = popupTemplate
                        }
                    }

                    if(source.layer){
                        lyrProp.url = source.layer.url
                    } else{
                        lyrProp.url = source.url
                    }
                    featureSearchProperties.layerProperties.push(lyrProp)
                }
            })
            featureSearchProperties.searchConfigurationLoaded = true
        }
        catch(ex){
            console.error("search not supported")
        }
    }

    BusyIndicator {
        id: searchBusyIndicator

        visible: false
        Material.primary: app.primaryColor
        Material.accent: app.accentColor
        width: app.iconSize
        height: app.iconSize
        anchors.centerIn: parent
    }

    function getLayerInfoById (id,subLayerId) {
        var layerList = mapView.contentListModel
        for (var i=0; i<layerList.count; i++) {
            var layer = layerList.get(i)
            if (!layer) continue
            if (layer.layerId === id) {
                if(layer.sublayerIds){
                    var lyrids = layer.sublayerIds.split(",")

                    var lyrNames = layer.sublayersTxt.split(",")
                    for(var p=0;p<lyrids.length;p++)
                    {
                        var lyrid = lyrids[p]
                        if(lyrid.toString() === subLayerId.toString())
                        {
                            var lyrname = lyrNames[p]
                            layer.name = lyrname
                        }
                    }
                }
                return layer
            }
        }
    }
    function close()
    {
        visible = false
        hideSearchPage()
    }

    function getLayerByName (name,url) {
        var layerList = mapView.map.operationalLayers
        for (var i=0; i<layerList.count; i++) {
            var layer = layerList.get(i)

            if (!layer) continue
            if (layer.name === name) {
                return layer
            }
        }
    }

   /* function getLayerById (id) {
        var layerList = mapView.map.operationalLayers
        for (var i=0; i<layerList.count; i++) {
            var layer = layerList.get(i)

            if (!layer) continue
            if (layer.layerId === id) {
                return layer
            }
        }
    }*/

    function searchPlaces (txt) {
        currentPlaceSearchText = txt
        geocodeParameters.preferredSearchLocation = mapView.currentCenter()
        locatorTask.geocodeWithParameters(txt, geocodeParameters)
    }

    QueryParameters {
        id: params
        // maxFeatures: 10  // setting this was causing not to return results for some webmaps
    }

    function searchFeaturesTileSubLayer_online (url,layername,lyrid,sublyr)
    {
        params.whereClause = ""
        for (var i=0; i<featureSearchProperties.layerProperties.length; i++) {
            var layerProperties = featureSearchProperties.layerProperties[i]
            var id = layerProperties.subLayer
            var searchFieldName = layerProperties.field.name
            var isExactMatch = layerProperties.field.exactMatch
            var fieldType = layerProperties.field.type
            if(lyrid.toString() === id.toString())
            {
                if(params.whereClause)
                    params.whereClause += " OR "

                if (isExactMatch) {
                    if(fieldType === "esriFieldTypeSmallInteger" || fieldType === "esriFieldTypeInteger" || fieldType === "esriFieldTypeDouble")
                    {
                        params.whereClause += "%1 = %2".arg(searchFieldName).arg(currentFeatureSearchText)
                    }
                    else
                        params.whereClause += "LOWER(%1) = LOWER('%2')".arg(searchFieldName).arg(currentFeatureSearchText)
                } else {
                    params.whereClause += "LOWER(%1) LIKE LOWER('%%2%')".arg(searchFieldName).arg(currentFeatureSearchText)
                }

                if(searchFieldNames[lyrid.toString()])
                {
                    var searchfields = searchFieldNames[lyrid.toString()]
                    if(!searchfields.includes(searchFieldName))
                        searchfields.push(searchFieldName)
                    searchFieldNames[lyrid.toString()] = searchfields
                }
                else
                {
                    var _searchfields = []
                    _searchfields.push(searchFieldName)
                    searchFieldNames[lyrid.toString()] = _searchfields
                }
            }
        }

        if(params.whereClause)
        {
            var urlstr = url.toString()

            var newurl = url + "/"+ lyrid.toString()
            var queryFeatureTable = ArcGISRuntimeEnvironment.createObject("ServiceFeatureTable", {url: newurl,featureRequestMode: Enums.FeatureRequestModeManualCache})

            var outFields= ["*"]
            queryFeatureTable.populateFromServiceStatusChanged.connect(function(){
                if(queryFeatureTable.populateFromServiceStatus === Enums.TaskStatusCompleted)
                {

                    while(queryFeatureTable.populateFromServiceResult.iterator.hasNext)
                    {
                        var feature = queryFeatureTable.populateFromServiceResult.iterator.next(),
                        attributeNames = feature.attributes.attributeNames
                        var searchlyrid = queryFeatureTable.serviceLayerId
                        var searchfldnames = searchFieldNames[searchlyrid]

                        var search_attr_val = ""
                        feature.attributes.attributeNames.forEach(fld =>
                                                                  {
                                                                      if(searchfldnames.includes(fld))
                                                                      {
                                                                          var val = feature.attributes.attributeValue(fld)
                                                                          var val_uppercase = val !== null?val.toString().toUpperCase():""
                                                                          var txt_search = currentFeatureSearchText.toString().toUpperCase()
                                                                          var n = val_uppercase.includes(txt_search);
                                                                          if(n)
                                                                          search_attr_val = fld.toString() + " : " + val.toString()
                                                                      }
                                                                  })
                        if(search_attr_val)
                        {
                            mapView.featuresModel.append({
                                                             "layerName": queryFeatureTable.displayName,
                                                             "search_attr": search_attr_val,
                                                             "extent": feature.geometry,
                                                             "showInView": false,
                                                             "initialIndex": mapView.featuresModel.features.length,
                                                             "hasNavigationInfo": false,
                                                             "distance":0
                                                         })
                            mapView.featuresModel.features.push(feature)
                        }

                    }
                    searchBusyIndicator.visible = false
                    featureSearchCompleted()
                }
                else if(queryFeatureTable.populateFromServiceStatus === Enums.TaskStatusErrored)
                {
                    if(queryFeatureTable.error)
                        console.error("error:", queryFeatureTable.error.message, queryFeatureTable.error.additionalMessage);
                }
            })
            queryFeatureTable.populateFromService(params,true,outFields)
        }
    }


    function processSearchTiledLayer(layer)
    {
        if(layer.mapServiceInfo)
        {
            var mapserviceInfo = layer.mapServiceInfo
            var url = mapserviceInfo.url
            var layerinfos = mapserviceInfo.layerInfos
            for(var q=0;q <layerinfos.length;q++)
            {
                if(layerinfos[q].parentLayerId > -1)
                {
                    searchFeaturesTileSubLayer_online (url,layerinfos[q].name,q)
                }
            }
        }
        else if (layer.subLayerContents && layer.subLayerContents.length > 0 && layer.subLayerContents[0] !== null)
        {
            for(var x=layer.subLayerContents.length;x--;){
                var sublyr = layer.subLayerContents[x]
                searchOnlineTiledGroupLayer(sublyr)
            }
        }
        else if(layer.mapServiceSublayerInfo)
        {
            var url1 = layer.mapServiceSublayerInfo.url.toString()
            searchFeaturesTileSubLayer_online (url1,layer.name,layer.id)
        }
    }


    function searchOnlineTiledGroupLayer(layer){
        if (layer.loadStatus !== Enums.LoadStatusLoaded)
        {
            layer.loadStatusChanged.connect(function(){
                if (layer.loadStatus === Enums.LoadStatusLoaded){
                    processSearchTiledLayer(layer)
                }

            })
            layer.load()
        }
        else
        {
            processSearchTiledLayer(layer)
        }
    }

    function searchOnlineMapImageGroupLayer(layer)
    {
        if(layer)
        {
            layer.loadTablesAndLayersStatusChanged.connect(function(){
                if (layer.loadTablesAndLayersStatus === Enums.TaskStatusCompleted)
                {

                    if(layer.subLayerContents)
                    {
                        for(var k=0;k<layer.subLayerContents.length;k++)
                        {
                            var sublayer = layer.subLayerContents[k]
                            if(sublayer.mapServiceSublayerInfo && sublayer.mapServiceSublayerInfo.parentLayerInfo)
                            {
                                //it is another sub group layer
                                searchOnlineMapImageGroupLayer(sublayer)
                            }
                            else
                            {
                                var layerServiceTable = layer.subLayerContents[k].table
                                searchFeatureLayer(layerServiceTable,layer.subLayerContents[k].name,layer.subLayerContents[k].id,currentFeatureSearchText)
                            }
                        }
                    }
                    layer = null
                }
            })
            layer.loadTablesAndLayers()
        }
    }


    function searchFeatures (txt) {
        currentFeatureSearchText = txt
        var layeridsSearched = []

        searchBusyIndicator.visible = true
        mapView.searchfeaturesModel.clearAll()

        for (var i=0; i<featureSearchProperties.layerProperties.length; i++) {
            var layerProperties = featureSearchProperties.layerProperties[i]
            if(layerProperties.subLayer > -1)
            {
                var id = layerProperties.id
                var searchFieldName = layerProperties.field.name
                var isExactMatch = layerProperties.field.exactMatch
                if(!layeridsSearched.includes(id))
                {
                    var layer = layerManager.getLayerById(id)
                    layeridsSearched.push(id)

                    if (layer.loadStatus === Enums.LoadStatusLoaded)
                    {
                        if(layer.objectType === "ArcGISTiledLayer")
                        {
                            searchOnlineTiledGroupLayer(layer)
                        }
                        else if (layer.objectType === "ArcGISMapImageLayer")
                        {
                            searchOnlineMapImageGroupLayer(layer)
                        }
                    }
                }
            }
            else
            {
                var id1 = layerProperties.id
                var layer1 = layerManager.getLayerById(id1)
                var layerServiceTable = layer1.featureTable
                //var lyrid = layer1.layerId
                if(layerServiceTable  && !layeridsSearched.includes(id1))
                {
                    layeridsSearched.push(id1)
                    searchFeatureLayer(layerServiceTable,layer1.name,id1,txt)
                }
            }
        }
    }

    function searchFeatureLayer(layerServiceTable,layername,lyrid,txt)
    {
        params.whereClause = ""
        for (var i=0; i<featureSearchProperties.layerProperties.length; i++) {
            var layerProperties = featureSearchProperties.layerProperties[i]
            var id = layerProperties.id
            var displayField = layerProperties.displayField

            if(lyrid === id)
            {
                var isExactMatch = layerProperties.exactMatch

                //get the fields
                layerProperties.searchFields.forEach(function(fld){
                    var searchFieldName = fld
                    if(layerServiceTable)
                    {
                        var fldObj = layerServiceTable.field(fld)
                        var fieldType = fldObj.fieldType
                        let searchTextValue = mapViewerCore.getCodeIfDomain(layerServiceTable.fields,fld,currentFeatureSearchText)

                        if(params.whereClause)
                            params.whereClause += " OR "
                        if (isExactMatch) {
                            if(fieldType === Enums.FieldTypeInt32 || fieldType === Enums.FieldTypeInt16 || fieldType === Enums.FieldTypeFloat32 || fieldType === Enums.FieldTypeFloat64)
                            {
                                params.whereClause += "%1 = %2".arg(searchFieldName).arg(searchTextValue)
                            }
                            else
                            {
                                params.whereClause += "LOWER(%1) = LOWER('%2')".arg(searchFieldName).arg(searchTextValue)
                            }
                        } else {
                            params.whereClause += "LOWER(%1) LIKE LOWER('%%2%')".arg(searchFieldName).arg(searchTextValue)
                        }
                    }
                })

                if((layerServiceTable.layer && layerServiceTable.layer.name))
                {
                    var lrname = layerServiceTable.layer.name

                    if(searchFieldNames[lrname])
                    {
                        var searchfields = searchFieldNames[lrname]
                        searchFieldNames[lrname] = layerProperties.searchFields
                    }
                    else
                    {
                        searchFieldNames[lrname] = layerProperties.searchFields
                    }
                }
            }
        }
        if (typeof layerServiceTable !== "undefined" && params.whereClause) {
            queryServiceTableForSearch(layerServiceTable, layername, txt,params)
        }
    }

    function getDisplayFieldLabel(serviceTable,displayField)
    {
        var displayFieldName = displayField
        for (var i=0; i<featureSearchProperties.layerProperties.length; i++) {
            var layerProperties = featureSearchProperties.layerProperties[i]
            var id = layerProperties.id
            if(serviceTable.layer)
            {
                var lyrid = ""

                if(serviceTable.layer)
                    lyrid = serviceTable.layer.layerId

                if(lyrid === id)
                {
                    var _popup = layerProperties.popupTemplate
                    if(_popup){
                        var _fieldInfos = _popup.fieldInfos
                        for(var k=0;k< _fieldInfos.length;k++)
                        {
                            let fldObject = _fieldInfos[k]
                            if(fldObject.fieldName === displayField)
                            {
                                displayFieldName = fldObject.label
                                break
                            }
                        }
                    }
                    break
                }
            }
        }
        return displayFieldName
    }


    function getDisplayField(serviceTable)
    {
        var displayField = ""
        for (var i=0; i<featureSearchProperties.layerProperties.length; i++) {
            var layerProperties = featureSearchProperties.layerProperties[i]
            var id = layerProperties.id
            var _displayField = layerProperties.displayField
            if(serviceTable.layer)
            {
                var lyrid = ""

                if(serviceTable.layer)

                    lyrid = serviceTable.layer.layerId

                if(lyrid === id)
                {
                    //displayField = _displayField
                    displayField = layerProperties.displayField
                    break
                }
            }
        }
        return displayField
    }


    function queryServiceTableForSearch (serviceTable, layerName, txt,featureParameters) {
        serviceTable.queryFeaturesStatusChanged.connect (function () {
            if(serviceTable)
            {
                if (serviceTable.queryFeaturesStatus === Enums.TaskStatusCompleted) {

                    if (serviceTable.queryFeaturesResult) {
                        let recCount = 0
                        let searchFields = ""
                        if(serviceTable.layer)
                            searchFields = searchFieldNames[serviceTable.layer.name]

                        for(let k=0;k<serviceTable.queryFeaturesResult.iterator.features.length;k++){
                            let feature = serviceTable.queryFeaturesResult.iterator.features[k],
                            attributeNames = feature.attributes.attributeNames
                            let search_attr_val = ""
                            let displayField = getDisplayField(serviceTable)
                            let displayFieldLabel = getDisplayFieldLabel(serviceTable,displayField)
                            if(displayField > "")
                            {
                                feature.attributes.attributeNames.forEach(fld =>
                                                                          {

                                                                              if(fld.toString().toUpperCase() === displayField.toUpperCase())
                                                                              {
                                                                                  let val = feature.attributes.attributeValue(fld)
                                                                                  //check if it is a domain field. if domain field get the domain name
                                                                                  let fields = feature.featureTable.fields//feature.fields

                                                                                  let dispalyFieldValue = mapViewerCore.getCodedValue(fields,fld,val)

                                                                                  let val_uppercase = val !== null?val.toString().toUpperCase():""
                                                                                  let txt_search = currentFeatureSearchText.toString().toUpperCase()

                                                                                  if(typeof val !== "undefined" )
                                                                                  search_attr_val = displayFieldLabel + " : " + dispalyFieldValue.toString()
                                                                                  else
                                                                                  search_attr_val = displayFieldLabel + " : null"
                                                                              }
                                                                          })
                            }
                            else
                            {
                                feature.attributes.attributeNames.forEach(fld =>
                                                                          {
                                                                              if(searchFields.includes(fld.toString()))
                                                                              {
                                                                                  let val = feature.attributes.attributeValue(fld)
                                                                                  let fields = feature.featureTable.fields//feature.fields

                                                                                  let dispalyFieldValue = mapViewerCore.getCodedValue(fields,fld,val)

                                                                                  let val_uppercase = val !== null?dispalyFieldValue.toString().toUpperCase():""
                                                                                  let txt_search = currentFeatureSearchText.toString().toUpperCase()
                                                                                  let n = val_uppercase.includes(txt_search);
                                                                                  if(n)
                                                                                  search_attr_val = fld.toString() + " : " + dispalyFieldValue.toString()

                                                                              }
                                                                          })
                            }

                            if(search_attr_val)
                            {
                                if(recCount < 10)
                                {
                                    recCount +=1
                                    mapView.searchfeaturesModel.append({
                                                                           "layerName": layerName,
                                                                           "search_attr": search_attr_val,
                                                                           "extent": feature.geometry,
                                                                           "showInView": false,
                                                                           "initialIndex": mapView.searchfeaturesModel.features.length,
                                                                           "hasNavigationInfo": false,
                                                                           "distance":"0"
                                                                       })

                                    mapView.searchfeaturesModel.features.push(feature)
                                }
                                else
                                    break

                            }
                        }

                        searchBusyIndicator.visible = false
                        featureSearchCompleted()
                        serviceTable = null
                    }
                    else
                    {
                        searchBusyIndicator.visible = false
                        featureSearchCompleted()
                        serviceTable = null
                    }
                }
            }
        })

        serviceTable.queryFeatures(featureParameters)
    }

    function performFeatureSearch (txt) {
        searchFeatures(txt)
    }

    function search (txt) {
        switch (searchPage.searchTabs[swipeView.currentIndex]) {
        case app.tabNames.kPlaces:
            mapView.geocodeModel.clearAll()
            searchPlaces(txt)
            break
        case app.tabNames.kFeatures:
            performFeatureSearch(txt)
            break
        }
    }

    function displayFeatureResultsCount (count) {
        if (count) {
            searchResultTitleText = app.isRightToLeft ? "%L1: %2".arg(count).arg(strings.count) : "%1: %L2".arg(strings.count).arg(count)
            swipeView.currentItem.item.searchViewTitleText = searchResultTitleText
        } else {
            swipeView.currentItem.item.searchViewTitleText = qsTr("No results found for features")
        }
    }

    function displayPlaceResultsCount (count) {
        if (count) {
            searchResultTitleText = app.isRightToLeft ? "%L1: %2".arg(count).arg(strings.count) : "%1: %L2".arg(strings.count).arg(count)
            swipeView.currentItem.item.searchViewTitleText = searchResultTitleText
        } else {
            if(swipeView.currentItem && swipeView.currentItem.item)
                swipeView.currentItem.item.searchViewTitleText = qsTr("No results found for places")
        }
    }
}
