/* Copyright 2022 Esri
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*    http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*
*/

import QtQuick 2.7
import QtSensors 5.3
import QtPositioning 5.3
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.1
import QtGraphicalEffects 1.0
import QtQuick.Controls.Material 2.3
import QtQuick.Controls.Material.impl 2.12
import Esri.ArcGISRuntime 100.14

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Platform 1.0

import "../../MapViewer/controls" as Controls
import "../../MapViewer/views"



Controls.BasePage {
    id: mapPage

    LayoutMirroring.enabled: app.isRightToLeft
    LayoutMirroring.childrenInherit: app.isRightToLeft
    Material.background: "white"

    property var portalItem
    property var mapProperties: Object
    property var portalItem_main
    property var mapProperties_main: Object
    property bool showMeasureTool: false
    property var attachqueryno:0
    signal getAttachmentCompleted()
    property bool isAttachmentPresent:false
    property bool isGetAttachmentRunning:false
    property Geodatabase offlineGdb:null
    property string defaultAnchor: app.isRightToLeft ? "anchorleft" :"anchorrightNoPanel"
    property var processedLayers : []
    property var layersWithAttachments
    property var layers:[]
    property var layerName:""
    property bool isFetchedFeatures:false
    property bool isJsonQueryFieldsPopulated:false
    property bool isMapLoaded:false
    property bool fetchingFeatures:false
    property var currentSelectedLayer:null
    property var prevSelectedLayer:null
    property var currentSelectedFeature:null
    property var currentSelectedIndex:0
    property var activeFeatureTable:""
    property var activePopupDefinition:""
    property bool isModelBindingInProcess:false
    property var headerColor: setHeaderColor()
    property bool openPopup:false
    property bool isSearchEnabled:true
    property bool isFeatureSearchEnabled: false
    property var searchConfigSources: []
    property bool isElevationEnabled:true
    property bool isLegendEnabled:false
    property bool isBaseMapEnabled: false
    property bool isBookMarkEnabled: false
    property bool isFilterEnabled:false
    property bool isBufferSearchEnabled:true
    property var popupfieldsArray: []
    property var popuptitle : ""
    property color maskColor : "#80000000"

    //<listindex,feature_key> useful for cases where features without attachments are not shown
    property var listIndexFeatureKeyDic:({})
    property bool backToGallery:false
    property var spatialQueryGraphicsArray:[]
    property var isSearLayerEnabled: false
    property var isFilterFinished: false
    property bool isFiltersInitialized: false
    property int linearUnit: Enums.LinearUnitIdKilometers
    property var definitionQueryDic:({})
    property var featureOIDDic:({})
    property var spatialSearchLayers:[] //store the layernames for spatial search
    property var layersToSearch:[]
    property var originalLayerVisibility: ({})
    property int noOfFiltersApplied: 0
    property var searchLayer
    property bool groupResultsByLayer:false
    property bool identifyInProgress:false
    property bool isInRouteMode:false
    property var existingmapareas:null
    property var mapAreasCount:0
    property var mapAreasModel:ListModel{}
    property var mapAreaGraphicsArray:[]
    property var mapAreaslst:[]
    property var  offlineSyncTask:null
    property var offlinemapSyncJob:null
    property var updatesAvailable:false
    property bool hasMapArea:false
    property bool willReadAppJson:true
    property bool showUpdatesAvailable:false
    property bool isMapAreaOpened:false
    property bool updateMapArea:false
    property bool comingFromMapArea:false
    property alias backIcon:backIcon

    signal cacheCleared()
    signal mapSyncCompleted(string title)

    // Attachments list model to send the attachments data to IdentifyPage
    property var attachmentListModel:ListModel{}
    property var emptyattachmentListModel:ListModel{}

    enum SearchOption {
        TapAtPoint,
        CurrentLocation
    }

    SimpleLineSymbol {
        id: simpleLineSymbol1

        width: 2
        color: "white"

    }

    Component{
        id:profileView
        ElevationProfileView{
            onPlotXYOnPolyline: {
                elevationpointGraphicsOverlay.graphics.clear()
                var simpleMarker = ArcGISRuntimeEnvironment.createObject("SimpleMarkerSymbol",
                                                                         {color: "red", size: app.units(12),outline:simpleLineSymbol1,
                                                                             style: Enums.SimpleMarkerSymbolStyleCircle})
                var graphic = ArcGISRuntimeEnvironment.createObject("Graphic",
                                                                    {symbol: simpleMarker, geometry: pointGeometry})

                graphic.zIndex = 9999
                graphic.selected = true
                elevationpointGraphicsOverlay.graphics.append(graphic)
                var isContained = GeometryEngine.contains(mapView.currentViewpointExtent.extent,elevationpointGraphicsOverlay.extent)
                if(!isContained)
                    mapView.setViewpointCenter(graphic.geometry)

            }

            onSetTitleWithUnits:{
                mapView.elevationUnits = units
                panelPage.title = strings.elevation_units.arg(mapView.elevationUnits)
                mapView.panelTitle = panelPage.title

            }




        }

    }


    //



    //

    ListModel {
        id:mediaListModel
    }

    Component{
        id: expressionTempModelComponent

        Controls.CustomListModel {
            id: featuresTempModel
        }
    }


    function getCurrentView(tabName)
    {
        if(tabName === app.tabNames.kElevation)
            return profileView


    }

    function setHeaderColor(){ //TODO

        return app.primaryColor
    }

    function openPopupForAppLinkFeature()
    {
        if(app.urlParameters.objectid)
        {
            let indx = layerManager.featureIndexDic[app.urlParameters.objectid] //= mediaListModel.count - 1
            if(indx > -1)
            {
                let mediaObject = mediaListModel.get(indx)
                let key = mediaObject.key

                var featObj = mapView.featuresModel.features[key];
                mapPage.currentSelectedIndex = key
                mapView.identifyProperties.reset()
                if(featObj && featObj.feature)
                {
                    var feature = featObj.feature
                    openPopup = true
                    mapView.loadFeatureAndPopulateFromMedia(feature,featObj.attachments)
                    currentSelectedFeature = feature
                }


            }
            else
            {
                messageDialog.show(qsTr("Error"),strings.object_not_found.arg(app.urlParameters.objectid));
            }

        }


    }

    Connections{
        id:attachmentLoader
        target:layerManager
        function onPopulateAttachmentCompleted() {
            if((mapView.featuresModel.features.length > 100) && mediaListModel.count === 100)
                toastMessage.show(strings.loading_first_100)

        }

        function onFetchFeaturesCompleted() {
            if(!isFetchedFeatures)
            {
                isFetchedFeatures = true
                fetchingFeatures = false
                if((mapView.featuresModel.features.length > 100) && mediaListModel.count === 100)
                    toastMessage.show(strings.loading_first_100)
                mapView.identifyProperties.highlightInMap(currentSelectedLayer,currentSelectedFeature,false)

                openPopupForAppLinkFeature()
            }
        }
    }

    Component.onCompleted: {
        processedLayers = []

    }



    onGetAttachmentCompleted: {

        isGetAttachmentRunning = false
    }

    Item {
        id: screenSizeState

        states: [
            State {
                name: "SMALL"
                when: !isLandscape
            }
        ]

        onStateChanged: {
        }
    }

    header: ToolBar {
        id: mapPageHeader
        width: parent.width
        height: app.headerHeight + app.notchHeight
        topPadding: app.notchHeight

        Material.background: headerColor
        Material.elevation: 2

        RowLayout {
            anchors {
                fill: parent
                rightMargin: app.isLandscape ? app.widthOffset: 0
                leftMargin: app.isLandscape ? app.widthOffset: 0
            }
            spacing: 0


            Controls.Icon {
                id: menuIcon//backIcon

                iconSize: 6 * app.baseUnit
                visible: !backIcon.visible

                imageSource: ( app.webMapsModel.count === 1 ? "../../MapViewer/images/menu.png" : "../../MapViewer/images/outline_grid_view_white_48dp.png")

                onClicked: {
                    if ( app.webMapsModel.count === 1 ) {
                        sideMenu.open();
                    } else {
                        app.urlParameters = {}
                        pageView.hidePanelItem()
                        pageView.hideSearchItem()
                        moreIcon.checked = false

                        if((stackView.currentItem.objectName === "mapPage") && (stackView.depth === 2))
                        {
                            app.urlParameters = ({})
                            stackView.replace(mapPage, galleryPage);
                        }

                        mapPage.previous();
                        //if (locationBtn.checked) locationBtn.clicked();
                    }
                }
            }

            Controls.Icon {
                id: backIcon

                iconSize: 6 * app.baseUnit
                visible:mapProperties.isMapArea && portalItem_main !== undefined && app.isOnline//false

                imageSource:"../../MapViewer/images/back.png"
                onClicked: {
                    mapView.clearSearch()

                    // to enable re populating the user-defined filters in the FiltersView and to show filter icon only after the filters loads
                    isJsonQueryFieldsPopulated = false
                    isFiltersInitialized = false
                    pageView.hidePanelItem()

                    comingFromMapArea = true
                    portalItem = portalItem_main
                    mapProperties = mapProperties_main
                    hasMapArea = true
                    portalItem_main = null
                    mapProperties_main = null
                }
            }

            Controls.SpaceFiller {
            }

            RowLayout {
                id: mapTools
                visible: (mapView.map ? (mapView.map.loadStatus === Enums.LoadStatusLoaded) : false)
                Layout.fillHeight: true
                Layout.fillWidth: true
                spacing: 0

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                Controls.Icon {
                    id: searchIcon
                    iconSize: 6 * app.baseUnit
                    visible: {
                        return isSearchEnabled && ( app.isOnline || isFeatureSearchEnabled )
                    }

                    imageSource: "../../MapViewer/images/search.png"
                    checkable: true

                    onCheckedChanged: {
                        if (checked) {

                            pageView.hidePanelItem()
                            searchDockItem.addDock()
                            moreIcon.checked = false

                        } else {
                            searchDockItem.removeDock()

                        }
                    }

                }
                Item{
                    width:filterIcon.width
                    height:filterIcon.height
                    visible: ( !isBufferSearchEnabled && Object.keys(mapView.filterLayersDic).length === 0 ) || !isFiltersInitialized ? false : true

                    Controls.Icon {
                        id: filterIcon
                        iconSize: 6 * app.baseUnit
                        visible:isSearchEnabled

                        imageSource: mapView.filterConfigModel.count > 0 ? "../../MapViewer/images/ic_tune_white_48dp.png": "../../MapViewer/images/ic_map_marker_radius_outline_white_48dp.png"
                        checkable: true

                        onCheckedChanged: {
                            if (checked) {
                                moreIcon.checked = false
                                pageView.hideSearchItem()
                                panelDockItem.addDock("filters")
                            } else {
                                pageView.hidePanelItem();
                            }
                        }
                    }

                    Rectangle{
                        width:filterplaceholder.text.length > 1 ? filterplaceholder.width : filterplaceholder.width + app.units(4)//filterplaceholder.text.length > 1 ? app.units(16):app.units(12)
                        height:filterplaceholder.text.length > 1? app.units(16) :width
                        radius:filterplaceholder.text.length > 1 ? app.units(8) :width
                        Material.elevation: -1

                        anchors.left:filterIcon.right

                        anchors.top:filterIcon.top
                        anchors.leftMargin: -app.units(20)
                        anchors.topMargin: app.units(6)
                        visible:filterplaceholder.text > 0
                        border.width:app.units(2)
                        border.color:app.primaryColor

                        Label {
                            id: filterplaceholder

                            text:noOfFiltersApplied
                            leftPadding: app.units(4)
                            rightPadding: app.units(4)

                            color: app.primaryColor
                            font.bold: true
                            anchors.centerIn: parent
                            //opacity: 0.5

                            font.pixelSize: 10 * app.scaleFactor
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter

                        }

                    }

                }

                Controls.Icon {
                    id: mapareasSyncIcon
                    visible:app.isOnline?(mapProperties.isMapArea?mapProperties.isMapArea:false):false

                    objectName: "updatesAvailable"
                    imageSource: "../../MapViewer/images/available-updates-24.png"

                    MouseArea {
                        anchors.fill: parent
                        visible:true
                        onClicked: {

                            app.messageDialog.standardButtons = Dialog.Yes | Dialog.No
                            app.messageDialog.show("", qsTr("Do you want to update  %1?").arg(portalItem.title))
                            app.messageDialog.connectToAccepted(function () {
                                mapareasbusyIndicator.visible = true
                                checkForUpdates()
                                //applyUpdates()
                            })



                        }
                    }
                    enabled: !mapareasbusyIndicator.visible
                    BusyIndicator {
                        id: mapareasbusyIndicator

                        visible: false

                        Material.primary: "white"//app.primaryColor
                        Material.accent: "white"//app.accentColor
                        width: app.iconSize
                        height: app.iconSize
                        anchors.centerIn: parent
                    }
                }


                Controls.Icon {
                    id: moreIcon

                    objectName: "more"
                    imageSource: "../../MapViewer/images/more.png"
                    iconSize: 6 * app.baseUnit
                    checkable: true
                    onCheckedChanged: {
                        if (checked) {
                            more.open()
                        } else {
                            more.close()
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        visible: showMeasureTool
                        onClicked: {
                            parent.checked = true
                        }
                    }
                }

                Item {
                    Layout.preferredWidth: app.units(2)
                    Layout.fillHeight: true
                }
            }

            Controls.PopupMenu {
                id: more
                defaultMargin: app.defaultMargin
                backgroundColor: "#FFFFFF"
                highlightColor: Qt.darker(app.backgroundColor, 1.1)
                textColor: app.baseTextColor
                primaryColor: app.primaryColor
                menuItems: getMenuItems()

                Material.primary: app.primaryColor
                Material.background: backgroundColor

                height: app.units(32 * getMenuItems().length) + app.defaultMargin

                x: app.isRightToLeft ? (0 + app.baseUnit) : (parent.width - width - app.baseUnit)
                y: 0 + app.baseUnit

                onMenuItemSelected: {
                    searchIcon.checked = false
                    switch (itemLabel) {
                    case strings.tab_about:
                        pageView.hideSearchItem()
                        panelDockItem.addDock("about")
                        break

                    case strings.kLegend:
                        pageView.hideSearchItem()
                        panelDockItem.addDock("legend")
                        break

                    case strings.kBasemaps:
                        pageView.hideSearchItem()
                        panelDockItem.addDock("basemaps")
                        break

                    case strings.kBookmarks:
                        pageView.hideSearchItem()
                        panelDockItem.addDock("bookmark")
                        break

                    case strings.kMapArea:
                        pageView.hideSearchItem()
                        mapView.clearSearch()
                        panelDockItem.addDock("mapareas")
                        break
                    }
                }

                function titleCase(str) {
                    return str.toLowerCase().split(" ").map(function(word) {
                        return (word.charAt(0).toUpperCase() + word.slice(1));
                    }).join(" ");
                }
                onClosed: moreIcon.checked = false

                function getMenuItems()
                {
                    let items = [
                            {"itemLabel": strings.tab_about}];

                    if( isLegendEnabled ) {
                        items.push({"itemLabel": strings.kLegend});
                    }

                    if ( isBaseMapEnabled ){
                        items.push({"itemLabel": strings.kBasemaps});
                    }

                    if ( isBookMarkEnabled ){
                        items.push({"itemLabel": strings.kBookmarks});
                    }
                    if(hasMapArea){
                        items.push({"itemLabel": strings.kMapArea});
                    }


                    return items

                }

                function updateMenuItemsContent () {

                    if(isLegendEnabled)
                        more.appendUniqueItemToMenuList({"itemLabel": strings.kLegend})


                    if ( isBaseMapEnabled)
                        more.appendUniqueItemToMenuList({"itemLabel": strings.kBasemaps})

                    if (isBookMarkEnabled)
                        more.appendUniqueItemToMenuList({"itemLabel": strings.kBookmarks})
                    if(hasMapArea)
                        more.appendUniqueItemToMenuList({"itemLabel": strings.kMapArea})

                }


            }
        }


        Behavior on y {
            NumberAnimation {
                duration: 100
            }
        }
    }

    contentItem: Item {

        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }


        Item{
            id: pageView

            width:pageView.state !=="anchorright"?app.width:app.width * 0.65

            anchors {
                top: parent.top
                right: parent.right
                bottom: parent.bottom
            }
            PanelPage {
                id: panelPage

                property real extentFraction: 0.48
                anchors.top:pageView.top

                mapView: mapView

                pageExtent: (1-extentFraction) * pageView.height


            }

            MenuPage {
                id: sideMenu

                fallbackBannerImage: "../../MapViewer/images/default-thumbnail.png"

                title: portalItem ? mapPage.portalItem.title : ""
                modified: portalItem ? mapPage.portalItem.modified : ""
                bannerImage: getThumbnailUrl()
                y:0//mapPage.top


                onCacheCleared: {
                    mapPage.cacheCleared()
                }


                onMenuItemSelected: {
                    switch (itemLabel) {
                    case app.kBack:
                    case app.kBackToGallery:
                        pageView.hidePanelItem()
                        pageView.hideSearchItem()
                        moreIcon.checked = false

                        //toolBarBtns.uncheckAll(mapPage.previous)
                        mapPage.previous()
                        if (locationBtn.checked) locationBtn.clicked()
                        break
                    }
                }

                Component.onCompleted: {
                    if (app.showBackToGalleryButton) {
                        sideMenu.insertItemToMenuList(0, { "iconImage": "../images/back.png", "itemLabel": app.kBackToGallery, "control": "" })
                    }

                    title = portalItem ? mapPage.portalItem.title : ""
                    modified = portalItem ? mapPage.portalItem.modified : ""
                    bannerImage = getThumbnailUrl()
                }


                function getThumbnail_MapArea()
                {
                    var url = fallbackBannerImage

                    var storageBasePath = offlineMapAreaCache.fileFolder.path//app.rootUrl //AppFramework.resolvedUrl("./ArcGIS/AppStudio/cache")

                    var mapareapath = [storageBasePath,portalItem.mapid].join("/")
                    if(Qt.platform.os === "windows")
                        url = "file:///" + mapareapath + "/" + portalItem.id + "_thumbnail/" + portalItem.thumbnailUrl
                    else
                        url = "file://" + mapareapath + "/" + portalItem.id + "_thumbnail/" + portalItem.thumbnailUrl
                    return url
                }

                function getThumbnailUrl () {
                    try {
                        if(portalItem.type === "maparea")
                            return getThumbnail_MapArea()
                        else
                        {
                            var url = portalItem ? mapPage.portalItem.thumbnailUrl.toString() : ""
                            if (url.startsWith("http") && portalItem){
                                url = offlineCache.cache(url, '', {"token":app.portal?(app.portal.credential?app.portal.credential.token:""):""}, null)
                                url += "?token=%1".arg(app.portal?(app.portal.credential?app.portal.credential.token:""):"");
                            }
                            return url > "" ? url : fallbackBannerImage
                        }
                    } catch (err) {
                        return fallbackBannerImage
                    }
                }

            }

            MapView {
                id: mapView
                anchors.top:pageView.top
                width:(searchDockItem.visible || panelDockItem.visible)?(pageView.state ==="anchorbottom"?app.width:app.width  * 0.65):app.width
                height: pageView.state ==="anchorbottom" ? parent.height * 0.6 : parent.height

                property var tasksInProgress: []
                property ListModel contentsModel_copy: ListModel {}
                property ListModel contentsModel: ListModel {}
                property ListModel contentListModel: ListModel {}
                property ListModel mapunitsListModel: ListModel {}
                property ListModel gridListModel: ListModel{}
                property ListModel unOrderedLegendInfos: Controls.CustomListModel {}
                property ListModel orderedLegendInfos: Controls.CustomListModel {} // model used in view
                property int noSwatchRequested:0
                property int noSwatchReceived:0
                property var scale:mapView.mapScale
                property int noOfFeaturesRequestReceived:0
                property int noOfFeaturesRequested:0
                property var featureTableRequestReceived:[]
                property bool isIdentifyTool:false
                property int mapReadyCount: 0
                property real initialMapRotation: 0
                property alias compass: defaultLocationDataSource.compass
                property alias devicePositionSource: defaultLocationDataSource.positionInfoSource
                property Point center
                property alias pointGraphicsOverlay:placeSearchResult
                property string routeColor:"#003333"
                property var fromGraphic:null
                property var toGraphic:null
                property var routeStops: []
                property var fromRouteAddress:""
                property var toRouteAddress:""
                property var allPoints: []
                property var searchText:""
                property string activeSearchTab:app.tabNames.kPlaces
                property alias geocodeModel:geocodeModel
                property alias featuresModel:featuresModel
                property var layerResults: [] //Arrays that store results of one layer in one listmodel
                property alias searchfeaturesModel:searchfeaturesModel
                property alias withinExtent:withinExtent
                property alias outsideExtent:outsideExtent
                property alias myWebMap:myWebmap
                property alias polygonGraphicsOverlay:polygonGraphicsOverlay
                property alias simpleMapAreaFillSymbol:simpleMapAreaFillSymbol

                // Selected buffer point on user mouse-click: Point QMLType
                property Point selectedBufferPoint
                property Point routeFromPoint:selectedBufferPoint
                property var routeStartIconName:"redPin.png"
                property Point destinationPoint
                property var layersWithAttachments:ListModel{}
                property var bufferDistance:defaultDistance
                property var defaultDistance:1
                property var bufferMax: 100
                property var bufferMin: 0
                property int bufferRadiusPrecision: 1

                property var layerSpatialSearch: [] //Layers included in the results
                property var layerDirection: [] //Layers for which direction service is enabled
                property bool isFilter: false //Whether the filters are configured
                property ListModel filterConfigModel:ListModel{} //Listmodel that store the info of the layers that have filters configured
                property var filterLayersDic:({}) //Dictionary that have listmodels for each layer that have filters

                property string measureUnitsString:strings.km
                property bool includeDistance: true
                property bool showDirections: false
                property int measureUnits: measurePanel.lengthUnits.kilometers
                property string noResultsMessage:""
                property var bufferGeometry
                property var searchExtent
                // property alias searchTimer:_searchTimer
                property int selectedSearchOption: NearbyMapPage.SearchOption.TapAtPoint
                property var selectedSearchDistanceMode:"bufferCenter"
                property alias distanceLineGraphicsOverlay:distanceGraphicsOverlay
                property var distanceData:"4"
                property string elevationUnits:strings.ft

                property bool canShowSearchDistanceControls:true
                property var currentFeatureIndexForElevation:-1
                property var panelTitle:panelPage.title
                property  var selectedMeasurementUnits:measurementUnits.imperial
                property var prevMapExtent
                property bool isPanning:false
                property bool isInSearchMode:false
                signal showMoreMenu(var x, var y)

                QtObject {
                    id: measurementUnits

                    property int metric: 0
                    property int imperial: 1

                }



                QtObject {
                    id: searchMode

                    property int attribute: 0
                    property int spatial: 1

                }


                Controls.CustomListModel {
                    id: searchfeaturesModel

                    property var features: []
                    property int currentIndex: -1
                    //property var notToShowFeatures:[]

                    function clearAll () {
                        currentIndex = -1
                        features = []
                        clear()
                        mapView.identifyProperties.clearHighlight()
                    }
                }


                Controls.CustomListModel {
                    id: featuresModel

                    property var features: []
                    property int currentIndex: -1
                    property var notToShowFeatures:[]
                    property var featuresToShow:[]
                    property var searchMode:searchMode.attribute

                    function clearAll () {
                        currentIndex = -1
                        features = []
                        clear()
                        mapView.identifyProperties.clearHighlight()
                    }
                }

                Component{
                    id: featuresTempModelComponent
                    Controls.CustomListModel {
                        id: featuresTempModel

                        property var features: []
                        property int currentIndex: -1
                        property var notToShowFeatures:[]
                        property var featuresToShow:[]

                        function clearAll () {
                            currentIndex = -1
                            features = []
                            clear()
                            mapView.identifyProperties.clearHighlight()
                        }
                    }
                }



                Controls.CustomListModel {
                    id: geocodeModel


                    property var features: []
                    property int currentIndex: -1

                    function clearAll () {
                        currentIndex = -1
                        features = []
                        clear()
                        withinExtent.clear()
                        outsideExtent.clear()
                    }

                    function appendModelData (model) {
                        for (var i=0; i<model.count; i++) {
                            append(model.get(i))
                        }
                    }
                }

                Controls.CustomListModel {
                    id: withinExtent
                }

                Controls.CustomListModel {
                    id: outsideExtent
                }


                property int legendProcessingCountLimit: 250

                property QtObject layersWithErrorMessages: QtObject {
                    id: layersWithErrorMessages

                    property var layers: []
                    property var messagesRequiringLogin: [
                        "Unable to generate token.",
                        "Token Required"
                    ]
                    property real count: layers.length

                    function clear () {
                        layers = []
                    }

                    function append (item) {
                        layers.push(item)
                        count += 1
                    }

                    onLayersChanged: {
                        count = layers.length
                    }

                    onCountChanged: {
                        if (count) {
                            handleErrors()
                        }
                    }

                    function handleErrors () {
                        for (var i=0; i<count; i++) {
                            var layerContent = layers[i]

                            if (!layerContent.verified) {

                                if (layerContent.layer.loadError) {
                                    if (messagesRequiringLogin.indexOf(layerContent.layer.loadError.message) !== -1) {

                                        // Commented out because this is handled by the singleton AuthenticationManager
                                        // Mark as verified and let AuthenticationManager handle it

                                        //loginDialog.show(qsTr("Authentication required to acceess the layer %1").arg(layerContent.layer.name))
                                        //loginDialog.onAccepted.connect(function () {
                                        //    layerContent.verified = true
                                        //    return handleErrors()
                                        //})
                                        //loginDialog.onRejected.connect(function () {
                                        //    layerContent.verified = true
                                        //    return handleErrors()
                                        //})

                                        layerContent.verified = true // verified by AuthenticationManager in loginDialog
                                        return handleErrors()
                                    } else if (!app.messageDialog.visible) {
                                        var title = layerContent.layer.loadError.message
                                        var message = layerContent.layer.loadError.additionalMessage
                                        if (!title || !message) {
                                            message = message ? message : title
                                            title = ""
                                        }
                                        app.messageDialog.show (title, message)
                                        app.messageDialog.connectToAccepted(function () {
                                            layerContent.verified = true
                                            return layersWithErrorMessages.handleErrors()
                                        })
                                    }
                                }
                            }
                        }
                    }
                }

                property QtObject identifyProperties: QtObject {
                    id: identifyProperties
                    property int popupManagersCount: popupManagers.length
                    property int popupDefinitionsCount: popupDefinitions.length
                    property int featuresCount: features.length
                    property int fieldsCount: fields.length
                    property int attachmentsCount:attachments.length

                    property var popupManagers: []
                    property var popupDefinitions: []
                    property var features: []
                    property var fields: []
                    property var temporal: []
                    property var relatedFeatures:[]
                    property var attachments:[]

                    property var currentFeatureIndex:0

                    property var currentFeatureIndexForElevation:0

                    function reset () {
                        identifyProperties.clearHighlight()
                        popupManagers = []
                        popupDefinitions = []
                        features = []
                        fields = []
                        mapView.noOfFeaturesRequested = 0
                        mapView.noOfFeaturesRequestReceived = 0
                        mapView.featureTableRequestReceived = []
                        attachments = []

                        computeCounts()
                    }


                    function computeCounts () {
                        popupManagersCount = popupManagers.length
                        popupDefinitionsCount = popupDefinitions.length
                        featuresCount = features.length
                        fieldsCount = fields.length
                        attachmentsCount = attachments.length
                    }


                    function highlightInMap(featureLayer,feature,zoom)
                    {
                        clearHighlightInLayer()
                        if(featureLayer)
                        {
                            featureLayer.clearSelection()
                            featureLayer.selectFeature(feature)
                            if(isBufferSearchEnabled){
                                const centerPoint2 = GeometryEngine.project(feature.geometry, mapView.spatialReference)
                                const viewPointCenter = ArcGISRuntimeEnvironment.createObject("ViewpointCenter", {center: centerPoint2})
                                if (feature.geometry.geometryType === Enums.GeometryTypePoint)
                                    mapView.setViewpointGeometryAndPadding(mapView.bufferGeometry.extent,30)
                                else
                                {
                                    let isContained = GeometryEngine.contains(mapView.bufferGeometry.extent,feature.geometry.extent)
                                    if(isContained)
                                        mapView.setViewpointGeometryAndPadding(mapView.bufferGeometry.extent,30)
                                    else
                                    {
                                        let combinedGeometry = []
                                        combinedGeometry.push(mapView.bufferGeometry)
                                        combinedGeometry.push(feature.geometry)
                                        var combinedextent = GeometryEngine.combineExtentsOfGeometries(combinedGeometry);
                                        mapView.setViewpointGeometryAndPadding(combinedextent,30)
                                    }

                                }

                            }
                            else
                            {
                                let extent = mapView.searchExtent //mapView.currentViewpointExtent.extent
                                mapView.setViewpointGeometryAndPadding(extent,0)

                            }

                        }
                    }

                    function zoomToFeature(feature)
                    {
                        mapView.prevMapExtent = mapView.currentViewpointExtent.extent
                        mapView.setViewpointGeometryAndPadding(feature.geometry.extent,40)
                    }

                    function zoomToPreviousExtent()
                    {
                        mapView.setViewpointGeometryAndPadding(mapView.prevMapExtent,0)
                    }

                    function showInMap(featuregeometry,zoom)
                    {

                        clearHighlight()


                        if (featuregeometry.geometryType === Enums.GeometryTypePoint) {
                            var simpleMarker = ArcGISRuntimeEnvironment.createObject("SimpleMarkerSymbol",
                                                                                     {color: "cyan", size: app.units(10),
                                                                                         style: Enums.SimpleMarkerSymbolStyleCircle}),
                            graphic = ArcGISRuntimeEnvironment.createObject("Graphic",
                                                                            {symbol: simpleMarker, geometry: featuregeometry})
                            pointGraphicsOverlay.graphics.append(graphic)
                            mapView.setViewpointCenter(graphic.geometry)
                            if (zoom) {

                                mapView.zoomToPoint(pointGraphicsOverlay.extent.center)
                            }
                            temporal.push(simpleMarker, graphic)
                        } else if (featuregeometry.geometryType === Enums.GeometryTypePolygon) {
                            simpleFillSymbol.color = "transparent"
                            var graphic = ArcGISRuntimeEnvironment.createObject("Graphic",
                                                                                {symbol: simpleFillSymbol, geometry: featuregeometry})
                            polygonGraphicsOverlay.graphics.append(graphic)

                            //zoom to the feature after expanding 150% in case it is not within the current map extent
                            if (zoom) {
                                var isContained = GeometryEngine.contains(mapView.currentViewpointExtent.extent,polygonGraphicsOverlay.extent)
                                //if(!isContained)
                                mapView.zoomToExtent(polygonGraphicsOverlay.extent)
                                //else
                            }
                            else
                                mapView.setViewpointCenter(polygonGraphicsOverlay.extent.center)

                            temporal.push(graphic)
                        } else {
                            simpleFillSymbol.color = "cyan"
                            var graphic = ArcGISRuntimeEnvironment.createObject("Graphic",
                                                                                {symbol: simpleLineSymbol, geometry: featuregeometry})
                            lineGraphicsOverlay.graphics.append(graphic)
                            if (zoom) {
                                var isContained_pt = GeometryEngine.contains(mapView.currentViewpointExtent.extent,lineGraphicsOverlay.extent)

                                if(!isContained_pt)
                                {

                                    mapView.zoomToExtent(lineGraphicsOverlay.extent)
                                }
                                else
                                    mapView.setViewpointCenter(lineGraphicsOverlay.extent.center)
                            }
                            else
                                mapView.setViewpointCenter(lineGraphicsOverlay.extent.center)
                            temporal.push(graphic)
                        }

                    }

                    function highlightFeature (index, zoom) {
                        if (!zoom) zoom = false
                        if (!features.length) return

                        var feature = features[index]
                        clearHighlight()
                        showInMap(feature.geometry,zoom)


                    }

                    function clearGroupLayer(layer)
                    {
                        if(layer.subLayerContents.length > 0)
                        {
                            for(let k=0;k<layer.subLayerContents.length;k++)
                            {
                                let sublyr = layer.subLayerContents[k]
                                clearGroupLayer(sublyr)
                            }
                        }
                        else
                        {
                            try{
                                layer.clearSelection()
                            }
                            catch(ex)
                            {
                                console.error(ex)
                            }
                        }

                    }

                    function clearHighlightInLayer(){
                        try{
                            clearHighlight();

                            for (var i = 0 ; i < mapView.map.operationalLayers.count; i++) {
                                var lyr = mapView.map.operationalLayers.get(i);
                                if(lyr.objectType === "GroupLayer")
                                    clearGroupLayer(lyr)
                                else
                                {
                                    if(lyr && lyr.objectType === "FeatureCollectionLayer") {
                                        for(var j = 0; j < lyr.layers.length; j++){
                                            lyr.layers[j].clearSelection()
                                        }
                                    }
                                    else
                                    {

                                        if(lyr && lyr.objectType !== "ArcGISVectorTiledLayer" && lyr.objectType !== "ArcGISTiledLayer" && lyr.objectType !== "ArcGISMapImageLayer" && lyr.visible)
                                            lyr.clearSelection();

                                    }
                                }
                            }
                        }
                        catch(ex)
                        {
                            console.log(ex)

                        }
                    }


                    function clearHighlight (callback) {
                        if (!callback) callback = function () {}
                        pointGraphicsOverlay.graphics.clear()
                        polygonGraphicsOverlay.graphics.clear()
                        lineGraphicsOverlay.graphics.clear()
                        for (var i=0; i<temporal.length; i++) {
                            if (temporal[i]) {
                                temporal[i].destroy()
                            }
                        }
                        temporal = []
                        callback()
                    }
                }

                property QtObject mapInfo: QtObject {
                    id: mapInfo

                    property string title: ""
                    property string snippet: ""
                    property string description: ""
                }

                onMapReadyCountChanged: {
                    if (mapReadyCount === 1) {
                        initialMapRotation = mapRotation
                    }
                }

                onMapScaleChanged:{
                    if(!elapsedTimer.running)
                        elapsedTimer.start()

                }

                backgroundGrid: BackgroundGrid {
                    gridLineWidth: 1
                    gridLineColor: "#22000000"
                }
                /*

               The below events work to redo the search on panning the map.But we need to do the same with zoom events

                onMousePressed: {
                    mapView.prevMapExtent = mapView.currentViewpointExtent.extent
                }

                onMouseReleased: {
                    let extentChanged = isExtentChanged(mapView.prevMapExtent,mapView.currentViewpointExtent.extent)

                    if(extentChanged){

                       // if(clearBtn.text ===  strings.clear_search && !isBufferSearchEnabled)
                       if(isInSearchMode && !isBufferSearchEnabled)
                        {
                            notTooltipOnStart.contentText = ""
                            if(mapView.layerSpatialSearch.length > 0) //if have the configuration have lookupLayers, search in the layerSpatialSearch array
                                mapView.findFeaturesInMapExtent(mapView.layerSpatialSearch);
                            else { //do not have lookuplayers in configuration
                                mapView.findFeaturesInMapExtent();
                            }

                        }
                    }

                }*/

                function isExtentChanged(extent1, extent2)
                {
                    if((extent1.xMin !== extent2.xMin) || (extent1.yMin !== extent2.yMin) || (extent1.xMax != extent2.xMax) || (extent1.yMax !== extent2.yMax))
                        return true
                    else
                        return false
                }



                Map {
                    id:myWebmap
                    initUrl: mapPage.portalItem?(mapPage.portalItem.type === "Web Map" ? mapPage.portalItem.url : ""):""

                    onLoadStatusChanged: {
                        mapView.processLoadStatusChange()
                        if(mapPage.portalItem && mapPage.portalItem.type === "Web Map")
                        {
                            mapAreaManager.portalItem = mapPage.portalItem
                            existingmapareas = mapAreaManager.checkExistingAreas()
                            more.updateMenuItemsContent()
                            var taskid = offlineMapTask.preplannedMapAreas();
                        }
                    }

                    onLoadErrorChanged: {
                        mapView.processLoadErrorChange()
                    }
                }

                BusyIndicator {
                    id: mapBusyIndicator
                    Material.primary: headerColor
                    Material.accent: headerColor
                    visible: ((mapView.drawStatus === Enums.DrawStatusInProgress) && (mapView.mapReadyCount < 1)) || (mapView.identifyLayersStatus === Enums.TaskStatusInProgress) || identifyInProgress === true
                    width: 40 * app.scaleFactor
                    height: 40 * app.scaleFactor
                    anchors.centerIn: parent
                }

                rotationByPinchingEnabled: true
                zoomByPinchingEnabled: true
                wrapAroundMode: Enums.WrapAroundModeEnabledWhenSupported

                ColumnLayout{
                    id:searchDistanceControls
                    property real radius: 0.5 * app.mapControlIconSize
                    width: mapControls.radius + app.defaultMargin
                    visible: !isInRouteMode && mapView.includeDistance && mapView.featuresModel.count > 0  && mapView.devicePositionSource.active

                    anchors {
                        top: parent.top
                        left: parent.left


                        margins: app.defaultMargin

                        leftMargin:app.isLandscape ? app.widthOffset +  app.defaultMargin : app.defaultMargin
                        topMargin: app.defaultMargin

                    }
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: app.defaultMargin
                    }

                    RoundButton {
                        id: searchBufferBtn

                        radius: mapControls.radius
                        Material.background: "#FFFFFF"
                        Layout.preferredWidth: 2 * mapControls.radius
                        Layout.preferredHeight: Layout.preferredWidth
                        checkable: true
                        checked:mapView.selectedSearchDistanceMode === "bufferCenter"//true

                        contentItem: Image {
                            id: bufferCenterImg
                            source:"../../MapViewer/images/button_buffer_center.png"

                            width: mapControls.radius
                            height:  mapControls.radius
                            mipmap: true
                            fillMode: Image.PreserveAspectFit
                        }
                        ColorOverlay{
                            anchors.fill: bufferCenterImg
                            source: bufferCenterImg

                            color: searchBufferBtn.checked ?"steelblue": colors.blk_200

                        }

                        onVisibleChanged: {
                            if ( mapView.selectedSearchDistanceMode === "bufferCenter" ){
                                searchBufferBtn.checked = true;
                                searchCurrentLocationBtn.checked = false;
                            } else if ( mapView.selectedSearchDistanceMode === "currentLocation" ){
                                searchCurrentLocationBtn.checked = true;
                                searchBufferBtn.checked = false;
                            }
                        }

                        onClicked: {
                            if(searchBufferBtn.checked)
                            {
                                if(searchCurrentLocationBtn.checked)
                                {
                                    mapView.distanceLineGraphicsOverlay.graphics.clear()
                                    searchCurrentLocationBtn.checked = false
                                }
                                mapView.selectedSearchDistanceMode = "bufferCenter"
                                //update distance on the CarouselDelegate

                            }
                            else
                            {
                                mapView.distanceLineGraphicsOverlay.graphics.clear()
                                searchCurrentLocationBtn.checked = true
                                mapView.selectedSearchDistanceMode = "currentLocation"
                            }
                            // mapView.locationDisplay.stop()
                        }
                    }
                    RoundButton {
                        id: searchCurrentLocationBtn

                        radius: mapControls.radius
                        Material.background: "#FFFFFF"
                        Layout.preferredWidth: 2 * mapControls.radius
                        Layout.preferredHeight: Layout.preferredWidth
                        checkable: true
                        checked:mapView.selectedSearchDistanceMode === "currentLocation"//false

                        contentItem: Image {
                            id: currentLocImg
                            source:"../../MapViewer/images/button_current_location.png"
                            width: mapControls.radius
                            height: mapControls.radius
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                        }


                        ColorOverlay{
                            anchors.fill: currentLocImg
                            source: currentLocImg

                            color: searchCurrentLocationBtn.checked ?"steelblue": colors.blk_200
                        }
                        onClicked: {
                            if(searchCurrentLocationBtn.checked)
                            {
                                if(searchBufferBtn.checked)
                                {
                                    mapView.distanceLineGraphicsOverlay.graphics.clear()
                                    searchBufferBtn.checked = false
                                }
                                mapView.selectedSearchDistanceMode = "currentLocation"
                                //update distance on the CarouselDelegate

                            }
                            else
                            {
                                mapView.distanceLineGraphicsOverlay.graphics.clear()
                                searchBufferBtn.checked = true
                                mapView.selectedSearchDistanceMode = "bufferCenter"
                            }
                        }
                    }
                }

                ColumnLayout {
                    id: mapControls
                    property real radius: 0.5 * app.mapControlIconSize
                    height: parent.height - 148 * app.scaleFactor//3 * width
                    width: mapControls.radius + app.defaultMargin

                    anchors {
                        top: parent.top
                        right: parent.right

                        margins: app.defaultMargin

                        rightMargin:app.isLandscape ? app.widthOffset +  app.defaultMargin : app.defaultMargin
                        topMargin: app.defaultMargin

                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: app.defaultMargin
                    }

                    RoundButton {
                        radius: mapControls.radius
                        Material.background: "#FFFFFF"
                        Layout.preferredWidth: 2 * mapControls.radius
                        Layout.preferredHeight: Layout.preferredWidth
                        contentItem: Image {
                            id: homeImg
                            source: "../../MapViewer/images/home.png"
                            width: mapControls.radius
                            height: mapControls.radius
                            mipmap: true
                        }
                        ColorOverlay{
                            anchors.fill: homeImg
                            source: homeImg
                            color: colors.blk_200
                        }
                        onClicked: {
                            mapView.setViewpointWithAnimationCurve(mapView.map.initialViewpoint, 2.0, Enums.AnimationCurveEaseInOutCubic)
                            pageView.hidePanelItem()
                            pageView.hideSearchItem()
                            moreIcon.checked = false
                        }
                    }

                    RoundButton {
                        id: locationBtn

                        radius: mapControls.radius
                        Material.background: "#FFFFFF"
                        Layout.preferredWidth: 2 * mapControls.radius
                        Layout.preferredHeight: Layout.preferredWidth
                        //checkable: true

                        contentItem: Image {
                            id: locationImg
                            source: "../../MapViewer/images/location.png"
                            width: mapControls.radius
                            height: mapControls.radius
                            mipmap: true
                        }
                        ColorOverlay{
                            anchors.fill: locationImg
                            source: locationImg
                            color: mapView.devicePositionSource.active  ? "steelBlue" : colors.blk_200
                        }
                        onClicked: {
                            pageView.hidePanelItem()
                            mapView.distanceLineGraphicsOverlay.graphics.clear()
                            mapView.showCurrentLocationsOptionsInBottomSheet()
                        }
                    }


                    RoundButton {
                        radius: mapControls.radius
                        opacity: mapView.mapRotation ? 1 : 0
                        rotation: mapView.mapRotation
                        Material.background: "transparent"//"#FFFFFF"
                        Layout.preferredWidth: 2 * mapControls.radius
                        Layout.preferredHeight: Layout.preferredWidth
                        contentItem: Image {
                            id: compassImg
                            source:"../../MapViewer/images/compass.png"
                            anchors {
                                fill: parent
                                margins: 0.4 * parent.padding
                            }
                            mipmap: true
                        }
                        onClicked: {
                            mapView.setViewpointRotation(mapView.initialMapRotation)
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }


                function getXYFromPolyline(startPoint,measure)
                {
                    //get the Polyline
                    let feature = mapView.identifyProperties.features[mapView.currentFeatureIndexForElevation]


                }



                function showDialogAndZoomToCurrentLocation()
                {
                    app.messageDialog.connectToAccepted(function () {

                        mapView.clearSearch()
                        mapView.panToLocation()

                    })

                    app.messageDialog.connectToRejected(function(){
                        mapView.zoomToLocation()

                    }
                    )

                    var title = ""
                    var message = "Do you want to perform a search using the currentLocation?"
                    if (!title || !message) {
                        message = message ? message : title
                        title = ""
                    }
                    app.messageDialog.standardButtons = Dialog.Yes | Dialog.No
                    app.messageDialog.show (title, message)

                }

                function showCurrentLocationsOptionsInBottomSheet(){
                    // Loader QMLtype to dynamically load the Navigation bottom sheet into the directions page
                    let navigationShareSheetLoader = nearbyMapPageNavSheetLoader

                    navigationShareSheetLoader.source = "./NavigationShareSheet.qml";

                    // Getting the item from the dynamically loaded page to initialize UI and functionality
                    let navigationShareSheet = navigationShareSheetLoader.item;

                    // resets the settings in the navigation bottom sheet
                    navigationShareSheet.clearSettings();

                    // Settings UI properties to display the navigationShareSheet

                    navigationShareSheet.maximumHeight = app.height;
                    navigationShareSheet.sheetTitle = strings.choose_options
                    navigationShareSheet.iconColor = colors.primary_color;

                    // Settings the strings, onClick function for each item in the List model for the bottom sheet
                    navigationShareSheet.listModel.append({ isColorOverlay: true, itemLabel:strings.zoom_current_location_search , itemEnabled: true });

                    navigationShareSheet.functions.push(() => {
                                                            mapView.clearSearch()
                                                            pageView.hidePanelItem()
                                                            pageView.hideSearchItem()
                                                            locationBtn.checked = true
                                                            searchBufferBtn.checked = false
                                                            mapView.panToLocation()
                                                            mapView.selectedSearchOption = NearbyMapPage.SearchOption.CurrentLocation
                                                        })

                    navigationShareSheet.listModel.append({ isColorOverlay: true, itemLabel:strings.zoom_current_location , itemEnabled: true });

                    navigationShareSheet.functions.push(() => {
                                                            mapView.zoomToLocation()
                                                            if(!searchBufferBtn.checked && !searchCurrentLocationBtn.checked)
                                                            searchBufferBtn.checked = true

                                                            locationBtn.checked = true

                                                            mapView.selectedSearchOption = NearbyMapPage.SearchOption.TapAtPoint
                                                        })

                    if(!mapView.locationDisplay.started)
                        navigationShareSheet.listModel.append({ isColorOverlay: true, itemLabel:strings.on , itemEnabled: true });
                    else
                        navigationShareSheet.listModel.append({ isColorOverlay: true, itemLabel:strings.off , itemEnabled: true });

                    navigationShareSheet.functions.push(() => {
                                                            if (!mapView.locationDisplay.started){
                                                                locationBtn.checked = true
                                                                mapView.locationDisplay.start()
                                                            } else{
                                                                mapView.locationDisplay.stop()
                                                                locationBtn.checked = false
                                                                mapView.selectedSearchDistanceMode = "bufferCenter"
                                                            }
                                                            mapView.selectedSearchOption = NearbyMapPage.SearchOption.TapAtPoint
                                                            navigationShareSheet.hideSheet();

                                                        })

                    // function that opens the bottom sheet
                    navigationShareSheet.displaySheet();

                }



                function zoomToCurrentLocation(){
                    if ( !((Qt.platform.os === "ios") || (Qt.platform.os == "android")) )
                        showDialogAndZoomToCurrentLocation()
                    else {
                        if (Permission.checkPermission(Permission.PermissionTypeLocationWhenInUse) === Permission.PermissionResultGranted){
                            showDialogAndZoomToCurrentLocation()
                        } else{
                            permissionDialog.permission = PermissionDialog.PermissionDialogTypeLocationWhenInUse;
                            permissionDialog.open()
                        }
                    }
                }

                function zoomToLocation()
                {
                    if (!mapView.locationDisplay.started) {

                        mapView.locationDisplay.start()
                        mapView.locationDisplay.autoPanMode = Enums.LocationDisplayAutoPanModeRecenter
                    }
                    else
                    {
                        mapView.locationDisplay.autoPanMode = Enums.LocationDisplayAutoPanModeRecenter
                    }

                    /* else {
                        mapView.locationDisplay.stop()
                    }*/
                }

                function panToLocation()
                {
                    if (!mapView.locationDisplay.started) {
                        mapView.locationDisplay.start()
                        mapView.locationDisplay.locationChanged.connect(searchFeaturesAtCurrentExtent)
                    }
                    else {
                        searchFeaturesAtCurrentExtent()
                    }

                }

                function searchFeaturesAtCurrentExtent()
                {
                    let myLocation = mapView.locationDisplay.location.position
                    let myLocation_projected = GeometryEngine.project(myLocation, mapView.map.spatialReference)
                    let isCurrentLocationInsideHomeExtent = true
                    //mapView.isInSearchMode = true
                    mapView.locationDisplay.locationChanged.disconnect(searchFeaturesAtCurrentExtent)

                    if(mapProperties.isMapArea)
                    {
                        let homeExtent = mapView.map.initialViewpoint.extent
                        isCurrentLocationInsideHomeExtent = GeometryEngine.contains(homeExtent, myLocation_projected)
                        if(!isCurrentLocationInsideHomeExtent)
                        {
                            toastMessage.show(strings.location_outside_mapExtent)
                        }

                    }
                    if(!mapProperties.isMapArea || isCurrentLocationInsideHomeExtent)
                    {

                        mapView.setViewpointCenterAndScale(myLocation,mapView.scale)

                        mapView.setViewpointCompleted.connect(doSearch)

                    }

                }

                function doSearch(succeeded)
                {
                    notificationToolTipOnStart.contentText = ""
                    mapView.isInSearchMode = true
                    if(succeeded){
                        mapView.setViewpointCompleted.disconnect(doSearch)
                        if(!isBufferSearchEnabled){
                            if(mapView.layerSpatialSearch.length > 0) //if have the configuration have lookupLayers, search in the layerSpatialSearch array
                                mapView.findFeaturesInMapExtent(mapView.layerSpatialSearch);
                            else { //do not have lookuplayers in configuration
                                mapView.findFeaturesInMapExtent();
                            }
                        }
                        else
                        {
                            mapView.searchAtMyCurrentLocation()
                        }
                    }


                }


                function getCurrentLocation() {
                    if(mapView.locationDisplay.location){
                        let myLocationPoint = mapView.locationDisplay.mapLocation;
                        return myLocationPoint;
                    }
                    return null;
                }

                function screenRatio() {
                    let width = mapView.widthInPixels
                    let height = mapView.heightInPixels
                    return height > width ? width / height : height / width;
                }

                PermissionDialog {
                    id:permissionDialog
                    openSettingsWhenDenied: true

                    onRejected:{}
                    onAccepted:{}
                }

                locationDisplay {
                    dataSource: DefaultLocationDataSource { //Set the dataSource property inside locationDisplay qmlProperty of MapView QML type
                        id: defaultLocationDataSource
                    }
                }

                SimpleFillSymbol {
                    id: simpleFillSymbol
                    color: "transparent"
                    style: Enums.SimpleFillSymbolStyleSolid

                    SimpleLineSymbol {
                        style: Enums.SimpleLineSymbolStyleSolid
                        color: "cyan"
                        width: app.units(2)
                    }
                }
                SimpleFillSymbol {
                    id: simpleMapAreaFillSymbol
                    color: "transparent"
                    style: Enums.SimpleFillSymbolStyleSolid

                    SimpleLineSymbol {
                        style: Enums.SimpleLineSymbolStyleSolid
                        color: "black"
                        width: app.units(2)
                    }
                }

                SimpleLineSymbol {
                    id: simpleLineSymbol

                    style: Enums.SimpleLineSymbolStyleSolid
                    color: "cyan"
                    width: app.units(2)
                }

                GraphicsOverlay{
                    id: spatialQueryGraphicsOverlay
                }

                GraphicsOverlay{
                    id: polygonGraphicsOverlay
                }

                GraphicsOverlay{
                    id: pointGraphicsOverlay


                }
                GraphicsOverlay{
                    id: elevationpointGraphicsOverlay


                }

                GraphicsOverlay {
                    id: lineGraphicsOverlay
                }


                GraphicsOverlay {
                    id: distanceGraphicsOverlay
                    // popupEnabled: true
                    visible: !isInRouteMode

                    SimpleRenderer{
                        SimpleLineSymbol {
                            id: distancelineSymbol
                            color: "cyan"//mapView.routeColor
                            style: Enums.SimpleLineSymbolStyleDash
                            width: 3
                        }
                    }
                }

                GraphicsOverlay {
                    id:routeGraphicsOverlay
                    SimpleRenderer {
                        SimpleLineSymbol {
                            id: lineSymbol

                            color: "#3588D4"
                            style: Enums.SimpleLineSymbolStyleSolid
                            width: 6
                        }
                    }
                    renderingMode: Enums.GraphicsRenderingModeStatic
                }

                GraphicsOverlay{
                    id:routePartGraphicsOverlay

                    SimpleRenderer {
                        SimpleLineSymbol {
                            id: routelineSymbol

                            color: mapView.routeColor
                            style: Enums.SimpleLineSymbolStyleSolid
                            width: 5
                        }
                    }
                    renderingMode: Enums.GraphicsRenderingModeStatic

                }

                GraphicsOverlay {
                    id: placeSearchResult
                    SimpleRenderer {
                        PictureMarkerSymbol{
                            id:pic
                            width: app.units(24)
                            height: app.units(24)
                            url: "../../MapViewer/images/redPin.png" //mapView.searchSymbolUrl


                        }
                    }
                }

                PictureMarkerSymbol{
                    id:sym12
                    width: app.units(32)
                    height: app.units(32)
                    url: "../../MapViewer/images/button_current_location.png"
                }



                Timer{
                    id:elapsedTimer
                    interval:500
                    repeat:true
                    onTriggered:mapView.isZooming()
                }


                PictureMarkerSymbol {
                    id: basePictureMarkerSymbol
                    url: "../../MapViewer/images/pin.png"
                    opacity: 0.5
                    width: 20
                    height: 20

                }

                function searchAtMyCurrentLocation(){
                    let myLocation = mapView.getCurrentLocation()
                    mapView.selectedSearchDistanceMode = "currentLocation"
                    findFeaturesInBuffer(myLocation, mapView.bufferDistance, mapView.measureUnits, mapView.layerSpatialSearch)
                }



                function isZooming()
                {
                    if(mapView.mapScale !== scale)
                        scale = mapView.mapScale
                    else
                    {
                        elapsedTimer.stop()
                        legendManager.sortLegendContentByLyrIndex()
                        legendManager.sortLegendContent()
                    }
                }

                function updateContentListModel(layer, checked)
                {
                    for(var k=0;k<mapView.contentListModel.count;k++)
                    {
                        var item = mapView.contentListModel.get(k)
                        if(item.lyrname === layer.name)
                        {
                            mapView.contentListModel.set(k,{"checkBox":checked})
                            break;
                        }
                    }
                }

                function populateAttachments()
                {
                    var attachmentsRequested = 0
                    for(var feature of mapView.featuresModel.features){
                        //isGetAttachmentRunning = true
                        var attachmentListModel = feature.attachments;
                        if(attachmentListModel){

                            attachmentListModel.fetchAttachmentsStatusChanged.connect(function() {
                                if(attachmentListModel.fetchAttachmentsStatus === Enums.TaskStatusCompleted){
                                    attachmentsRequested +=1
                                    var element =  attachmentListModel.get(0)
                                    if(attachmentsRequested === mapView.featuresModel.count)
                                    {
                                        getAttachmentCompleted()
                                    }



                                }
                            }

                            )
                            attachmentListModel.fetchAttachments()

                        }

                    }
                }


                Timer {
                    id: mapLoadTimer

                    interval: 5000
                    running: false
                    repeat: true
                    onTriggered: {
                        if(!isJsonQueryFieldsPopulated)
                            populateJsonQueryFields()

                        isFiltersInitialized = true;

                        if(!isFetchedFeatures && isMapLoaded && !layerManager.fetchingFeatures && !layerManager.fetchingLayers)
                        {
                            layerManager.mapView = mapView

                            layersWithAttachments = layerManager.getLayerNamesWithAttachmentsEnabled(app.urlParameters.layerid)

                        }
                        else{
                            mapLoadTimer.stop()
                            mapView.populateOriginalLayerVisibility()
                        }
                    }
                }

                function processLoadStatusChange () {
                    switch (mapView.map.loadStatus) {
                    case Enums.LoadStatusLoaded:
                        legendManager.mapView = mapView
                        relatedRecordsManager.mapView = mapView
                        mapUnitsManager.mapView = mapView
                        layerManager.mapView = mapView
                        legendManager.updateLayers()
                        mapView.updateMapInfo()
                        isMapLoaded = true
                        layerManager.mapView = mapView
                        mapView.mapReadyCount += 1

                        if (mapView && mapView.map) {
                            if(mapView && mapView.map && mapView.map.initialViewpoint)
                            {
                                var mapExtent = ArcGISRuntimeEnvironment.createObject("EnvelopeBuilder", { geometry: mapView.map.initialViewpoint.extent })
                                mapView.center = mapExtent.center
                            }
                        }

                        var layerList = mapView.map.operationalLayers

                        if(layerList.count > 0){
                            readAppConfigJson()
                        }

                        mapView.populateOriginalLayerVisibility()
                        mapLoadTimer.start()
                        break
                    }
                }

                function processLoadErrorChange () {
                    app.messageDialog.connectToAccepted(function () {
                        if (mapView) {
                            if (mapView.map.loadStatus !== Enums.loadStatusLoaded) {
                                previous()
                            }
                        }
                    })
                    var title = mapView.map.loadError.message
                    var message = mapView.map.loadError.additionalMessage
                    if (!title || !message) {
                        message = message ? message : title
                        title = ""
                    }
                    app.messageDialog.show (title, message)
                }

                function populateOriginalLayerVisibilityOfGroupLayer(grplayer)
                {
                    for(let k=0;k<grplayer.subLayerContents.length;k++)
                    {
                        let sublyr = grplayer.subLayerContents[k]
                        if(sublyr.subLayerContents.length)
                            populateOriginalLayerVisibilityOfGroupLayer(sublyr)
                        else
                        {
                            if ( sublyr.layerId )
                                originalLayerVisibility[sublyr.layerId] = sublyr.visible
                        }
                    }

                }



                function populateOriginalLayerVisibility(){
                    if(Object.keys(originalLayerVisibility).length !== mapView.map.operationalLayers.count){
                        for ( let k = 0; k < mapView.map.operationalLayers.count; k++ ){
                            let lyr = mapView.map.operationalLayers.get(k)
                            if(lyr && lyr.objectType === "GroupLayer")
                            {
                                populateOriginalLayerVisibilityOfGroupLayer(lyr)
                            }
                            else
                            {

                                if ( lyr && lyr.layerId )
                                    originalLayerVisibility[lyr.layerId] = lyr.visible
                            }
                        }
                    }
                }

                function zoomToPoint (point, scale) {
                    if (!scale) scale = 10000
                    var centerPoint = GeometryEngine.project(point, mapView.spatialReference)
                    var viewPointCenter = ArcGISRuntimeEnvironment.createObject("ViewpointCenter", {center: centerPoint, targetScale: scale})
                    mapView.setViewpointWithAnimationCurve(viewPointCenter, 0.0, Enums.AnimationCurveEaseInOutCubic)

                }



                function zoomToExtent (envelope) {
                    var envBuilder = ArcGISRuntimeEnvironment.createObject("EnvelopeBuilder",{geometry:envelope,spatialReference:mapView.map.spatialReference})
                    envBuilder.expandByFactor(1.5)
                    var viewPointExtent = ArcGISRuntimeEnvironment.createObject("ViewpointExtent", {extent: envBuilder.geometry})
                    mapView.setViewpointWithAnimationCurve(viewPointExtent, 0.0, Enums.AnimationCurveEaseInOutCubic)

                }

                function showPin (point) {
                    hidePin(function () {
                        var graphic = ArcGISRuntimeEnvironment.createObject("Graphic", {geometry: point})
                        placeSearchResult.visible  = true
                        placeSearchResult.graphics.insert(0, graphic)

                    })
                }

                function hidePin (callback) {
                    placeSearchResult.visible = false
                    placeSearchResult.graphics.remove(0, 1)
                    if (callback) callback()
                }

                function showStartAndEndPoint(point1, point2){
                    var pictureMarkerSymbol = ArcGISRuntimeEnvironment.createObject("PictureMarkerSymbol", {width: app.units(32), height: app.units(32), url: "../images/pin.png"})
                    var graphic = ArcGISRuntimeEnvironment.createObject("Graphic", {geometry: point1, symbol: pictureMarkerSymbol})
                    var pictureMarkerSymbol2 = ArcGISRuntimeEnvironment.createObject("PictureMarkerSymbol", {width: app.units(32), height: app.units(32), url: "../images/start.png"})
                    var graphic2 = ArcGISRuntimeEnvironment.createObject("Graphic", {geometry: point2, symbol: pictureMarkerSymbol2})
                    placeSearchResult.visible  = true
                    placeSearchResult.graphics.append(graphic)
                    placeSearchResult.graphics.append(graphic2)

                }


                function getDetailValue () {
                    if (!mapView.map) return "";
                    var center = (mapView.currentViewpointCenter && mapView.currentViewpointCenter && mapView.map.loadStatus === Enums.LoadStatusLoaded) ?
                                CoordinateFormatter.toLatitudeLongitude(mapView.currentViewpointCenter.center, Enums.LatitudeLongitudeFormatDecimalDegrees, 3)
                              : "";//qsTr("No Location Available.");
                    if(captureType === "line"){
                        try { return polylineBuilder.geometry? Math.abs(GeometryEngine.lengthGeodetic(polylineBuilder.geometry, Enums.LinearUnitIdMeters, Enums.GeodeticCurveTypeGeodesic)):0;
                        } catch (err) {}
                    } else if(captureType === "area"){
                        try { return polygonBuilder.geometry? Math.abs(GeometryEngine.areaGeodetic(polygonBuilder.geometry, Enums.AreaUnitIdSquareMeters, Enums.GeodeticCurveTypeGeodesic)):0;
                        } catch (err) {}
                    }
                    return 0//center + ""
                }

                //-------------------------------------------------------------------------------------------------------

                Pane {
                    id: locationAccuracy

                    property string distanceUnit: Qt.locale().measurementSystem === Locale.MetricSystem ? strings.m : strings.ft
                    property real accuracy: Qt.locale().measurementSystem === Locale.MetricSystem ? mapView.devicePositionSource.position.horizontalAccuracy : 3.28084 * mapView.devicePositionSource.position.horizontalAccuracy
                    property real threshold: Qt.locale().measurementSystem === Locale.MetricSystem ? (50/3.28084) : 50
                    property var localeAccuracyStr: parseFloat(Math.round(accuracy.toFixed(1))).toLocaleString(Qt.locale())
                    visible: mapView.devicePositionSource.active && mapView.devicePositionSource.position.horizontalAccuracyValid && locationBtn.checked

                    padding: 0
                    Material.elevation: app.baseElevation + 2
                    width: accuracyLabel.contentWidth + 2 * app.defaultMargin ///2
                    height: accuracyLabel.height  + 2 * app.defaultMargin
                    background: Rectangle{
                        width:parent.width
                        height:parent.height
                        color:"transparent"

                        Rectangle {
                            width:parent.width - 2 * defaultMargin
                            height:parent.height - 2 * defaultMargin

                            anchors.centerIn: parent
                            radius: app.units(1)
                            color: locationAccuracy.accuracy <= locationAccuracy.threshold ? "green" : "red"
                        }
                    }
                    states: [
                        State {
                            name: "popupmode"
                            when:mapView.height > mapPage.height * 0.70
                            AnchorChanges {
                                target: locationAccuracy
                                anchors {
                                    top:parent.top
                                    left:parent.left

                                }

                            }
                        },
                        State {
                            name: "nonpopupmode"
                            when:mapView.height < mapPage.height * 0.70
                            AnchorChanges {
                                target: locationAccuracy
                                anchors {
                                    bottom:parent.bottom
                                    right: parent.right

                                }

                            }
                        }

                    ]


                    Controls.BaseText {
                        id: accuracyLabel

                        anchors.centerIn: parent
                        height: contentHeight
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        color: "#FFFFFF"
                        text: "±%L1 %L2".arg(locationAccuracy.localeAccuracyStr).arg(locationAccuracy.distanceUnit)
                        //text: "±%L1 %L2".arg(locationAccuracy.accuracy.toFixed(1)).arg(locationAccuracy.distanceUnit)
                        fontSizeMode: Text.HorizontalFit
                    }

                    MouseArea {
                        anchors.fill: parent
                        preventStealing: true
                        onClicked: {
                            mapView.locationDisplay.autoPanMode = Enums.LocationDisplayAutoPanModeRecenter
                        }
                    }
                }

                MeasurePanel {
                    id: measurePanel

                    onCameraClicked: {
                        screenShotsView.takeScreenShot()
                    }

                    onIsIdentifyModeChanged: {
                        if (isIdentifyMode) {
                            measureToolIcon.checked = false
                        }
                    }

                    z: parent.z + 2
                    states: [
                        State {
                            when: showMeasureTool && !measurePanel.isIdentifyMode
                            name: "MEASURE_MODE"

                            PropertyChanges {
                                target: mapPageHeader
                                y: -app.headerHeight
                            }

                            PropertyChanges {
                                target: undoRedoDraw
                                anchors.topMargin: app.defaultMargin
                            }

                            PropertyChanges {
                                target: measureToolTip
                                anchors.topMargin: app.defaultMargin + app.notchHeight
                            }

                            PropertyChanges {
                                target: placeSearchResult
                                visible: false
                            }
                        }
                    ]

                    onCopiedToClipboard: {
                        measureToast.show(qsTr("Copied to clipboard"), parent.height-measureToast.height-measurePanel.height )
                    }

                    onMeasurementUnitChanged: {
                        mapView.updateSegmentLengths()
                    }
                }

                Controls.ToastDialog {
                    id: measureToast
                    z: parent.z + 1
                    fromVar: parent.height
                    enter: Transition {
                        NumberAnimation { property: "y";easing.type:Easing.InOutQuad; from:measureToast.fromVar; to:measureToast.toVar}
                    }
                    exit:Transition {
                        NumberAnimation { property: "y";easing.type:Easing.InOutQuad; from:measureToast.toVar; to:measureToast.fromVar}
                    }
                }

                //------------------------------------------------------------------------------------------

                onViewpointChanged: {
                    mapUnitsManager.updateMapUnitsModel()
                    mapUnitsManager.updateGridModel()
                }

                onMouseClicked: {
                    if (mapView.map.loadStatus === Enums.LoadStatusLoaded) {
                        isIdentifyTool = true
                        moreIcon.checked = false
                        mapView.populateOriginalLayerVisibility()

                        // store the selected buffer point
                        mapView.selectedBufferPoint = mouse.mapPoint

                        if (mapView.featuresModel.features.length > 0){
                            identifyInProgress = true
                            identifyFeatures (mouse.x, mouse.y)
                        } else {
                            // Hide the panel page only in mobile (small) screen when panel is docked to the bottom
                            if ( !app.isLandscape ){
                                pageView.hidePanelItem();
                            }
                            if(isBufferSearchEnabled){
                                mapView.selectedSearchOption = NearbyMapPage.SearchOption.TapAtPoint
                                mapView.selectedSearchDistanceMode = "bufferCenter"
                                searchBufferBtn.checked = true
                                searchCurrentLocationBtn.checked = false
                                identifyInProgress = true
                                if (mapView.layerSpatialSearch.length > 0){
                                    //if have the configuration have lookupLayers, search in the layerSpatialSearch array
                                    findFeaturesInBuffer(selectedBufferPoint, mapView.bufferDistance, mapView.measureUnits, mapView.layerSpatialSearch);
                                } else {
                                    //do not have lookuplayers in configuration
                                    findFeaturesInBuffer(selectedBufferPoint, mapView.bufferDistance, mapView.measureUnits);
                                }
                            }
                        }
                    }
                }

                onIdentifyLayersStatusChanged: {
                    switch (identifyLayersStatus) {
                    case Enums.TaskStatusCompleted:
                        if (mapView.identifyLayersResults.length) {
                            populateIdentifyProperties(mapView.identifyLayersResults)
                        } else{
                            identifyInProgress = false
                        }
                        break
                    }
                }

                function cancelAllTasks () {
                    for (var i=0; i<mapView.tasksInProgress.length; i++) {
                        mapView.cancelTask(mapView.tasksInProgress[i])
                    }
                    mapView.tasksInProgress = []
                }

                function loadFeatureAndPopulateFromMedia(feature,attachments)
                {
                    if (feature.loadStatus === Enums.LoadStatusLoaded)
                    {
                        currentSelectedFeature = feature
                        mapView.populateIdentifyFromMedia(feature,attachments)
                    }
                    else
                    {

                        feature.loadStatusChanged.connect(function(){
                            if (feature.loadStatus === Enums.LoadStatusLoaded) {
                                currentSelectedFeature = feature
                                mapView.populateIdentifyFromMedia(feature,attachments)


                            }
                        })
                        feature.load()
                    }
                }

                function populateIdentifyFromMedia(feature,attachments)
                {
                    mapView.identifyProperties.reset()

                    let featureTable = feature.featureTable
                    let popupDefinition = ""

                    popupDefinition = featureTable.layer.popupDefinition

                    let popUp = ArcGISRuntimeEnvironment.createObject("Popup", {initGeoElement: feature, initPopupDefinition: popupDefinition})
                    let popupManager = ArcGISRuntimeEnvironment.createObject("PopupManager", {popup: popUp})

                    popupManager.objectName = featureTable.layer.name

                    mapView.identifyProperties.popupManagers.push(popupManager)

                    mapView.identifyProperties.popupDefinitions.push(popupDefinition)
                    var fields = popupDefinition.fields
                    var visibleFieldList = []

                    for(var k=0;k<fields.length;k++)
                    {
                        if(fields[k].visible)
                            visibleFieldList.push(fields[k])
                    }

                    mapView.identifyProperties.fields.push(visibleFieldList)

                    mapView.identifyProperties.features.push(feature)
                    if(attachments)
                    {

                        mapView.identifyProperties.attachments.push(attachments)
                    }
                    identifyProperties.computeCounts()

                    if (mapView.identifyProperties.features.length)
                    {
                        if(featureTable.layer)
                        {

                            mapView.identifyProperties.highlightInMap(featureTable.layer,feature,false)
                            mapPageCarouselView.currentIndex = mapPage.currentSelectedIndex
                        }
                        else
                        {
                            //get the layer
                            for(var k1=0;k1<mapView.map.operationalLayers.count;k1++)
                            {
                                let lyr = mapView.map.operationalLayers.get(k1)
                                if(lyr.name === layerName)
                                {
                                    mapView.identifyProperties.highlightInMap(lyr,feature,false)
                                    mapPageCarouselView.currentIndex = mapPage.currentSelectedIndex
                                    break

                                }
                            }

                        }
                    }


                }

                function queryAttachments(featurecount)
                {

                    isGetAttachmentRunning = true
                    var attachmentListModel = mapView.identifyProperties.features[featurecount].attachments;
                    if(attachmentListModel){
                        attachmentListModel.fetchAttachmentsStatusChanged.connect(function() {
                            if(attachmentListModel.fetchAttachmentsStatus === Enums.TaskStatusCompleted){

                                if(attachmentListModel.count > 0)
                                {
                                    isAttachmentPresent = true
                                    getAttachmentCompleted()
                                }

                                getAttachmentCompleted()


                            }
                        }

                        )
                        attachmentListModel.fetchAttachments()

                    }
                    else
                        getAttachmentCompleted()

                }

                function populateIdentifyProperties (identifyLayerResults) {

                    isAttachmentPresent = false
                    attachqueryno = 0
                    var features = []
                    mapView.identifyProperties.relatedFeatures = []

                    var identifyLayerResult = identifyLayerResults[0],
                    hasSubLayerResults = false
                    try {
                        hasSubLayerResults = identifyLayerResult.sublayerResults &&
                                identifyLayerResult.sublayerResults.length
                    } catch (err) {}

                    if (hasSubLayerResults) {
                        populateIdentifyProperties(identifyLayerResult.sublayerResults)
                    } else {

                        var uniqueFieldName = getUniqueFieldName(identifyLayerResult.layerContent.featureTable);
                        var layerId = identifyLayerResult.layerContent.layerId
                        for (var j=0; j<identifyLayerResult.geoElements.length; j++) {

                            var feature = identifyLayerResult.geoElements[j];

                            var key ="%1_%2".arg(layerId).arg(feature.attributes.attributeValue(uniqueFieldName));

                            if (featureOIDDic[key] !== undefined)
                                mapPageCarouselView.identifyIndex = featureOIDDic[key];

                            identifyInProgress = false;
                        }

                    }
                }

                function populateRelatedRecords(features)
                {

                    if(features.length > 0)
                    {

                        var feature = features.pop()
                        var promiseToFindRelatedRecord = relatedRecordsManager.fetchRelatedRecords(feature)
                        promiseToFindRelatedRecord.then(isFetched => {
                                                            populateRelatedRecords(features)
                                                        })

                    }
                    else
                    {
                        identifyInProgress = false

                        identifyProperties.computeCounts()
                        showIdentifyPanel()
                        if (mapView.identifyProperties.features.length) mapView.identifyProperties.highlightFeature(0, true)

                    }

                }


                function showIdentifyPanel () {
                    if (mapView.identifyProperties.popupManagers.length) {
                        identifyInProgress = false;
                    }
                }

                function identifyFeatures (x, y, tolerance, returnPopupsOnly, maxResults) {
                    if (typeof tolerance === "undefined") tolerance = 10
                    if (typeof returnPopupsOnly === "undefined") returnPopupsOnly = false
                    if (typeof maxResults === "undefined") maxResults = 1

                    let id = mapView.identifyLayersWithMaxResults(x, y, tolerance, returnPopupsOnly, maxResults)
                    mapView.tasksInProgress.push(id)
                }


                //spatial query
                function queryLayers(spatialSearchLayers,lyrid,layersToSearch) {
                    if(!layersToSearch)
                        layersToSearch = [...spatialSearchLayers];
                    identifyInProgress = true;
                    if(!lyrid)
                        lyrid = layersToSearch.pop()

                    var promiseToQueryLayers =  new Promise((resolve, reject)=>{
                                                                queryLayer(lyrid,resolve);
                                                            });
                    promiseToQueryLayers.then(function(result){
                        //if have lookuplayers

                        //if not all the lookuplayers are searched
                        if(layersToSearch.length > 0 ) {

                            let nextlyrId = layersToSearch.pop();
                            queryLayers(spatialSearchLayers,nextlyrId,layersToSearch);
                        } else {
                            clearBtn.enabled = true
                            spatialQueryTimer.stop();
                            identifyInProgress = false;

                            //if results are not empty
                            if(mapView.featuresModel.features.length > 0){
                                mapView.featuresModel.sortByNumberAttribute("numericaldistance","desc")
                                mapPageCarouselView.currentIndex = 0;
                                mapPageCarouselView.highlightResult(mapView.featuresModel.get(0).initialIndex);
                                notificationToolTipOnStart.contentText = ""
                            } else {

                                mapPageCarouselItem.visible = false
                                mapView.searchText = ""
                                placeSearchResult.graphics.remove(0, 1)
                                mapView.geocodeModel.clearAll()
                                searchfeaturesModel.clearAll()
                                if(searchPageLoader && searchPageLoader.item)
                                {
                                    searchPageLoader.item.searchText = ""
                                    searchPageLoader.item.mapView.searchText = ""
                                    searchPageLoader.item.currentPlaceSearchText = ""
                                    searchPageLoader.item.searchResultTitleText = ""
                                    searchPageLoader.item.clearSearch()
                                }
                                mapView.identifyProperties.clearHighlight();
                                mapView.identifyProperties.clearHighlightInLayer();
                                if(mapView.featuresModel.searchMode === searchMode.spatial)
                                    mapView.clearSpatialSearch()
                                notificationToolTipOnStart.contentText = mapView.noResultsMessage > "" ? mapView.noResultsMessage : (isBufferSearchEnabled ?   strings.no_nearby_found : strings.no_results_found);
                            }

                            if ( !isFilterFinished ){
                                isFilterFinished = true;
                            }
                        }
                        //}


                    })
                }

                //Spatial query for a single layer
                function queryLayer(lyrid,resolve) {
                    if (lyrid === undefined) resolve();
                    else {
                        let layer =  layerManager.getLayerById(lyrid)

                        let lyrDefQuery = definitionQueryDic[layer.name];
                        if (lyrDefQuery === undefined)
                            definitionQueryDic[layer.name] = layer.definitionExpression;

                        // if((layer.layerType===Enums.LayerTypeRasterLayer) || (layer.layerType === Enums.LayerTypeArcGISTiledLayer))
                        //    resolve();
                        if(layer.loadStatus ===   Enums.LoadStatusLoaded){
                            let _table = layer.featureTable;

                            layer.definitionExpression = definitionQueryDic[layer.name];

                            var searchExpression = "";
                            if(filterLayersDic[layer.layerId] !== undefined){
                                for (var i=0 ; i< filterLayersDic[layer.layerId].count ; i++){
                                    var expression = filterLayersDic[layer.layerId].get(i);
                                    if(expression.isChecked) {

                                        //get the operator
                                        let operator = layerManager.getFilterOperatorFromConfig(layer.layerId)
                                        if(!operator)
                                            operator = " OR "
                                        if (searchExpression > "")
                                            searchExpression = `${searchExpression} ${operator} ${expression.definitionExpression}`
                                        else {
                                            searchExpression = expression.definitionExpression;
                                        }
                                    }
                                }
                            }

                            if(_table){
                                var uniqueFieldName = getUniqueFieldName(_table)
                                var promiseToQuery = queryFeatures(searchExpression, _table);
                                promiseToQuery.then(function(result){

                                    const features = Array.from(result.iterator.features);
                                    showSpatialFeatures(features,layer,uniqueFieldName);
                                    resolve();
                                }).catch(error => {
                                             console.error("error occurred",error.message)
                                             measureToast.toVar = parent.height - measureToast.height
                                             measureToast.show("%1:%2".arg(strings.error).arg(error.message), parent.height-measureToast.height, 1500)
                                             resolve();
                                         })
                            }
                            else{
                                resolve();
                            }
                        }
                        else
                            resolve()
                    }
                }

                function getUniqueFieldName(_table) {
                    let fields = _table.fields;
                    for(let k=0;k<fields.length;k++) {
                        let fldType = fields[k].fieldType;
                        if(fldType === Enums.FieldTypeOID)
                            return fields[k].name;
                    }
                    return null;
                }

                function getDistanceInMeters(realValue, fromUnit) {
                    switch (fromUnit) {
                    case measurePanel.lengthUnits.meters:
                        realValue = parseFloat(realValue)
                        return realValue
                    case measurePanel.lengthUnits.miles:
                        realValue = realValue * 1609.34
                        return realValue
                    case measurePanel.lengthUnits.kilometers:
                        return (realValue*1000)
                    case measurePanel.lengthUnits.feet:
                        return (realValue*0.3048)
                    case measurePanel.lengthUnits.feetUS:
                        return (realValue*0.3)
                    case measurePanel.lengthUnits.yards:
                        return (realValue*0.9144)
                    case measurePanel.lengthUnits.nauticalMiles:
                        return (realValue*1852)
                    default:
                        return realValue
                    }
                }

                //Calculate the geodetic distance of P1 and P2
                function getDistance (p1, p2) {
                    var results = GeometryEngine.distanceGeodetic(p1, p2, Enums.LinearUnitIdMeters, Enums.AngularUnitIdDegrees, Enums.GeodeticCurveTypeGeodesic)
                    return results.distance
                }

                function getSublyridFromGroupLayer(layer,lyrids)
                {

                    for(let k=0;k<layer.subLayerContents.length;k++)
                    {
                        let sublyr = layer.subLayerContents[k]
                        if(sublyr.subLayerContents.length)
                            getSublyridFromGroupLayer(sublyr,lyrids)
                        else
                        {
                            if (sublyr.layerId) {

                                lyrids.push(sublyr.layerId)
                            }
                        }
                    }



                }


                function getAllLayerids()
                {
                    let lyrids = []
                    for(let k=0;k<mapView.map.operationalLayers.count;k++)
                    {
                        let lyr = mapView.map.operationalLayers.get(k)
                        if(lyr.objectType === "GroupLayer")
                        {
                            getSublyridFromGroupLayer(lyr,lyrids)
                        }
                        else
                            lyrids.push(lyr.layerId)
                    }
                    return lyrids
                }

                function findFeaturesInMapExtent(spatialSearchLayers,canShowPin)
                {
                    var extent = mapView.currentViewpointExtent.extent
                    mapView.searchExtent = extent
                    if(!canShowPin)
                        canShowPin = true
                    spatialqueryParameters.geometry = extent
                    spatialqueryParameters.spatialRelationship = Enums.SpatialRelationshipContains//Enums.SpatialRelationshipIntersects

                    if(!spatialSearchLayers)
                        spatialSearchLayers = []

                    mapView.featuresModel.clearAll();
                    mapView.layerResults=[];
                    mapView.identifyProperties.reset();
                    featureOIDDic = ({});
                    mapView.selectedBufferPoint = extent.center
                    if(canShowPin)
                        mapView.showPin(mapView.selectedBufferPoint);

                    layersToSearch = [...spatialSearchLayers];

                    if(!layersToSearch)
                        layersToSearch = mapView.getAllLayerids()

                    let lyrid

                    if(layersToSearch.length > 0) {
                        lyrid = layersToSearch.pop();

                    }

                    mapView.featuresModel.searchMode = searchMode.spatial;
                    if(lyrid)
                        queryLayers(spatialSearchLayers,lyrid,layersToSearch);

                }

                function clearSearch()
                {

                    mapView.distanceLineGraphicsOverlay.graphics.clear()
                    if(isBufferSearchEnabled)
                        notificationToolTipOnStart.contentText = strings.search_notification_tooltip_on_start
                    else
                        notificationToolTipOnStart.contentText = strings.search_tooltip_on_search_by_extent
                    spatialQueryTimer.stop();
                    identifyInProgress = false;
                    mapPageCarouselItem.visible = false
                    mapView.searchText = ""
                    placeSearchResult.graphics.remove(0, 1)
                    mapView.geocodeModel.clearAll()
                    searchfeaturesModel.clearAll()
                    routeGraphicsOverlay.graphics.clear()
                    routePartGraphicsOverlay.graphics.clear()

                    if ( searchPageLoader && searchPageLoader.item ){
                        searchPageLoader.item.searchText = ""
                        searchPageLoader.item.mapView.searchText = ""
                        searchPageLoader.item.currentPlaceSearchText = ""
                        searchPageLoader.item.searchResultTitleText = ""
                        searchPageLoader.item.clearSearch()
                    }
                    mapView.identifyProperties.clearHighlight();
                    mapView.identifyProperties.clearHighlightInLayer();

                    if(mapView.featuresModel.searchMode === searchMode.spatial)
                        mapView.clearSpatialSearch()
                }


                //preparation function for spatial query
                function findFeaturesInBuffer(selectedPoint, bufferRadius,measurementUnits,spatialSearchLayers) {
                    if(!spatialSearchLayers)
                        spatialSearchLayers = [];

                    mapView.hidePin();
                    mapView.featuresModel.clearAll();
                    mapView.layerResults=[];
                    mapView.identifyProperties.reset();
                    featureOIDDic = ({});
                    isFilterFinished = false;

                    // Set the bufffer point in mapView for distance based sort and display
                    mapView.selectedBufferPoint = selectedPoint;

                    mapView.showPin(selectedPoint);

                    let pointGraphic = ArcGISRuntimeEnvironment.createObject("Graphic", {geometry: selectedPoint});
                    const bufferInMeters = getDistanceInMeters(bufferRadius, measurementUnits);

                    layersToSearch = [...spatialSearchLayers];
                    if(!layersToSearch || layersToSearch.length === 0)
                        layersToSearch = mapView.getAllLayerids()

                    let lyrid

                    mapView.featuresModel.searchMode = searchMode.spatial;

                    let bufferGeometry = GeometryEngine.bufferGeodetic(selectedPoint, bufferInMeters, Enums.LinearUnitIdMeters, NaN, Enums.geodesicCurveTypeGeodesic)

                    mapView.bufferGeometry = bufferGeometry;
                    drawBuffer(bufferGeometry);
                    spatialqueryParameters.geometry = bufferGeometry;
                    spatialqueryParameters.spatialRelationship = Enums.SpatialRelationshipIntersects;

                    queryLayers(spatialSearchLayers,lyrid,layersToSearch);
                }

                function resetDefinitionQuery(layer)
                {

                    if(layer && layer.layerId)
                        layer.visible = originalLayerVisibility[layer.layerId] !== undefined ? originalLayerVisibility[layer.layerId] : true

                    if(layer && layer.objectType === "FeatureLayer"){
                        if(definitionQueryDic[layer.name] > "")
                            layer.definitionExpression = definitionQueryDic[layer.name]
                        else
                            layer.definitionExpression = ""

                    }

                }

                function resetDefinitionQueryOfGroupLayer(grplayer)
                {
                    for(let k=0;k<grplayer.subLayerContents.length;k++)
                    {
                        let sublyr = grplayer.subLayerContents[k]
                        if(sublyr.subLayerContents.length)
                            resetDefinitionQueryOfGroupLayer(sublyr)
                        else
                        {
                            resetDefinitionQuery(sublyr)
                        }
                    }

                }

                //Clear spatial query results
                function clearSpatialSearch() {
                    isFilterFinished = false;
                    mapView.bufferGeometry = null
                    spatialQueryGraphicsOverlay.graphics.clear();
                    hidePin()
                    //clear the definition query of layers and set it to as initial

                    for(let k=0;k<mapView.map.operationalLayers.count;k++) {
                        let layer = mapView.map.operationalLayers.get(k);
                        if(layer && layer.objectType === "GroupLayer")
                        {
                            resetDefinitionQueryOfGroupLayer(layer)
                        }
                        else
                        {

                            resetDefinitionQuery(layer)


                        }

                    }
                    //apply the selected filters to the definition query
                    updateDefinitionQueryOfLayers(definitionQueryDic, null, true)

                    mapView.featuresModel.searchMode = searchMode.attribute;
                    mapView.featuresModel.clearAll();
                    mapView.layerResults = [];
                    mapView.identifyProperties.clearHighlight();
                    mapPageCarouselItem.visible = true
                }

                function setDefinitionExpression(layer, expression){

                    layer.definitionExpression = expression


                }




                //Calculate distance according to the measureUnits from configuration
                function getNewDistance(distance, measureUnits){
                    var newDistance = "";
                    switch(measureUnits){
                    case measurePanel.lengthUnits.meters:
                        newDistance =  parseFloat(distance.toFixed(2)).toLocaleString(Qt.locale());
                        break;
                    case measurePanel.lengthUnits.kilometers:
                        newDistance = parseFloat((distance*0.001).toFixed(2)).toLocaleString(Qt.locale());
                        break;
                    case measurePanel.lengthUnits.feet:
                        newDistance = parseFloat((distance*3.28083).toFixed(2)).toLocaleString(Qt.locale());
                        break;
                    case measurePanel.lengthUnits.miles:
                        newDistance = parseFloat((distance*0.000621371).toFixed(2)).toLocaleString(Qt.locale());
                        break;
                    default:
                        break;
                    }
                    return newDistance;
                }

                //Check whether the direction service is enabled for this layer
                function isDirectionLayer(currentLayer) {
                    var isDirEnabled = false;

                    if ( currentLayer.featureTable.geometryType === Enums.GeometryTypePoint ){
                        if ( mapView.layerDirection.length === 0 ) return true;
                        mapView.layerDirection.forEach(layerId => {
                                                           if ( layerId === currentLayer.layerId ){
                                                               isDirEnabled = true;
                                                               return true;
                                                           }
                                                       });
                    }

                    return isDirEnabled;
                }

                function canApplyFilter(layerid)
                {
                    let canFilter = false

                    if(mapView.featuresModel.count > 0)
                    {
                        if((mapView.layerSpatialSearch.length > 0))
                        {
                            //apply filter if not present in mapView.layerSpatialSearch
                            if(!mapView.layerSpatialSearch.includes(layerid))
                                canFilter = true

                        }


                    }
                    else
                    {
                        //apply filter on all the layers
                        canFilter = true


                    }
                    return canFilter

                }

                function updateDefinitionQueryOfLayers(definitionQueryDic,filterDic, applyFilter = false){
                    //check if the map-layer is part of the lookuplayers and  if(mapView.featuresModel.count > 0) then
                    //do not apply filters as they are applied when doing search
                    //else apply filters on other layers
                    if(Object.keys(mapView.filterLayersDic).length > 0){
                        for(let k in mapView.filterLayersDic){
                            let itemsConfigured =  mapView.filterLayersDic[k]
                            let lyrid = k
                            let needToApplyFilter = canApplyFilter(lyrid)
                            if(needToApplyFilter || applyFilter){
                                if(!layerManager.mapView)
                                    layerManager.mapView = mapView
                                let lyr = layerManager.getLayerById(k)
                                try{
                                    if(lyr){
                                        let lyrDefQuery = definitionQueryDic[lyr.name];
                                        if (lyrDefQuery === undefined)
                                            mapPage.definitionQueryDic[lyr.name] = lyr.definitionExpression;

                                        let defexpr = ""
                                        for(let x = 0;x < itemsConfigured.count; x++){
                                            var configObj = itemsConfigured.get(x)
                                            if(configObj.isChecked){
                                                //get the operator
                                                let operator = layerManager.getFilterOperatorFromConfig(k)
                                                if(!operator)
                                                    operator = " OR "

                                                if(defexpr > "")
                                                    defexpr += ` ${operator} `

                                                defexpr += `(${configObj.definitionExpression})`
                                            }
                                        }

                                        // if(lyr){
                                        //get the initial definition expression defined on the layer
                                        let initialDefinitionExpr = definitionQueryDic[lyr.name]
                                        if(initialDefinitionExpr > ""){
                                            if(defexpr > "")
                                                defexpr = `${initialDefinitionExpr} AND (${defexpr})`
                                            else
                                                defexpr = `${initialDefinitionExpr}`
                                        }
                                        lyr.visible = true
                                        setDefinitionExpression(lyr, defexpr)
                                        // }
                                    }
                                }
                                catch(ex)
                                {
                                    console.error(ex)
                                }
                            }
                        }
                    } else{
                        for(let k1=0;k1<mapView.map.operationalLayers.count;k1++) {
                            let layer = mapView.map.operationalLayers.get(k1);
                            try{
                                if(layer.objectType === "FeatureLayer"){
                                    let needToApplyFilter = canApplyFilter(layer.layerId)
                                    if(needToApplyFilter){
                                        if(mapPage.definitionQueryDic[layer.name] > "")
                                            layer.definitionExpression = definitionQueryDic[layer.name]
                                        else
                                            layer.definitionExpression = ""
                                    }

                                }
                                else
                                {
                                    if(layer.objectType === "GroupLayer")
                                    {
                                        resetDefExprForGroupLayer(layer)

                                    }
                                }
                            }
                            catch(ex)
                            {
                                console.error(ex)
                            }

                        }
                    }
                }


                function resetDefExprForGroupLayer(grpLayer)
                {
                    for(let k=0;k<grpLayer.subLayerContents.length;k++)
                    {
                        let sublyr = grpLayer.subLayerContents[k]
                        if(sublyr.subLayerContents.length)
                            resetDefExprForGroupLayer(sublyr)
                        else
                        {
                            if(sublyr.objectType === "FeatureLayer"){
                                let needToApplyFilter = canApplyFilter(sublyr.layerId)
                                if(needToApplyFilter){
                                    if(mapPage.definitionQueryDic[sublyr.name] > "")
                                        layer.definitionExpression = definitionQueryDic[sublyr.name]
                                    else
                                        layer.definitionExpression = ""
                                }
                            }
                        }
                    }
                }

                //Save results
                function showSpatialFeatures(features,layer,_field) {

                    var inputFeatures = features;
                    if(features.length > 0){
                        layer.visible = true;

                        var displayFieldName = features[0].featureTable.layerInfo.displayFieldName ? features[0].featureTable.layerInfo.displayFieldName : _field

                        var isDirLyr = isDirectionLayer(layer);
                        if(_field){
                            var featureids = inputFeatures.map(obj => obj.attributes.attributeValue(_field));

                            var component = featuresTempModelComponent;
                            var featuresTempModel = component.createObject(parent);
                            inputFeatures.forEach(feature =>{
                                                      var popupDefinition
                                                      if(feature.featureTable)
                                                      popupDefinition = feature.featureTable.popupDefinition;
                                                      if(!popupDefinition)
                                                      popupDefinition = ArcGISRuntimeEnvironment.createObject("PopupDefinition", {initGeoElement: feature});

                                                      var popUp = ArcGISRuntimeEnvironment.createObject("Popup", {initGeoElement: feature, initPopupDefinition: popupDefinition});
                                                      var popupManager = ArcGISRuntimeEnvironment.createObject("PopupManager", {popup: popUp});
                                                      popupManager.objectName = layer.name;

                                                      mapView.identifyProperties.popupManagers.push(popupManager);
                                                      mapView.identifyProperties.popupDefinitions.push(popupDefinition);

                                                      var newDistance = "0";
                                                      var distance = 0
                                                      if(!mapView.selectedBufferPoint)
                                                      {

                                                          if(mapView.map.initialViewpoint)
                                                          {
                                                              let mapExtent = GeometryEngine.project(mapView.map.initialViewpoint.extent, mapView.map.spatialReference)
                                                              mapView.selectedBufferPoint = mapExtent.center

                                                          }


                                                      }

                                                      if(feature.geometry.geometryType === Enums.GeometryTypePoint){
                                                          distance = getDistance(mapView.selectedBufferPoint, feature.geometry);
                                                          newDistance = getNewDistance(distance, mapView.measureUnits);
                                                      }
                                                      else if(feature.geometry.geometryType === Enums.GeometryTypePolygon || feature.geometry.geometryType === Enums.GeometryTypePolyline)
                                                      {

                                                          let centerPointOfFeature = feature.geometry.extent.center
                                                          distance = getDistance(mapView.selectedBufferPoint, centerPointOfFeature);
                                                          newDistance = getNewDistance(distance, mapView.measureUnits);
                                                      }


                                                      mapView.featuresModel.append({
                                                                                       "layerId": layer.layerId,
                                                                                       "layerName": layer.name,
                                                                                       "search_attr": popupManager.title,
                                                                                       "extent": feature.geometry,
                                                                                       "showInView": false,
                                                                                       "initialIndex": mapView.featuresModel.features.length,
                                                                                       "hasNavigationInfo": false,
                                                                                       "numericaldistance":distance.toFixed(2),
                                                                                       "distance":newDistance,
                                                                                       "isDirLyr":isDirLyr,
                                                                                       "geometryType":feature.geometry.geometryType
                                                                                   });

                                                      featuresTempModel.append({
                                                                                   "layerId": layer.layerId,
                                                                                   "layerName": layer.name,
                                                                                   "search_attr": popupManager.title,
                                                                                   "extent": feature.geometry,
                                                                                   "showInView": false,
                                                                                   "initialIndex": mapView.featuresModel.features.length,
                                                                                   "hasNavigationInfo": false,
                                                                                   "numericaldistance":distance.toFixed(2),
                                                                                   "distance":newDistance,
                                                                                   "isDirLyr":isDirLyr,
                                                                                   "geometryType":feature.geometry.geometryType
                                                                               });

                                                      var key = "%1_%2".arg(layer.layerId).arg(feature.attributes.attributeValue(_field))
                                                      featureOIDDic[key]=mapView.featuresModel.features.length;
                                                      var fields = popupDefinition.fields

                                                      var visibleFieldList = [];

                                                      for(var k=0;k<fields.length;k++) {
                                                          if(fields[k].visible)
                                                          visibleFieldList.push(fields[k])
                                                      }

                                                      mapView.identifyProperties.fields.push(visibleFieldList);

                                                      mapView.identifyProperties.features.push(feature);

                                                      mapView.featuresModel.features.push(feature);

                                                  })

                            //Sort results based on distance
                            featuresTempModel.sortByNumberAttribute("numericaldistance","desc")
                            //Push the results for the current layer to the array
                            mapView.layerResults.push(featuresTempModel);

                            var newexpr = "";

                            //set the definition query if part of lookuplayers or result layers
                            if((mapView.layerSpatialSearch.length > 0 && mapView.layerSpatialSearch.includes(layer.layerId)) || mapView.layerSpatialSearch.length === 0){
                                if(definitionQueryDic[layer.name])
                                    var existingExpr = definitionQueryDic[layer.name];
                                if(existingExpr  > "")
                                    newexpr =`${existingExpr} AND ${_field} IN (${featureids})`;
                                else
                                    newexpr =`${_field} IN (${featureids})`;

                                layer.definitionExpression = newexpr;
                            }
                        }
                    }
                    else {
                        if(mapView.layerSpatialSearch.includes(layer.layerId))
                        {
                            layer.visible = false;
                            //console.log("setting layerid false",layer.layerId)

                        }
                    }

                    listPage.bindModel();
                }

                function zoomToSpatialSearchLayer() {
                    var allFeatures = [];
                    mapView.featuresModel.features.forEach(feature =>{
                                                               allFeatures.push(feature.geometry);
                                                           })
                    var extent = GeometryEngine.combineExtentsOfGeometries(allFeatures);
                    var taskid =  mapView.setViewpointGeometryAndPadding(extent,100);
                    mapPageCarouselView.highlightResult(0);
                }

                function doIdentify() {
                    var screenPt = mapView.locationToScreen(mapView.currentViewpointCenter.center);
                    identifyFeatures (screenPt.x,screenPt.y);
                }

                function queryFeatures(searchString, table){
                    return new Promise((resolve, reject)=>{
                                           let taskId;
                                           if(searchString > ""){
                                               spatialqueryParameters.whereClause = searchString;
                                           } else{
                                               spatialqueryParameters.whereClause = "";
                                           }
                                           const featureStatusChanged = ()=> {
                                               switch (table.queryFeaturesStatus) {
                                                   case Enums.TaskStatusCompleted:
                                                   table.queryFeaturesStatusChanged.disconnect(featureStatusChanged);
                                                   const result = table.queryFeaturesResults[taskId];
                                                   if (result) {
                                                       resolve(result);
                                                   } else {
                                                       reject({message: "The query finished but there was no result for this taskId", taskId: taskId});
                                                   }
                                                   break;
                                                   case Enums.TaskStatusErrored:
                                                   table.queryFeaturesStatusChanged.disconnect(featureStatusChanged);
                                                   spatialqueryParameters.whereClause = "";
                                                   if (table.error) {
                                                       reject(table.error);
                                                   } else {
                                                       reject({message: table.tableName + ": query task errored++++"});
                                                   }
                                                   break;

                                                   default:
                                                   break;
                                               }
                                           }

                                           table.queryFeaturesStatusChanged.connect(featureStatusChanged);
                                           if(table.queryFeaturesWithFieldOptions)
                                           taskId = table.queryFeaturesWithFieldOptions(spatialqueryParameters, Enums.QueryFeatureFieldsLoadAll);
                                           else
                                           taskId = table.queryFeatures(spatialqueryParameters);

                                           spatialQueryTimer.currentTaskId = taskId;
                                           spatialQueryTimer.start();
                                       });
                }

                //draw the buffer geometry on the map
                function drawBuffer(bufferGeometry) {
                    spatialQueryGraphicsOverlay.graphics.clear()
                    var graphic = ArcGISRuntimeEnvironment.createObject("Graphic",
                                                                        {symbol: simpleFillSymbol, geometry: bufferGeometry})
                    spatialQueryGraphicsOverlay.graphics.append(graphic)

                    mapView.setViewpointGeometryAndPadding(spatialQueryGraphicsOverlay.extent,30)

                }





                //get layer index by layer index
                function getLayerIndexbyId(layerId) {
                    for (var i = 0 ; i < mapView.map.operationalLayers.count; i++) {
                        var lyr = mapView.map.operationalLayers.get(i);


                        if(lyr.layerId === layerId)
                            return i;

                    }
                }

                function updateMapInfo () {
                    if (!mapView.map) return
                    if (mapView.map.item) {
                        if (mapView.map.item.title) {
                            mapView.mapInfo.title = mapView.map.item.title
                        }
                        if (mapView.map.item.snippet) {
                            mapView.mapInfo.snippet = mapView.map.item.snippet
                        }
                        if (mapView.map.item.description) {
                            mapView.mapInfo.description = mapView.map.item.description
                        }
                    }
                }

                function currentCenter () {
                    var x = app.width/2
                    var y = (app.height - app.headerHeight)/2
                    return screenToLocation(x, y)
                }
            }


            //A 60 secs timer for user to cancel the spatial query when it takes too long to load
            Timer {
                id: spatialQueryTimer

                property var currentTaskId:""
                interval: 60000
                repeat: false
                onTriggered: {
                    mapPageCarouselItem.visible = false
                    mapView.searchText = ""
                    placeSearchResult.graphics.remove(0, 1)
                    mapView.geocodeModel.clearAll()
                    searchfeaturesModel.clearAll()

                    if ( searchPageLoader && searchPageLoader.item ){
                        searchPageLoader.item.searchText = ""
                        searchPageLoader.item.mapView.searchText = ""
                        searchPageLoader.item.currentPlaceSearchText = ""
                        searchPageLoader.item.searchResultTitleText = ""
                        searchPageLoader.item.clearSearch()
                    }

                    mapView.identifyProperties.clearHighlight();
                    mapView.identifyProperties.clearHighlightInLayer();
                    if(mapView.featuresModel.searchMode === searchMode.spatial)
                        mapView.clearSpatialSearch();
                    identifyInProgress = false;
                    measureToast.toVar = parent.height - measureToast.height;
                    measureToast.show(strings.search_time_out, parent.height-measureToast.height, 1500);
                }
            }

            states: [
                State{
                    name: "anchorrightNoPanel"
                    AnchorChanges {
                        target: searchDockItem
                        anchors.left: parent.left//parent.bottom
                        anchors.top:parent.top
                    }
                    PropertyChanges{
                        target: mapView

                        width:app.width // * 0.30
                        height:app.height - mapPageHeader.height

                    }
                    PropertyChanges{
                        target: searchDockItem
                        y:app.headerHeight - 10
                        x:0
                        //width:app.width * 0.35
                        height:pageView.height
                        color:"transparent"

                    }

                    PropertyChanges{
                        target: mapPageHeader
                        y:0
                        visible:true
                        height: app.headerHeight + app.notchHeight
                    }

                },
                State{
                    name: "anchorright"
                    AnchorChanges {
                        target: panelDockItem
                        anchors.left: parent.left
                    }
                    AnchorChanges {
                        target: searchDockItem
                        anchors.left: parent.left
                        anchors.top:parent.top
                    }
                    PropertyChanges{
                        target: pageView
                        width:app.width  * 0.65
                        height:app.height

                    }
                    PropertyChanges{
                        target: panelDockItem
                        y:app.headerHeight - 10
                        x:0
                        width:app.width * 0.35
                        height:pageView.height
                        color:"transparent"

                    }
                    PropertyChanges{
                        target: searchDockItem
                        y:app.headerHeight - 10
                        x:0
                        width:app.width * 0.35
                        height:pageView.height
                        color:"transparent"

                    }

                    PropertyChanges{
                        target: mapPageHeader
                        y:0
                        visible:true
                        height:app.headerHeight + app.notchHeight
                    }


                },
                State{
                    name: "anchorbottom"
                    AnchorChanges {
                        target: pageView
                        anchors.right: parent.right

                    }

                    AnchorChanges {
                        target: panelDockItem
                        anchors.bottom: parent.bottom//parent.bottom
                    }

                    PropertyChanges{
                        target: pageView
                        width:app.width

                    }

                    PropertyChanges{
                        target: mapPageHeader
                        y:0
                        visible:true
                        height: app.headerHeight + app.notchHeight
                    }

                    PropertyChanges{
                        target: panelDockItem
                        x:0
                        width:pageView.width
                        height:pageView.height * 0.4
                        color:"transparent"

                    }


                },
                State{
                    name: "anchorbottomReduced"
                    AnchorChanges {
                        target: mapView
                        anchors.top: parent.top
                    }

                    PropertyChanges {
                        target: mapView
                        x:0
                        width:pageView.width
                        height:pageView.height - app.units(50)//pageView.height * 0.4

                    }


                },
                State{
                    name: "anchortop"
                    AnchorChanges {
                        target: panelDockItem
                        anchors.top:parent.top//parent.bottom
                    }

                    AnchorChanges {
                        target: searchDockItem
                        anchors.top: parent.top
                    }

                    PropertyChanges{
                        target: panelDockItem
                        y:0//app.headerHeight - 10
                        x:0
                        width:mapPage.width
                        height:app.height//pageView.height
                        color:"transparent"

                    }

                    PropertyChanges {
                        target: searchDockItem
                        x:0

                        width:mapPage.width
                        height:app.height
                    }

                    PropertyChanges{
                        target: mapPageHeader
                        visible:false
                        height:0//app.headerHeight
                    }


                }
                ,

                State{
                    name: "anchorTopReduced"


                    AnchorChanges {
                        target: mapView
                        anchors.top: parent.top
                    }
                    AnchorChanges {
                        target: panelDockItem
                        anchors.bottom: parent.bottom
                    }
                    PropertyChanges {
                        target: mapView
                        x:0

                        width:mapPage.width
                        height:mapPage.height * 0.2


                    }


                    PropertyChanges {
                        target: panelDockItem
                        x:0
                        width:mapPage.width
                        height:mapPage.height * 0.8


                    }


                }

            ]

            function hidePanelItem(activeTool)
            {
                panelDockItem.removeDock()
                panelDockItem.visible = false
                if(filterIcon.checked) {
                    filterIcon.checked = false;
                }
                isInRouteMode = false
            }

            function hideSearchItem()
            {
                searchIcon.checked = false
            }


            //The bottom notification tooltip
            Pane {
                id: notificationToolTipOnStart

                property string contentText: isBufferSearchEnabled ? strings.search_notification_tooltip_on_start : strings.search_tooltip_on_search_by_extent
                width: Math.min((parent.width - 2 * app.defaultMargin), app.maximumScreenWidth)
                visible: isBufferSearchEnabled ? !(mapBusyIndicator.visible || clearBtn.visible )  && !isInRouteMode: notificationToolTipOnStart.contentText > ""


                anchors{
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                    bottomMargin: 24 * app.scaleFactor + ( app.isIphoneX ? app.heightOffset + app.defaultMargin : 0 )
                }

                background: Rectangle {
                    radius: 8 * app.scaleFactor
                    color: headerColor

                    layer.enabled: true
                    layer.effect: ElevationEffect {
                        elevation: 2
                    }
                }

                Label {
                    anchors.fill: parent

                    font.pixelSize: 14 * app.scaleFactor
                    font.family: "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                    font.bold: true
                    color: "white"

                    text: notificationToolTipOnStart.contentText
                    wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Label.AlignLeft
                }

            }

            //Carousel
            Rectangle{
                id: mapPageCarouselItem

                width: parent.width
                height: 160 * app.scaleFactor
                anchors.bottom: parent.bottom
                anchors.bottomMargin: app.defaultMargin + ( app.isIphoneX ? app.heightOffset + app.defaultMargin : 0 )
                anchors.margins: app.defaultMargin
                color:"transparent"
                visible:!isInRouteMode


                ListView {
                    id: mapPageCarouselView
                    signal makeFontBold(var selectedIndex)
                    //signal callDrawLine(var selectedIndex)


                    property bool busy: flicking || dragging
                    property int centerIndex: Math.round(contentX  / cellWidth)
                    property int cellWidth: Math.min((app.width - 4 * app.defaultMargin), 50 * app.baseUnit)
                    clip: true
                    model: mapView.featuresModel
                    anchors.fill: parent
                    anchors.bottomMargin: app.baseUnit
                    //boundsBehavior: Flickable.StopAtBounds
                    orientation: ListView.Horizontal
                    cacheBuffer:0

                    //new params
                    snapMode: ListView.SnapToItem
                    preferredHighlightBegin: mapPageCarouselView.width/2 - mapPageCarouselView.cellWidth * 0.5
                    preferredHighlightEnd: mapPageCarouselView.width/2 + mapPageCarouselView.cellWidth * 0.5  //this line means that the currently highlighted item will be central in the view
                    highlightRangeMode: ListView.StrictlyEnforceRange
                    highlightFollowsCurrentItem: true  //updates the current index property to match the currently highlighted item
                    highlightResizeDuration: 10
                    highlightResizeVelocity: 2000
                    highlightMoveVelocity: 2000
                    highlightMoveDuration: 10
                    property int identifyIndex:-1

                    delegate: CarouselDelegate {
                        width: mapPageCarouselView.cellWidth
                        height: 160 * app.scaleFactor
                        pageName:"map"


                        distanceToFeature: {
                            if(mapView.selectedSearchDistanceMode === "bufferCenter"){
                                return distance
                            } else{
                                let _feature = mapView.featuresModel.get(index)
                                if(_feature){
                                    let featureIndex = _feature.initialIndex//mapView.featuresModel.get(index).initialIndex
                                    let targetFeature = mapView.featuresModel.features[featureIndex]
                                    if(targetFeature){
                                        let centerPointOfFeature = targetFeature.geometry.extent.center
                                        let currentLocation  = mapView.locationDisplay.mapLocation
                                        let mydistance = mapView.getDistance(currentLocation, centerPointOfFeature);
                                        return mapView.getNewDistance(mydistance, mapView.measureUnits);
                                    }
                                }
                            }
                        }

                        onOpenElevationProfile: {
                            pageView.hideSearchItem()
                            let _featureIndex = mapView.featuresModel.get(index).initialIndex
                            let feature = mapView.identifyProperties.features[_featureIndex]

                            //highlight in map
                            mapView.currentFeatureIndexForElevation = _featureIndex
                            panelDockItem.addDock("elevationProfile")
                            mapView.identifyProperties.zoomToFeature(feature)
                        }



                        // Handles directions button onClick from CarouselDelegate in the NearbyMapPage
                        onOpenRoute:{
                            //mapView.canShowSearchDistanceControls = false
                            identifyPage.currentIndex = initialIndex
                            handleDirectionsOnClick("mapPage");
                        }

                        onOpenDetail:{
                            mapView.distanceLineGraphicsOverlay.graphics.clear()

                            mapPageCarouselView.selectFeature(index);

                            identifyPage.open();
                            moreIcon.checked = false
                            pageView.hideSearchItem()

                        }

                        onOpenDamage:{
                            let _featureIndex = mapView.featuresModel.get(index).initialIndex
                            let feature = mapView.identifyProperties.features[_featureIndex]

                            Qt.openUrlExternally(`https://survey123.arcgis.app/?itemID=e14c7ea7b7cf45bc92c5fe30b893437e&field:tree_id=` + feature.attributes.attributeValue("OBJECTID"))
                        }

                        onOpenCitSci:{
                            let _featureIndex = mapView.featuresModel.get(index).initialIndex
                            let feature = mapView.identifyProperties.features[_featureIndex]

                            Qt.openUrlExternally(`https://survey123.arcgis.app/?itemID=974149334df34fb992d76442789a394d&field:tree_id=` + feature.attributes.attributeValue("OBJECTID"))
                        }

                        onClearDistanceLine: {
                            mapView.distanceLineGraphicsOverlay.graphics.clear()

                        }

                        onDrawDistanceLine: {
                            mapView.distanceLineGraphicsOverlay.graphics.clear()
                            mapPageCarouselView.identifyIndex = initialIndex
                            mapPageCarouselView.showDistanceLine(`${distanceToFeature} ${mapView.measureUnitsString}`)

                        }



                    }

                    onMovementEnded: {

                        highlightResult(mapView.featuresModel.get(currentIndex).initialIndex);
                        mapView.distanceLineGraphicsOverlay.graphics.clear()
                    }

                    onIdentifyIndexChanged:{
                        currentIndex = mapView.featuresModel.getIndexByAttributes({"initialIndex":identifyIndex});
                        highlightResult(identifyIndex);
                        let geometryType = mapView.featuresModel.get(currentIndex).geometryType
                        if ( !(isElevationEnabled && geometryType === Enums.GeometryTypePolyline )){
                            if ( panelPageLoader.item ){
                                panelPageLoader.item.hidepanelPage()
                            }
                        } else{
                            //refresh chart if polyline and chart is open
                            mapView.distanceLineGraphicsOverlay.graphics.clear()
                            if(isElevationEnabled && geometryType === Enums.GeometryTypePolyline){
                                let _featureIndex = mapView.featuresModel.get(currentIndex).initialIndex
                                let feature = mapView.identifyProperties.features[_featureIndex]
                                mapView.currentFeatureIndexForElevation = _featureIndex
                            }
                        }

                    }

                    Behavior on contentX {
                        NumberAnimation {duration:0}
                    }

                    function showDistanceLine(distance)
                    {

                        mapView.distanceLineGraphicsOverlay.graphics.clear()

                        let feature = mapView.identifyProperties.features[identifyIndex]
                        if(feature)
                        {
                            let toPoint = feature.geometry
                            var polylinebuildr = ArcGISRuntimeEnvironment.createObject("PolylineBuilder",{spatialReference:mapView.spatialReference})

                            if(mapView.selectedSearchDistanceMode === "bufferCenter")
                                polylinebuildr.addPointXY(mapView.selectedBufferPoint.x,mapView.selectedBufferPoint.y)
                            else
                            {
                                let currentLocation  = mapView.locationDisplay.mapLocation
                                polylinebuildr.addPointXY(currentLocation.x,currentLocation.y)
                            }


                            if(toPoint.geometryType === Enums.GeometryTypePolygon || toPoint.geometryType === Enums.GeometryTypePolyline)
                            {
                                let centerpt = toPoint.extent.center
                                polylinebuildr.addPointXY(centerpt.x,centerpt.y)
                            }
                            else
                                polylinebuildr.addPointXY(toPoint.x,toPoint.y)

                            var distanceSegmentGraphic = ArcGISRuntimeEnvironment.createObject("Graphic", {geometry: polylinebuildr.geometry });
                            if(distance)
                                distanceSegmentGraphic.attributes.insertAttribute("distance", distance);
                            mapView.distanceLineGraphicsOverlay.graphics.append(distanceSegmentGraphic)
                            let combinedGeometry = []
                            combinedGeometry.push(distanceSegmentGraphic.geometry)
                            combinedGeometry.push(toPoint.geometry)
                            var combinedextent = GeometryEngine.combineExtentsOfGeometries(combinedGeometry);
                            mapView.setViewpointGeometryAndPadding(combinedextent,100)


                            //mapView.setViewpointGeometryAndPadding(distanceSegmentGraphic.geometry.extent,50)
                        }


                    }

                    function highlightResult(index){
                        var featObj = mapView.featuresModel.features[index]
                        var featureTable = featObj.featureTable
                        var feature = featObj
                        var layer = featureTable.layer
                        mapView.identifyProperties.highlightInMap(layer,feature, false);
                    }

                    function roundIt (cx) {
                        let dx = (cx % (cellWidth));
                        return cx - dx;
                    }

                    function centerCard(index){
                        mapPageCarouselView.contentX = index * cellWidth;
                    }

                    function selectFeature(featureIndex) {
                        mapPageCarouselView.currentIndex = featureIndex;
                        mapPageCarouselView.highlightResult(mapView.featuresModel.get(featureIndex).initialIndex);
                        identifyPage.currentIndex = mapView.featuresModel.get(featureIndex).initialIndex;

                        // Setting the current carousel index to the identifyPage to display "currentIndex of TotalIndex" in the header
                        identifyPage.listIndex = featureIndex;

                        // ------ Fetching attributes data from mapview ------

                        identifyPage.bindModel();

                        // ------ Fetching attachments from mapview ------

                        let feature = mapView.identifyProperties.features[identifyPage.currentIndex]
                        if(feature) {
                            identifyPage.bindAttachmentModel(feature)
                        }
                    }

                    // Handle previous and next button clicks from the IdentifyPage header to correspondinly show previous and next features
                    Connections {
                        target: identifyPage

                        function onPrevFeatureSelected(prevIndex){
                            mapPageCarouselView.selectFeature(prevIndex);
                        }

                        function onNextFeatureSelected(nextIndex){
                            mapPageCarouselView.selectFeature(nextIndex);
                        }
                    }
                }
            }

            //List Button
            RoundButton {
                radius: mapControls.radius
                Material.background: "#FFFFFF"
                anchors.bottom: mapPageCarouselItem.top
                anchors.bottomMargin:  app.baseUnit
                anchors.right: parent.right
                anchors.rightMargin: app.baseUnit
                width: 2 * mapControls.radius
                height: width

                visible: clearBtn.visible && clearBtn.text === strings.clear_search && mapView.featuresModel.count > 0

                contentItem: Image {
                    id: listBtn
                    source: "../../MapViewer/images/outline_list_white_48.png"
                    width: mapControls.radius
                    height: mapControls.radius
                    mipmap: true
                }

                ColorOverlay{
                    anchors.fill: listBtn
                    source: listBtn
                    color: colors.blk_200
                }

                onClicked: {
                    distanceGraphicsOverlay.graphics.clear()
                    listPage.open()
                }
            }

            //Clear Search Button
            RoundButton {
                id: clearBtn
                opacity: !isBufferSearchEnabled ? 1 : ((mapView.featuresModel.count > 0 && !isInRouteMode) ? 1 : 0)
                // opacity: !isBufferSearchEnabled ? 1 : (((mapView.featuresModel.count > 0 || mapView.bufferGeometry) && !isInRouteMode) ? 1 : 0)
                width: Math.min(implicitWidth, 30 * app.baseUnit + 2 * app.defaultMargin)
                height: 6 * app.baseUnit
                radius: 3 * app.baseUnit
                anchors.top: mapView.top
                anchors.topMargin: 4.5 * app.baseUnit
                anchors.horizontalCenter: parent.horizontalCenter
                text: !isBufferSearchEnabled  && mapView.featuresModel.count === 0   ? strings.search_this_area : strings.clear_search
                Material.foreground: mapPage.headerColor
                Material.background: "#FFFFFF"
                Material.elevation: 2
                visible:identifyInProgress === true || text === "" ? false : (opacity > 0?true:false)


                contentItem: Text {
                    text: clearBtn.text
                    font.family: "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                    font.pixelSize: 14 * app.scaleFactor
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: colors.blk_200
                    padding: app.defaultMargin
                    elide: Text.ElideRight
                }

                onClicked: {
                    elevationpointGraphicsOverlay.graphics.clear()
                    if(clearBtn.text ===  strings.search_this_area)
                    {
                        mapView.isInSearchMode = true
                        notificationToolTipOnStart.contentText = ""
                        if(mapView.layerSpatialSearch.length > 0) //if have the configuration have lookupLayers, search in the layerSpatialSearch array
                            mapView.findFeaturesInMapExtent(mapView.layerSpatialSearch);
                        else { //do not have lookuplayers in configuration
                            let _maplayers = []

                            mapView.findFeaturesInMapExtent();
                        }

                    } else{
                        mapView.clearSearch()
                        mapView.isInSearchMode = false
                    }
                }

                Behavior on opacity {
                    NumberAnimation { duration : 250 }
                }
            }
            //

        }

        //search dockitem

        Rectangle{
            id:searchDockItem
            width:parent.width//mapPage.state === "anchortop"?app.width :app.width * 0.35//parent.width //* 0.35
            height:app.height //+ 200//parent.height
            visible:false
            //y:200


            property int floatingWidth: 100
            property int floatingHeight: 100

            Drag.active: dragArea2.drag.active
            Drag.hotSpot.x:100

            MouseArea {

                id: dragArea2
                anchors.fill: parent
                enabled:pageView.state !== "anchorbottom"

                drag.target: isLandscape ? searchDockItem:null
                onPressed: {
                    if (!searchDockItem.anchors.fill) {
                        searchDockItem.floatingWidth = searchDockItem.width;
                        searchDockItem.floatingHeight = searchDockItem.height;
                    }
                    searchDockItem.anchors.fill = null;
                    searchDockItem.width = floatingWidth;
                    searchDockItem.height = floatingHeight;
                    let mousePos = searchDockItem.mapToItem(searchDockItem.parent, mouseX, mouseY);
                    searchDockItem.x = mousePos.x - searchDockItem.width / 2;
                    searchDockItem.y = mousePos.y - searchDockItem.height / 2;
                    searchDockItem.z = Date.now();
                }

                onReleased: {
                    if( isLandscape )
                    {

                        searchDockItem.y=0
                        if(searchDockItem.x > parent.width/2)
                        {
                            searchDockItem.x = mapView.width
                            mapPage.state = "anchorleft"

                        }
                        else
                        {
                            searchDockItem.x = 0
                            mapPage.state = "anchorright"
                        }
                    }

                }
            }

            property alias searchItemLoader: searchPageLoader.item

            Loader{
                id:searchPageLoader

                anchors.fill:parent

                onLoaded: {
                    item.mapView = mapView
                    item.searchText = mapView.searchText
                    item.currentPlaceSearchText = mapView.searchText
                    item.currentFeatureSearchText = mapView.searchText

                    if(mapView.activeSearchTab.toUpperCase() === app.tabNames.kPlaces){
                        item.makePlaceSearchTabActive()
                        item.tabBar.currentIndex = 0
                    } else{
                        item.tabBar.currentIndex = 1
                    }

                    item.visible = true
                    item.isLoaded = true
                }
            }

            Connections {
                target: searchPageLoader.item
                function onHideSearchPage() {
                    mapView.searchText = searchPageLoader.item.searchText
                    mapView.activeSearchTab = searchPageLoader.item.activeTab
                    searchIcon.checked = false
                    searchDockItem.removeDock()
                }


                function onVisibleChanged() {
                    let hasPermission = app.isDesktop ? Permission.checkPermission(Permission.PermissionTypeLocationWhenInUse) === Permission.PermissionResultUnknown : Permission.checkPermission(Permission.PermissionTypeLocationWhenInUse) === Permission.PermissionResultGranted;
                    app.hasLocationPermission = hasPermission;

                    if (!searchPageLoader.item.visible) {
                        if (searchPageLoader.item.sizeState === "") {
                            mapPage.header.y = - ( app.headerHeight + app.notchHeight )
                        }
                        searchIcon.checked = false
                    } else {
                        if (searchPageLoader.item.sizeState === "") { mapPage.header.y = - app.headerHeight }
                    }
                }

                function onSizeStateChanged() {
                    if (searchPageLoader.item.sizeState === "" && measurePanel.state !== 'MEASURE_MODE') {
                        if (!visible) {
                            mapPage.header.y = 0
                        } else {
                            mapPage.header.y = - ( app.headerHeight + app.notchHeight )
                        }
                    }
                }


                function onDockToLeft() {
                    if ( searchPageLoader.visible ) {
                        if(app.isLandscape)
                            pageView.state = "anchorright"
                    }
                }

                function onDockToTop() {
                    pageView.state = "anchortop"
                }

                function onDockToBottom() {
                    searchDockItem.dockToBottom()
                }
            }

            function dockToBottomReduced()
            {
                mapPage.state = "anchorbottomReduced"

            }
            function screenRatio()
            {
                let width = mapView.widthInPixels
                let height = mapView.heightInPixels
                return height > width ? width/height :height/width
            }

            function dockToBottom()
            {
                pageView.state = "anchorbottom"
                Qt.inputMethod.hide()

            }

            function addDock(){
                if ( !app.isLandscape ){
                    pageView.state = "anchortop"
                } else{
                    pageView.state = "anchorright"
                }

                if(!searchPageLoader.item){
                    searchPageLoader.source = "../../MapViewer/views/SearchPage.qml"
                    searchItemLoader.mapView = mapView
                    searchItemLoader.mapProperties = mapProperties
                    searchItemLoader.searchType = isBufferSearchEnabled ? "bufferSearch":"searchByExtent"
                    searchItemLoader.visible = true
                    searchItemLoader.currentPlaceSearchText = mapView.searchText
                    searchItemLoader.currentFeatureSearchText = mapView.searchText

                } else
                    searchPageLoader.item.willDockToBottom = false

                searchItemLoader.updateFeatureSearchProperties(searchConfigSources)
                searchDockItem.visible = true
            }

            function removeDock()
            {
                if(searchItemLoader)
                {
                    mapView.searchText = searchItemLoader.currentPlaceSearchText || searchItemLoader.currentFeatureSearchText

                }
                mapPageCarouselItem.visible = true
                if(searchPageLoader && searchPageLoader.item)
                    mapView.activeSearchTab = searchPageLoader.item.activeTab
                searchPageLoader.source = ""

                pageView.state = defaultAnchor//"anchorright"
                searchDockItem.visible = false
            }
        }

        //paneldock item

        Rectangle{
            id:panelDockItem
            width:parent.width
            height:parent.height
            anchors.bottom: parent.bottom
            visible:false
            property var childItem
            Drag.active: dragArea2.drag.active
            Drag.hotSpot.x:10

            MouseArea {

                id: dragArea3
                anchors.fill: parent
                enabled:pageView.state !== "anchorbottom"

                drag.target: isLandscape ? panelDockItem:null

                onReleased: {
                    if( isLandscape )
                    {

                        panelDockItem.y=0
                        if(panelDockItem.x > parent.width/2)
                        {
                            panelDockItem.x = mapView.width
                            pageView.state = "anchorleft"

                        }
                        else
                        {
                            panelDockItem.x = 0
                            pageView.state = "anchorright"
                        }
                    }

                }
            }
            property alias panelItemLoader: panelPageLoader.item
            Loader{
                id:panelPageLoader
                width:parent.width
                height:parent.height


                onLoaded: {

                }
            }
            Connections {
                target: panelPageLoader.item

                function onHidepanelPage() {
                    pageView.hidePanelItem()
                    pageView.hideSearchItem()
                    moreIcon.checked = false
                    isInRouteMode = false
                }

                function onShowMoreMenu(x,y){
                    mapView.showMoreMenu(x,y)
                }




                function onDockToLeft() {
                    if ( panelPageLoader.visible ){
                        if ( app.isLandscape )
                            pageView.state = "anchorright"
                    }
                }

                function onDockToTop() {
                    mapPageHeader.height = 0
                    mapPageHeader.visible = false
                    pageView.state = "anchortop"

                }

                function onDockToBottom() {

                    panelDockItem.dockToBottom()
                }

                function onDockToTopReduced() {
                    panelDockItem.dockToTopReduced()
                }

            }


            function screenRatio()
            {
                let width = mapView.widthInPixels
                let height = mapView.heightInPixels
                return height > width ? width/height :height/width
            }

            function dockToBottom()
            {
                pageView.state = "anchorbottom"
            }



            function populatePanelPageMapUnits(panelPage)
            {
                panelPage.headerTabNames = [app.tabNames.kMapUnits]
                panelPage.title = strings.kMapUnits
                mapView.panelTitle = strings.kMapUnits
                panelPage.showPageCount = false

            }
            function populatePanelPageGraticules(panelPage)
            {
                panelPage.headerTabNames = [app.tabNames.kGraticules]
                panelPage.title = strings.kGraticules
                mapView.panelTitle = strings.kGraticules
                panelPage.showPageCount = false

            }


            function populatePanelPageElevationProfile(panelPage)
            {
                panelPage.headerTabNames = [app.tabNames.kElevation]
                panelPage.title = qsTr("%1 (%2)").arg(strings.kElevation).arg(mapView.elevationUnits)
                panelPage.showPageCount = false
                panelPage.showFeaturesView()
            }

            function populatePanelPageFilters(panelPage){
                panelPage.headerTabNames = [app.tabNames.kFilters]
                panelPage.title = strings.filter
                mapView.panelTitle = strings.filter
                panelPage.showFeaturesView()
                panelPage.showPageCount = false
            }

            function populatePanelPageMapAreas(panelPage)
            {
                panelPage.headerTabNames = [app.tabNames.kMapAreas]
                panelPage.title = strings.kMapArea
                mapView.panelTitle = strings.kMapArea
                panelPage.showPageCount = false
                panelPage.showFeaturesView()
                //mapView.clearSearch()
                mapAreaManager.mapView = mapView
                mapAreaManager.mapAreaGraphicsArray = mapPage.mapAreaGraphicsArray
                offlineMapTask.loadUnloadedMapAreas()
                mapAreaManager.drawMapAreas()

            }



            function populatePanelPageBaseMapProperties(panelPage)
            {
                panelPage.headerTabNames = [app.tabNames.kBasemaps]
                panelPage.title = strings.kBasemaps
                mapView.panelTitle = strings.kBasemaps
                panelPage.showPageCount = false
                panelPage.showFeaturesView()
            }

            function populatePanelPageAboutProperties(panelPage) {
                panelPage.headerTabNames = [ app.tabNames.kAbout ]
                panelPage.title = strings.tab_about
                mapView.panelTitle = strings.tab_about

                let welcomeText = app.viewerJsonDict[app.currentAppId].detailTitle
                if ( app.viewerJsonDict[app.currentAppId].detailTitle && app.viewerJsonDict[app.currentAppId].detailTitle > "" ){
                    panelPage.mapWelcomeText = welcomeText
                }

                if( mapProperties.title && mapProperties.title > "" ) {
                    panelPage.mapTitle = mapProperties.title
                }

                if( mapProperties.owner && mapProperties.owner > "" ) {
                    panelPage.owner = mapProperties.owner
                }

                if( mapProperties.modifiedDate && mapProperties.modifiedDate > "" ) {
                    panelPage.modifiedDate = mapProperties.modifiedDate
                }

                panelPage.showPageCount = false
                panelPage.showFeaturesView()
            }

            function populatePanelPageBookmarkProperties(panelPage)
            {
                panelPage.headerTabNames = [app.tabNames.kBookmarks]
                panelPage.title = strings.kBookmarks
                mapView.panelTitle = strings.kBookmarks
                panelPage.showPageCount = false
                panelPage.showFeaturesView()
                //panelPage.show()
            }

            function populatePanelPageIdentifyProperties(panelPage,tabString)
            {
                panelPage.headerTabNames = tabString.split(",")

                panelPage.pageCount = mapView.identifyProperties.popupManagers.length
                panelPage.showFeaturesView()
                panelPage.pageCount = mapView.identifyProperties.popupManagers.length
                panelPage.showPageCount = panelItemLoader.pageCount > 1 ? true:false

            }

            function populatePanelPageLegendProperties(panelPage)
            {
                panelPage.hideDetailsView()
                if(isLegendEnabled)
                    panelPage.headerTabNames = [app.tabNames.kLegend]

                panelPage.title = strings.kLegend
                mapView.panelTitle = strings.kLegend
                panelPage.showFeaturesView()
                panelPage.showPageCount = false
            }

            function populatePanelPageRoutes(panelPage)
            {
                panelPage.headerTabNames = [app.tabNames.kDirections]

                panelPage.title = strings.direction
                mapView.panelTitle  = strings.direction
                panelPage.showFeaturesView()
                panelPage.showPageCount = false
                if((panelDockItem.childItem === "routes") && (!isBufferSearchEnabled))
                    mapView.showPin(mapView.selectedBufferPoint)
            }

            function populatePanelPage(type,tabString)
            {
                switch(type) {
                case "about":
                    childItem = "about"
                    populatePanelPageAboutProperties(panelItemLoader)
                    break
                case "legend":
                    childItem = "legend"
                    populatePanelPageLegendProperties(panelItemLoader)
                    break
                case "identify":
                    childItem = "identify"
                    populatePanelPageIdentifyProperties(panelItemLoader,tabString)
                    break
                case "bookmark":
                    childItem = "bookmark"
                    populatePanelPageBookmarkProperties(panelItemLoader)
                    break
                case "basemaps":
                    childItem = "basemaps"
                    populatePanelPageBaseMapProperties(panelItemLoader)
                    break

                case "mapunits":
                    childItem = "mapunits"
                    populatePanelPageMapUnits(panelItemLoader)
                    break
                case "graticules":
                    childItem = "graticules"
                    populatePanelPageGraticules(panelItemLoader)
                    break
                case "filters":
                    childItem = "filters"
                    populatePanelPageFilters(panelItemLoader)
                    break
                case "route":
                    childItem = "routes"

                    populatePanelPageRoutes(panelItemLoader)
                    break
                case "elevationProfile":
                    childItem = "elevationProfile"
                    placeSearchResult.visible = true
                    populatePanelPageElevationProfile(panelItemLoader)
                    break;
                case "mapareas":
                    populatePanelPageMapAreas(panelItemLoader)
                    break
                }
            }

            function addDock(type,tabString)
            {
                searchDockItem.removeDock()

                if (!app.isLandscape ){
                    mapPageCarouselItem.visible = false
                    pageView.state = "anchorbottom"
                } else {
                    pageView.state = "anchorright"
                }

                if (!panelPageLoader.item){
                    //close any other window like panelPage and searchPage
                    panelPageLoader.source = "../../MapViewer/views/PanelPage.qml"
                    panelItemLoader.mapView = mapView
                    populatePanelPage(type,tabString)

                } else{
                    //clear previous panel page item
                    if(childItem !== type)
                        populatePanelPage(type,tabString)
                }

                panelDockItem.visible = true
            }


            function removeDock()
            {
                routePartGraphicsOverlay.graphics.clear()
                routeGraphicsOverlay.graphics.clear()
                elevationpointGraphicsOverlay.graphics.clear()
                polygonGraphicsOverlay.graphics.clear()
                panelPageLoader.source = ""

                mapPageHeader.height = app.headerHeight + app.notchHeight
                pageView.state = defaultAnchor//"anchorright"

                panelDockItem.visible = false
                mapPageCarouselItem.visible = true
            }
        }

        OfflineMapTask {
            id: offlineMapTask
            onlineMap: myWebmap
            onLoadErrorChanged: {

            }

            onLoadStatusChanged:{
                if (loadStatus == Enums.LoadStatusLoaded){


                }
            }

            function loadUnloadedMapAreas()
            {
                if(mapAreasCount !== mapAreasModel.count)
                {
                    //check for the unloaded maparea
                    for(var j=0;j< mapAreasCount; j++)
                    {
                        let mapArea = offlineMapTask.preplannedMapAreaList.get(j);
                        var id = mapArea.portalItem.itemId
                        if(!isMapAreaPresentInModel(id))
                        {
                            loadMapArea(mapArea)
                        }
                    }
                    mapAreaManager.drawMapAreas()
                }
            }

            function isMapAreaPresentInModel(id)
            {
                for(var p=0;p < mapAreasModel.count;p++)
                {
                    var mapAreaObj = mapAreasModel.get(p)
                    var portalItem = mapAreaObj.portalItem
                    if(portalItem.itemId === id)
                        return true
                }
                return false
            }


            function loadMapArea(mapArea)
            {
                var token = null
                var url = ""
                if(portal && app.isSignedIn)
                    token = portal.credential.token
                mapArea.loadStatusChanged.connect(function () {
                    if (mapArea.loadStatus !== Enums.LoadStatusLoaded)
                        return;

                    var  mapAreaPolygon = null;
                    var mapAreaGeometry = mapArea.areaOfInterest;
                    if (mapAreaGeometry.geometryType === Enums.GeometryTypeEnvelope)
                        mapAreaPolygon = GeometryEngine.buffer(mapAreaGeometry, 0);
                    else
                        mapAreaPolygon = mapAreaGeometry;

                    const graphic = ArcGISRuntimeEnvironment.createObject("Graphic", { symbol: simpleMapAreaFillSymbol,geometry: mapAreaPolygon });

                    mapAreaGraphicsArray.push(graphic)
                    var _size = 0
                    var _title = ""


                    for(let j = 0;j < mapArea.packageItems.count;j++){
                        var content_data = mapArea.packageItems.get(j)
                        _size += parseInt(content_data.size)

                    }
                    if(_size < 1024)
                        _size = _size + " Bytes"
                    else
                        _size = mapViewerCore.getFileSize(_size)

                    var _portalItem = mapArea.portalItem
                    var _areaOfInterest = mapArea.areaOfInterest
                    var _mapAreaItemId = _portalItem.itemId
                    var mapareajson = _portalItem.json
                    var _thumbnailpath = mapareajson.thumbnail

                    var _modifiedDate = ""
                    if(mapareajson.modified !== null)
                    {
                        _modifiedDate = mapareajson.modified
                    }

                    var _createdDate = mapareajson.created
                    var _owner = mapareajson.owner


                    var _isdownloaded = false
                    if(existingmapareas)
                    {
                        var _existingrecs = existingmapareas.filter(item => item.id === _mapAreaItemId)
                        if(_existingrecs.length > 0)
                            _isdownloaded=true
                    }

                    _title = mapareajson.title

                    if(token)
                    {
                        var prefix = "?token="+ token
                        url =  app.portalUrl + ("/sharing/rest/content/items/%1/info/%2%3").arg(_mapAreaItemId).arg(_thumbnailpath).arg(prefix);
                    }
                    else
                        url = app.portalUrl + ("/sharing/rest/content/items/%1/info/%2").arg(_mapAreaItemId).arg(_thumbnailpath)

                    if(!isMapAreaPresentInModel(mapArea.portalItem.itemId))
                    {
                        mapAreasModel.append({"mapArea":mapArea,"portalItem":_portalItem,"thumbnailImg":_thumbnailpath,"thumbnailurl":url,"title":_title,"areaOfInterest":_areaOfInterest,"size":_size,"createdDate":_createdDate,"modifiedDate":_modifiedDate,"isPresent":_isdownloaded,"owner":_owner,"isDownloading":false,"isSelected":false})
                        mapAreaslst.push({"mapArea":mapArea,"portalItem":_portalItem,"thumbnailImg":_thumbnailpath,"thumbnailurl":url,"title":_title,"areaOfInterest":_areaOfInterest,"size":_size,"createdDate":_createdDate,"modifiedDate":_modifiedDate,"isPresent":_isdownloaded,"owner":_owner})
                    }

                });
                mapArea.load();
            }

            function loadMapAreaFromId(id)
            {
                for(var k=0; k<offlineMapTask.preplannedMapAreaList.count; k++)
                {
                    let mapArea = offlineMapTask.preplannedMapAreaList.get(k);
                    var _portalItem = mapArea.portalItem
                    if(_portalItem.itemId === id)
                    {
                        mapAreaManager.loadMapArea(mapArea)
                    }

                }

            }


            function loadMapAreaFromIndex(index)
            {
                var i = index
                let mapArea = offlineMapTask.preplannedMapAreaList.get(i);
                loadMapArea(mapArea)

            }

            onPreplannedMapAreasStatusChanged: {
                if(preplannedMapAreasStatus === Enums.TaskStatusCompleted)
                {
                    var token = null
                    var url = ""
                    mapAreaGraphicsArray = []
                    var areasModel = offlineMapTask.preplannedMapAreaList;
                    if(portal && portal.credential)
                        token = portal.credential.token
                    for(let i = 0;i< offlineMapTask.preplannedMapAreaList.count;i++){
                        loadMapAreaFromIndex(i)

                    }

                    mapAreasCount = offlineMapTask.preplannedMapAreaList.count

                    if(offlineMapTask.preplannedMapAreaList.count > 0)
                    {
                        mapPage.hasMapArea = true

                        var item = app.mapsWithMapAreas.filter(id => id === portalItem.id)
                        if(item.length === 0)
                            app.mapsWithMapAreas.push(portalItem.id)
                    }

                    else
                        mapPage.hasMapArea = false

                    //updateMenuItemsContent()

                }

            }

        }

    }

    onPrevious: {
        if(mapView.map)
        {
            mapView.map.cancelLoad()

        }
    }

    Component {
        id: filtersView

        FiltersView {
            id: filters
            width: app.width
            filterListModel: mapView.filterConfigModel
            filterDic: mapView.filterLayersDic
            radiusMax: mapView.bufferMax
            radiusMin: mapView.bufferMin
            currentRadius: mapView.bufferDistance
            defaultRadius: mapView.defaultDistance
            measureString: mapView.measureUnitsString

            onFilterConfigChanged: {
                if ( hidePanelPage && panelPageLoader.item ){
                    panelPageLoader.item.hidepanelPage()
                }

                if(mapView.featuresModel.count > 0 ) {
                    mapPageCarouselItem.visible = false
                    mapView.searchText = ""
                    placeSearchResult.graphics.remove(0, 1)
                    mapView.geocodeModel.clearAll()
                    searchfeaturesModel.clearAll()
                    isFilterFinished = true

                    if(searchPageLoader && searchPageLoader.item){
                        searchPageLoader.item.searchText = ""
                        searchPageLoader.item.mapView.searchText = ""
                        searchPageLoader.item.currentPlaceSearchText = ""
                        searchPageLoader.item.searchResultTitleText = ""
                        searchPageLoader.item.clearSearch()
                    }

                    mapView.identifyProperties.clearHighlight();
                    mapView.identifyProperties.clearHighlightInLayer();
                    if(mapView.featuresModel.searchMode === searchMode.spatial)
                        mapView.clearSpatialSearch();
                    identifyInProgress = false;

                    // Re-do search with the configured filters in a buffer mode
                    if ( isBufferSearchEnabled ){
                        if ( mapView.selectedBufferPoint ){
                            mapView.findFeaturesInBuffer(mapView.selectedBufferPoint, mapView.bufferDistance, mapView.measureUnits, mapView.layerSpatialSearch);
                        }
                    } else {
                        // Re-do search with the configured filters in an extent mode
                        mapView.findFeaturesInMapExtent(mapView.layerSpatialSearch);
                    }

                    mapView.updateDefinitionQueryOfLayers(definitionQueryDic,filterDic)
                } else{
                    mapView.updateDefinitionQueryOfLayers(definitionQueryDic,filterDic, true)
                }
            }
        }
    }

    CustomAuthenticationView {
        //TODO: This will be used to replace the runtime authentication popup. It has a consistent material look
        id: loginDialog
    }

    Component {
        id: listModelComponent

        ListModel {
        }
    }



    Connections {
        target: app

        function onIsSignedInChanged() {
            if (!app.isSignedIn && !app.refreshTokenTimer.isRefreshing) {
                pageView.hidePanelItem()
                pageView.hideSearchItem()
                moreIcon.checked = false
                mapPage.previous()
            }
        }

        function onBackButtonPressed() {
            portalSearch.offlineCacheManager.clearAllCache()
            if (app.stackView.currentItem.objectName === "mapPage" &&
                    !app.aboutAppPage.visible && !mapViewerCore.hasVisibleSignInPage()) {
                if (more.visible) {
                    more.close()
                } else if (app.messageDialog.visible) {
                    app.messageDialog.close()
                } else if (loginDialog.visible) {
                    loginDialog.close()
                } else if (panelDockItem.visible) {
                    if(panelDockItem.panelItemLoader.relatedDetails.visible)
                    {
                        panelDockItem.panelItemLoader.relatedDetails.visible = false
                        panelDockItem.panelItemLoader.panelContent.visible = true
                    }
                    else
                    {
                        if(panelDockItem.panelItemLoader.tabBar.currentIndex > 0)
                        {
                            panelDockItem.panelItemLoader.tabBar.currentIndex = 0
                        }
                        else if ( pageView.state === "anchortop" && !app.isLandscape ) {
                            panelDockItem.panelItemLoader.hideFullView()
                            pageView.state = "anchorbottom"

                        }
                        else
                        {
                            panelDockItem.removeDock()
                            identifyProperties.clearHighlight()
                            if ( filterIcon.checked ){
                                filterIcon.checked = false;
                            }
                        }
                    }
                }

                else if (searchDockItem.visible) {
                    if(searchDockItem.searchItemLoader.tabBar.currentIndex)
                    {
                        searchDockItem.searchItemLoader.tabBar.currentIndex = 0
                    }
                    else
                        searchDockItem.removeDock()

                }
                else if(nearbyMapPageNavSheetLoader.item)
                {
                    let navigationShareSheet = nearbyMapPageNavSheetLoader.item;
                    navigationShareSheet.hideSheet()
                }

                else {
                    mapPage.previous()
                }
            }
        }
    }

    function resetFilters()
    {
        for (var key in mapView.filterLayersDic){
            for (var i =0 ; i < mapView.filterLayersDic[key].count; i++){
                mapView.filterLayersDic[key].get(i).isChecked = false
            }
        }
        noOfFiltersApplied = 0

        mapView.map.loadStatusChanged.connect(function () {
            mapView.processLoadStatusChange()
        })

        mapView.bufferDistance = mapView.defaultDistance
    }

    onPortalItemChanged: {
        if (mapPage.portalItem) {
            //need to clear the info of previous item
            panelPage.owner = ""
            panelPage.modifiedDate = ""
            panelPage.mapTitle = ""
            switch(mapPage.portalItem.type) {
            case "Web Map":
                if(comingFromMapArea)
                {
                    var newItem = ArcGISRuntimeEnvironment.createObject("PortalItem", { url: portalItem.url });

                    // construct a map from an item
                    var newMap = ArcGISRuntimeEnvironment.createObject("Map", { item: newItem });

                    // add the map to the map view
                    mapView.map = newMap;
                    mapView.clearSearch()

                    resetFilters()

                }
                // mapPage.showUpdatesAvailable = false
                else{
                    isFetchedFeatures = false
                    fetchingFeatures=false
                    layerName = ""
                    layerManager.fetchingLayers = false
                    layerManager.fetchingFeatures = false
                    mapView.isFilter = false;
                    mapView.filterConfigModel.clear();
                    mapView.filterLayersDic = ({});
                    readAppConfigJson()
                }



                break

            case "maparea":
                mapPage.hasMapArea = false
                mapPage.showUpdatesAvailable = false
                var _basemaps
                if(typeof(mapProperties.basemaps) !== "object")
                    _basemaps = mapProperties.basemaps.split(",")
                else
                    _basemaps = mapProperties.basemaps
                myWebmap.basemap.baseLayers.clear()
                myWebmap.operationalLayers.clear()
                polygonGraphicsOverlay.graphics.clear()
                if(mapPage.willReadAppJson)
                    readAppConfigJson()

                checkIfFeatureSearchEnabled()
                openMapArea()

                resetFilters()

                break

            default:
                app.messageDialog.show(strings.unsupported_item_type, strings.cannot_open_item_of_type + mapPage.portalItem.type)
                app.messageDialog.connectToAccepted(function () { mapPage.previous() })
            }


        }
    }

    function checkIfFeatureSearchEnabled(){
        let layerPropertiesCount = 0;
        let currentAppJSON = app.viewerJsonDict[app.currentAppId]

        // get the search configuration sources to fetch layer properties for configured feature search
        if ( currentAppJSON ){
            if( currentAppJSON.searchConfiguration )
                searchConfigSources = currentAppJSON.searchConfiguration.sources
            else if ( currentAppJSON.searchConfig )
                searchConfigSources = currentAppJSON.searchConfig.sources
        }

        searchConfigSources.forEach((source) =>{
                                        if (source.flayerId || source.layer){
                                            layerPropertiesCount += 1;
                                        }
                                    })
        isFeatureSearchEnabled = layerPropertiesCount > 0
    }

    function readAppConfigJson()
    {

        let currentAppJSON = app.viewerJsonDict[app.currentAppId]
        mapView.filterConfigModel.clear()

        if( currentAppJSON.search !== undefined )
            isSearchEnabled = currentAppJSON.search
        else if(currentAppJSON.searchEnabled !== undefined)
            isSearchEnabled = currentAppJSON.searchEnabled

        // use searchConfigSources to find if feature search is enabled or not
        checkIfFeatureSearchEnabled()

        //check for the elevation
        if ( currentAppJSON.showElevationProfile !== undefined ) {
            isElevationEnabled = currentAppJSON.showElevationProfile
        }

        if ( currentAppJSON.legend !== undefined ) {
            isLegendEnabled = currentAppJSON.legend
        }
        if ( currentAppJSON.enableBufferSearch !== undefined ) {
            let _isBufferSearchEnabled = currentAppJSON.enableBufferSearch
            if(typeof _isBufferSearchEnabled === "boolean")
                isBufferSearchEnabled = _isBufferSearchEnabled
            else
                isBufferSearchEnabled = (_isBufferSearchEnabled.branchValue === "search-radius")

        }

        if (( currentAppJSON.basemapToggle !== undefined  && currentAppJSON.basemapToggle === true ) &&
                (( currentAppJSON.basemapSelector && currentAppJSON.basemapSelector > "" ) || ( currentAppJSON.altBasemap && currentAppJSON.altBasemap > "" ))) {
            isBaseMapEnabled = app.viewerJsonDict[app.currentAppId].basemapToggle
        }

        if ( app.viewerJsonDict[app.currentAppId].bookmarks !== undefined ){
            isBookMarkEnabled = app.viewerJsonDict[app.currentAppId].bookmarks
        }

        if (app.viewerJsonDict[app.currentAppId].enableSearchLayer !== undefined) {
            isSearLayerEnabled = app.viewerJsonDict[app.currentAppId].enableSearchLayer
        }

        if (app.viewerJsonDict[app.currentAppId].searchLayerLookup !== undefined) {
            isSearLayerEnabled = app.viewerJsonDict[app.currentAppId].searchLayerLookup
        }

        if (isSearLayerEnabled) {
            if(app.viewerJsonDict[app.currentAppId].searchLayer.layers !== undefined ){
                searchLayer = app.viewerJsonDict[app.currentAppId].searchLayer.layers[0].id;
            } else {
                searchLayer = app.viewerJsonDict[app.currentAppId].searchLayer.id;
            }
        }

        //Check whether need to group results by layer
        if(app.viewerJsonDict[app.currentAppId].groupResultsByLayer !== undefined ) {
            groupResultsByLayer = app.viewerJsonDict[app.currentAppId].groupResultsByLayer;
        } else {
            groupResultsByLayer = true
        }

        //Read the customized message when no result is returned
        if(app.viewerJsonDict[app.currentAppId].noResultsMessage !== undefined) {
            mapView.noResultsMessage = app.viewerJsonDict[app.currentAppId].noResultsMessage;
        }

        //Read the measure units
        if(app.viewerJsonDict[app.currentAppId].searchUnits !== undefined) {
            mapView.measureUnits = getMeasureUnits(app.viewerJsonDict[app.currentAppId].searchUnits)
            mapView.measureUnitsString = getMeasureUnitsString(app.viewerJsonDict[app.currentAppId].searchUnits);
        }

        if(isBufferSearchEnabled){

            //Read the maximum, minimum,precision and default value of the buffer radius slider bar
            if(app.viewerJsonDict[app.currentAppId].sliderRange !== undefined) {
                mapView.defaultDistance = app.viewerJsonDict[app.currentAppId].sliderRange.default;
                mapView.bufferMax = app.viewerJsonDict[app.currentAppId].sliderRange.maximum;
                mapView.bufferMin = app.viewerJsonDict[app.currentAppId].sliderRange.minimum;
                if ( app.viewerJsonDict[app.currentAppId].precision ){
                    mapView.bufferRadiusPrecision = app.viewerJsonDict[app.currentAppId].precision;
                }

                // if ( app.viewerJsonDict[app.currentAppId].sliderRange.precision ){
                //    mapView.bufferRadiusPrecision = app.viewerJsonDict[app.currentAppId].sliderRange.precision;
                // }

            } else {
                if(app.viewerJsonDict[app.currentAppId].distance !== undefined)
                    mapView.defaultDistance = app.viewerJsonDict[app.currentAppId].distance;
                if(app.viewerJsonDict[app.currentAppId].maxDistance !== undefined)
                    mapView.bufferMax = app.viewerJsonDict[app.currentAppId].maxDistance;
                if(app.viewerJsonDict[app.currentAppId].minDistance !== undefined)
                    mapView.bufferMin = app.viewerJsonDict[app.currentAppId].minDistance;

                if( app.viewerJsonDict[app.currentAppId].precision ){
                    mapView.bufferRadiusPrecision = app.viewerJsonDict[app.currentAppId].precision;
                }
            }

            if ( mapView.bufferRadiusPrecision > 2 ){
                mapView.bufferRadiusPrecision = 2;
            }
        }

        //Read the configuration of whether to show distance
        if (app.viewerJsonDict[app.currentAppId].includeDistance !== undefined) {
            mapView.includeDistance = app.viewerJsonDict[app.currentAppId].includeDistance;
        }

        //Read the configuration that whether direction service is enabled
        if (app.viewerJsonDict[app.currentAppId].showDirections !== undefined) {
            mapView.showDirections = app.viewerJsonDict[app.currentAppId].showDirections;
        }

        //Read the configuration to see which layers are included in the results
        if (app.viewerJsonDict[app.currentAppId].lookupLayers !== undefined) {
            mapView.layerSpatialSearch = [];
            var layers = app.viewerJsonDict[app.currentAppId].lookupLayers.layers;
            if(layers){
                layers.forEach(layer => {
                                   mapView.layerSpatialSearch.push(layer.id);
                               });
            }
        }

        //Read the configuration that for which layers direction service is enabled
        if (app.viewerJsonDict[app.currentAppId].directionsLayers !== undefined) {
            mapView.layerDirection = [];
            var layers2 = app.viewerJsonDict[app.currentAppId].directionsLayers.layers;
            layers2.forEach(layer => {
                                mapView.layerDirection.push(layer.id);
                            });
        }

        //Read the configuration of customized filters for each layer
        if(app.viewerJsonDict[app.currentAppId].filterConfig !== undefined) {
            if(app.viewerJsonDict[app.currentAppId].filterConfig.layerExpressions.length > 0) {
                mapView.isFilter = true;
                var layerExpressions = app.viewerJsonDict[app.currentAppId].filterConfig.layerExpressions;
                layerExpressions.forEach(layerExpression => {
                                             mapView.filterConfigModel.append({
                                                                                  "layerId": layerExpression.id,
                                                                                  "layerTitle": layerExpression.title,
                                                                                  "filterCount":layerExpression.expressions.length,
                                                                                  "operator":layerExpression.operator,
                                                                                  "collapsedState":layerExpressions.length > 1 ? true : false
                                                                              })

                                             var component = expressionTempModelComponent;
                                             var expressionTempModel = component.createObject(parent);

                                             layerExpression.expressions.forEach(expression => {
                                                                                     expression.isChecked = false;
                                                                                     expression.isDomainField = false
                                                                                     if(!expression.definitionExpression)
                                                                                     expression.definitionExpression = ""
                                                                                     let fldvals = {}
                                                                                     expression.fieldValues = fldvals
                                                                                     expressionTempModel.append(expression);
                                                                                 })
                                             mapView.filterLayersDic[layerExpression.id] = expressionTempModel;
                                         })
                isFilterEnabled = (Object.keys(mapView.filterLayersDic).length === 0)   ? false : true
            }
        }

    }

    function populateJsonQueryFields(keysprocessed,filterKeysUnprocessed){
        isJsonQueryFieldsPopulated = true
        if(!keysprocessed)
            keysprocessed = []

        if(!filterKeysUnprocessed)
            filterKeysUnprocessed = Object.keys(mapView.filterLayersDic)

        if(filterKeysUnprocessed.length > 0){
            let filterDicKey = filterKeysUnprocessed.pop()
            let itemsConfigured =  mapView.filterLayersDic[filterDicKey]
            let lyrid = filterDicKey
            let promiseArray = []
            for(var x = 0; x< itemsConfigured.count;x++)
            {
                var configobj =  itemsConfigured.get(x)
                if(!configobj.definitionExpression){
                    const promise1 =  new Promise((resolve, reject)=>{
                                                      queryTableForUniqueValues(lyrid,configobj,filterDicKey,resolve);
                                                  });

                    promiseArray.push(promise1)
                }
            }

            return Promise.all(promiseArray).then(() => {
                                                      keysprocessed.push(filterDicKey )
                                                      populateJsonQueryFields(keysprocessed,filterKeysUnprocessed)
                                                  });
        }
    }

    function updateFilterLayersDic(filterDicKey,modConfigObj){
        let itemsConfigured =  mapView.filterLayersDic[filterDicKey]
        for(var x = 0; x< itemsConfigured.count;x++){
            var configobj =  itemsConfigured.get(x)
            if(configobj.id === modConfigObj.id){
                mapView.filterLayersDic[filterDicKey].set(x,modConfigObj)
                break
            }
        }
    }


    function getfieldDomain(lyr,configobj){
        let field = configobj.field
        //let lyr = layerManager.getLayerById(layerId)
        let _table = lyr.featureTable;
        var fields = _table.fields
        let domain = null
        for(var k=0;k< fields.length; k++){
            var fieldobj = fields[k]
            if(fieldobj.name === field){
                domain = fieldobj.domain
            }
        }
        return domain
    }

    function populateFilterConfigValues(lyr,configobj,filterDicKey,resolve){
        let field = configobj.field
        //let lyr = layerManager.getLayerById(layerId)
        let _table = lyr.featureTable;
        if(_table)
        {
            let fields = _table.fields
            let taskId;
            let layerId = lyr.layerId

            //check if it is a domain field
            let fielddomain = getfieldDomain(lyr,configobj)
            if(fielddomain){
                configobj.isDomainField = true
            }

            // populate the ComboBox in FiltersView (drop-down menu) with unique values
            spatialqueryParameters.returnGeometry = true
            spatialqueryParameters.geometry = null
            let promiseToQuery = mapView.queryFeatures("1=1", _table);
            spatialQueryTimer.stop();

            promiseToQuery.then(function(result){
                const features = Array.from(result.iterator.features);
                let fieldvalues = features.map(obj => obj.attributes.attributeValue(configobj.field))
                let valuesArray = []
                let configValues = {}
                if (configobj.type === "number" && !configobj.isDomainField ){
                    //store the min and max
                    let valuesWithoutNull = fieldvalues.filter(function(val) {
                        return val !== null
                    });
                    let minVal = Math.min(...valuesWithoutNull)
                    let maxVal = Math.max(...valuesWithoutNull)

                    valuesArray.push(minVal)
                    valuesArray.push(maxVal)
                } else if (configobj.type === "string" || configobj.isDomainField ){
                    //get distinct values
                    const unique = (value, index, self) => {
                        return (self.indexOf(value) === index && value > "")
                    }

                    let uniqueValues = fieldvalues.filter(unique)
                    if(!configobj.isDomainField){
                        uniqueValues = uniqueValues.map(function(obj) {
                            let element = obj.replace(/\n/g,"")
                            return element
                        })
                    } else{
                        uniqueValues = uniqueValues.map(fieldValue => {
                                                            let displayText = mapViewerCore.getDomainNameFromCode(layerId,field,fieldValue,lyr)
                                                            return displayText


                                                        })
                    }
                    valuesArray = uniqueValues.sort()
                    if(configobj.placeholder > "")
                        valuesArray.unshift(configobj.placeholder)
                    else
                        valuesArray.unshift("None")
                }

                configValues["values"] = valuesArray
                configobj.fieldValues = configValues

                //update the model
                updateFilterLayersDic(filterDicKey,configobj)

                //after getting the unique field values update the mapView.filterLayersDic
                resolve();
            },configobj,filterDicKey).catch(error => {
                                                //console.error("error occurred",error.message)
                                                measureToast.toVar = parent.height - measureToast.height
                                                measureToast.show("%1:%2".arg(strings.error).arg(error.message), parent.height-measureToast.height, 1500)
                                                resolve();
                                            })
        }
    }

    function queryTableForUniqueValues(layerId,configobj,filterDicKey,resolve){
        let field = configobj.field
        let lyr = layerManager.getLayerById(layerId)
        if(lyr.objectType === "FeatureLayer")
        {

            if(lyr.loadStatus  === Enums.LoadStatusLoaded)
                populateFilterConfigValues(lyr,configobj,filterDicKey,resolve)
            //populateFilterConfigValues(lyr,configobj,filterDicKey,resolve)
            else{
                lyr.loadStatusChanged.connect(function(){
                    populateFilterConfigValues(lyr,configobj,filterDicKey,resolve)
                })

                lyr.load()
            }
        }
    }

    QueryParameters {
        id: attributequeryParameters
    }

    function openMapArea(){
        var filePath = mapProperties.fileUrl
        var fileInfo = AppFramework.fileInfo(filePath)
        var mmpk = null
        if (fileInfo.exists) {
            mmpk = ArcGISRuntimeEnvironment.createObject("MobileMapPackage", { path: filePath });
            mmpk.path = AppFramework.resolvedPathUrl(filePath)
            mmpk.loadStatusChanged.connect(()=> {
                                               if (mmpk.loadStatus !== Enums.LoadStatusLoaded )
                                               return;

                                               if (mmpk.maps.length < 1)
                                               return;

                                               if (mmpk.loadStatus === Enums.LoadStatusLoaded){
                                                   mapView.map = mmpk.maps[0];

                                                   // Handle loadStatus change for the offline map area if it is already loaded - this is loaded when we set mapView.map property
                                                   if (mapView.map.loadStatus === Enums.LoadStatusLoaded){
                                                       mapView.processLoadStatusChange();
                                                   }

                                                   // Handle loadStatus change for the offline map area - this is loaded when we set mapView.map property
                                                   mapView.map.loadStatusChanged.connect(() => {
                                                                                             if (mapView.map.loadStatus === Enums.LoadStatusLoaded)
                                                                                             mapView.processLoadStatusChange();
                                                                                         });
                                               }
                                           });
            mmpk.load();
        }
    }

    function updateMapAreaInfo () {
        var fileName = "mapareasinfos.json"
        var mapAreafileName = "mobile_map.marea"
        var fileContent = {"results": []}
        var mapAreaFileContent = ""
        var storageBasePath = offlineMapAreaCache.fileFolder.path + "/"
        //first read the mapareasInfos.json file

        //var mapareacontainerpath = [storageBasePath,mapPortalItemId].join("/")
        let fileInfoMapAreaContainer = AppFramework.fileInfo(storageBasePath)
        let mapAreaContainerFolder = fileInfoMapAreaContainer.folder
        if (mapAreaContainerFolder.fileExists(fileName)) {
            fileContent = mapAreaContainerFolder.readJsonFile(fileName)
        }
        //filter the downloaded maparea from contents
        fileContent.results.map(item => item.id )
        const newArray = fileContent.results.map(item => {
                                                     if(item.id === mapPage.portalItem.id)
                                                     {
                                                         //var ts = Math.round((new Date()).getTime() / 1000)
                                                         var today = new Date();
                                                         var date = (today.getMonth()+1) + '/'+ today.getDate()+'/'+ today.getFullYear();
                                                         item.modifiedDate = date
                                                     }

                                                 }
                                                 );


        //update the jsonfile
        mapAreaContainerFolder.writeJsonFile(fileName, fileContent)


    }

    function checkForUpdates()
    {
        offlineSyncTask = ArcGISRuntimeEnvironment.createObject("OfflineMapSyncTask",{map:mapView.map})
        offlineSyncTask.loadStatusChanged(getError)
        var mapUpdatesInfoTaskId =  offlineSyncTask.checkForUpdates()

        offlineSyncTask.checkForUpdatesStatusChanged.connect(function()
        {
            getUpdates(offlineSyncTask)
        }
        )

    }

    function getError()
    {
        //console.error("error")
    }

    function updateMyMapArea(portalItem)
    {

        //create the map
        var newMap = ArcGISRuntimeEnvironment.createObject("Map",{ item: portalItem });

        syncGeodatabase(portalItem.title,newMap)
        //if updates available then download maparea
    }

    function syncGeodatabase(title,myMap)
    {
        var offlineSyncTask = ArcGISRuntimeEnvironment.createObject("OfflineMapSyncTask",{map:myMap})

        //check for updates
        offlineSyncTask.loadStatusChanged(getError)

        offlineSyncTask.loadErrorChanged(getError)
        //need to test below after updates
        var mapUpdatesInfoTaskId =  offlineSyncTask.checkForUpdates()

        offlineSyncTask.checkForUpdatesStatusChanged.connect(function()
        {
            getUpdates(offlineSyncTask,title)
        }
        )


    }

    function getUpdates(offlineSyncTask,title)
    {
        var updatesInfo = offlineSyncTask.checkForUpdatesResult
        if(offlineSyncTask.checkForUpdatesStatus === Enums.TaskStatusCompleted)
        {
            var isDownloadAvailable = updatesInfo.downloadAvailability
            var isUploadAvailable = updatesInfo.uploadAvailability
            if(isUploadAvailable !== Enums.OfflineUpdateAvailabilityNone || isDownloadAvailable !== Enums.OfflineUpdateAvailabilityNone)
            {
                applyUpdates(offlineSyncTask)
            }
            else
            {
                toastMessage.show(qsTr("There are no updates available at this time."))
                mapareasbusyIndicator.visible = false
                mapSyncCompleted(title,false)
            }
        }
    }

    function applyUpdates(offlineSyncTask)
    {
        var mapsyncTaskId  = offlineSyncTask.createDefaultOfflineMapSyncParameters()
        offlineSyncTask.createDefaultOfflineMapSyncParametersStatusChanged.connect(function(){
            getParameters(offlineSyncTask)
        }
        )
    }

    function getParameters(offlineSyncTask)
    {
        if(offlineSyncTask.createDefaultOfflineMapSyncParametersStatus === Enums.TaskStatusCompleted)
        {
            var defaultMapSyncParams = offlineSyncTask.createDefaultOfflineMapSyncParametersResult
            defaultMapSyncParams.preplannedScheduledUpdatesOption = Enums.PreplannedScheduledUpdatesOptionDownloadAllUpdates

            var offlinemapSyncJob = offlineSyncTask.syncOfflineMap(defaultMapSyncParams)
            offlinemapSyncJob.start()

            offlinemapSyncJob.statusChanged.connect(function(){
                updateMap(offlinemapSyncJob)
            }
            )

        }
    }

    function showDownloadCompletedMessage(message,body)
    {
        toastMessage.isBodySet = true
        toastMessage.display(message,body)
    }

    function showDownloadFailedMessage(message,body)
    {
        if(message > "")
            messageDialog.show(qsTr("Download Failed"),body +": " + message)
    }

    function updateMap(offlinemapSyncJob)
    {
        var status = offlinemapSyncJob.jobStatus
        if(offlinemapSyncJob.jobStatus === Enums.JobStatusSucceeded)
        {
            var syncJobResult =  offlinemapSyncJob.result
            if(!syncJobResult.hasErrors)
            {
                toastMessage.show(qsTr("Offline map area syncing completed."))
                mapareasbusyIndicator.visible = false
                updateMapAreaInfo()

            }
            else
            {
                var errorMsg = syncJobResult.layerResults[0].syncLayerResult.error.additionalMessage
            }
        }
    }


    //Get the string measure unit
    function getMeasureUnitsString(searchUnits){
        var measureUnitsString = strings.km
        switch(searchUnits){
        case "meters":
            measureUnitsString =  strings.m
            break;
        case "kilometers":
            measureUnitsString = strings.km
            break;
        case "feet":
            measureUnitsString = strings.ft
            break;
        case "miles":
            measureUnitsString = strings.mi
            break;
        default:
            break;
        }
        return measureUnitsString;
    }

    //Get the measure panel enums based on the measure units
    function getMeasureUnits(searchUnits){
        var measureUnits = measurePanel.lengthUnits.kilometers
        switch(searchUnits){
        case "meters":
            measureUnits =  measurePanel.lengthUnits.meters;
            break;
        case "kilometers":
            measureUnits = measurePanel.lengthUnits.kilometers;
            break;
        case "feet":
            measureUnits = measurePanel.lengthUnits.feet;
            break;
        case "miles":
            measureUnits = measurePanel.lengthUnits.miles;
            break;
        default:
            break;
        }
        return measureUnits;
    }

    //Page to show results in listview
    ListPage {
        id: listPage

        unsortedFeatureResultsListModel : mapView.featuresModel
        groupResultsByLayer: mapPage.groupResultsByLayer
        layers: mapView.layerResults
    }

    // ------ Loader QMLtype to dynamically load the Navigation bottom sheet into the directions page ------

    Loader {
        id: nearbyMapPageNavSheetLoader
        width: parent.width
        height: parent.height
    }

    // ------ Alias item which represents the actual UI Item inside NavigationShareSheet.qml file

    property alias nearbyMapPageNavSheetLoader: nearbyMapPageNavSheetLoader.item

    //Detail popup page
    IdentifyPage {
        id: identifyPage

        identifyListModel: attrListModel
        attachmentsListModel: attachmentListModel
        totalNumOfFeatures: mapView.featuresModel.count

        Controls.CustomListModel {
            id: attrListModel
        }

        Connections {
            target: listPage

            function onClicked(index) {
                mapPageCarouselView.identifyIndex = index;
                identifyPage.currentIndex = index;
                identifyPage.bindModel();

                // Setting the current listView index to the identifyPage to display "currentIndex of TotalIndex" in the header
                identifyPage.listIndex = mapPageCarouselView.currentIndex;

                let feature = mapView.identifyProperties.features[index]
                if(feature) {
                    identifyPage.bindAttachmentModel(feature)
                }

                identifyPage.open();

            }
        }

        // Handles directions button onClick from the IdentifyPage
        onOpenRoutePage:{
            searchDistanceMode = selectedSearchDistanceMode
            handleDirectionsOnClick("identifyPage");
        }

        function bindModel() {
            try {
                identifyPage.popupLayerName = ""
                identifyPage.popupTitleText = ""
                identifyPage.distanceText = ""
                identifyPage.showDirections = mapView.showDirections
                identifyPage.showDistance = mapView.includeDistance

                var popupManager = mapView.identifyProperties.popupManagers[identifyPage.currentIndex]
                identifyPage.distanceText = "%1 %2".arg(mapView.featuresModel.get(mapView.featuresModel.getIndexByAttributes({"initialIndex":identifyPage.currentIndex})).distance).arg(mapView.measureUnitsString)
                let targetFeature = mapView.featuresModel.features[identifyPage.currentIndex]
                let centerPointOfFeature = targetFeature.geometry.extent.center
                let currentLocation
                if(mapView.locationDisplay.location){
                    currentLocation  = mapView.locationDisplay.mapLocation
                    let mydistance = mapView.getDistance(currentLocation, centerPointOfFeature);
                    identifyPage.distanceFromCurrentLocation = mapView.getNewDistance(mydistance, mapView.measureUnits);
                }


                identifyPage.isDirLyr = mapView.featuresModel.get(mapView.featuresModel.getIndexByAttributes({"initialIndex":identifyPage.currentIndex})).isDirLyr
                if(popupManager.objectName)
                    identifyPage.popupLayerName = popupManager.objectName.toString()
                if(popupManager.title)
                    identifyPage.popupTitleText = popupManager.title
                if(popupManager) {
                    /*----modified to evaluate the expressions before accessing the customHTML ---- */

                    if(popupManager.popup.popupDefinition.expressions)
                    {
                        popupManager.evaluateExpressionsStatusChanged.connect(function()
                        {
                            if(popupManager.evaluateExpressionsStatus === Enums.TaskStatusCompleted)

                            {
                                populateIdentifyModel(popupManager)
                            }

                        })

                        popupManager.evaluateExpressions()
                    }
                    else
                    {
                        populateIdentifyModel(popupManager)


                    }


                }
            } catch (err) {}
        }

        /*populate popup in identify */
        function populateIdentifyModel(popupManager)
        {
            attrListModel.clear()
            if(popupManager.showCustomHtmlDescription)
            {
                populateModelWithCustomHtml(popupManager)

            }
            else
            {
                populateModel(popupManager,attrListModel)


            }
        }

        function populateModelWithCustomHtml(popupManager)
        {

            var customHtml = popupManager.customHtmlDescription
            var newHtmlText = utilityFunctions.getHtmlSupportedByRichText(customHtml,parent.width)
            attrListModel.append({
                                     "description": newHtmlText,
                                     "label":"",
                                     "fieldValue":""

                                 })


        }

        function populateModel(popupManager,attrListModel) {
            attrListModel.clear()
            var popupModel = popupManager.displayedFields
            if (popupModel.count) {

                var feature1 = mapView.identifyProperties.features[identifyPage.currentIndex]
                var visiblefields = mapView.identifyProperties.fields[identifyPage.currentIndex]
                var attributeJson1 = feature1.attributes.attributesJson

                var _featuretable  = feature1.featureTable
                var fields = _featuretable.fields

                for(var key in visiblefields) {
                    var field = visiblefields[key]
                    var fldname = ""
                    if(field.name)
                        fldname = field.name
                    else
                        fldname = field.fieldName

                    //check if it is an expression
                    //if it is an expression then get it from popupManager
                    var popupfieldVal = ""
                    var exprfld = fldname.split('/')
                    if(exprfld.length > 1) {
                        var expr =exprfld[1]
                        var exprResults = popupManager.evaluateExpressionsResults
                        for(var k = 0;k<popupManager.evaluateExpressionsResults.length;k++) {
                            var exprobj = popupManager.evaluateExpressionsResults[k].popupExpression
                            if(exprobj.name === expr) {
                                var val = popupManager.evaluateExpressionsResults[k].result

                                var _type = exprobj.returnType

                                if(_type === Enums.PopupExpressionReturnTypeNumber)
                                    popupfieldVal = getFormattedFieldValue(val)
                                else
                                    popupfieldVal = val
                                fldname = exprobj.title
                                break;
                            }
                        }
                    }

                    //get the fieldValue from PopupManager if not populated
                    if(!popupfieldVal)
                        popupfieldVal = getPopupFieldValue(popupManager,fldname)


                    var _fieldVal = popupfieldVal
                    //if not populated get it from attribute Json

                    if(!_fieldVal) {
                        var fieldValAttrJson = mapViewerCore.getCodedValue(fields,fldname,attributeJson1[fldname])
                        _fieldVal = getFormattedFieldValue(fieldValAttrJson)
                    }

                    var _fieldAlias = fldname

                    if(field.label)
                        _fieldAlias = field.label
                    else if(field.alias)
                        _fieldAlias = field.alias

                    attrListModel.append({
                                             "description":"",
                                             "label": _fieldAlias,
                                             "fieldValue": _fieldVal !== undefined?(_fieldVal!== null? _fieldVal.toString():"null"):"null"

                                         })
                }

                //return popupManager.displayedFields
            } else {
                // This case handles map notes
                var feature = mapView.identifyProperties.features[identifyPage.currentIndex]
                var attributeJson = feature.attributes.attributesJson
                attrListModel.clear()
                if (attributeJson.hasOwnProperty("TITLE")) {
                    if (attributeJson["TITLE"]) {
                        attrListModel.append({
                                                 "label": "TITLE", //qsTr("Title"),
                                                 "fieldValue": attributeJson["TITLE"].toString()
                                             })
                    }
                }
                if (attributeJson.hasOwnProperty("DESCRIPTION")) {
                    if (attributeJson["DESCRIPTION"]) {
                        attrListModel.append({
                                                 "label": "DESCRIPTION", //qsTr("Description"),
                                                 "fieldValue": attributeJson["DESCRIPTION"].toString()
                                             })
                    }
                }
                if (attributeJson.hasOwnProperty("IMAGE_LINK_URL")) {
                    if (attributeJson["IMAGE_LINK_URL"]) {
                        attrListModel.append({
                                                 "label": "IMAGE_LINK_URL",
                                                 "fieldValue": attributeJson["IMAGE_LINK_URL"].toString()
                                             })
                    }
                }
            }
        }

        function getFormattedFieldValue(_fieldVal){
            var isNotNumber = isNaN(_fieldVal)
            if(_fieldVal && !isNotNumber) {
                var formattedVal = _fieldVal.toLocaleString(Qt.locale())
                if(formattedVal)
                    _fieldVal = formattedVal
            }
            //check if it is a date
            var dt = Date.parse(_fieldVal)
            if(dt) {
                var date_ob = new Date(dt)
                // year as 4 digits (YYYY)
                var year = date_ob.getFullYear()
                // month as 2 digits (MM)
                var month = ("0" + (date_ob.getMonth() + 1)).slice(-2);
                // date as 2 digits (DD)
                var day = ("0" + date_ob.getDate()).slice(-2);
                var formattedDateVal= month + "/"+ day + "/" + year

                _fieldVal = formattedDateVal

            }
            return _fieldVal
        }

        function getPopupFieldValue(popupManager,fieldName) {

            let _popupfield = popupManager.fieldByName(fieldName)
            let popupFieldFormat = ArcGISRuntimeEnvironment.createObject("PopupFieldFormat")
            popupFieldFormat.useThousandsSeparator = true;

            // If the popupFieldValue's fieldType is Float/ Double - round it down to 2 decimal places
            if ( popupManager.fieldType(_popupfield) === Enums.FieldTypeFloat32 || popupManager.fieldType(_popupfield) === Enums.FieldTypeFloat64 ){
                popupFieldFormat.decimalPlaces = 2;
            }

            _popupfield.format = popupFieldFormat
            let fieldVal = popupManager.fieldValue(_popupfield) !== null ? popupManager.formattedValue(_popupfield) : null
            return fieldVal
        }

        // ------ Get attachments from mapView -------

        function bindAttachmentModel(feature) {
            if(feature){
                getAttachments(feature)
            }
        }

        function getAttachments(feature) {
            attachmentListModel = emptyattachmentListModel
            isGetAttachmentRunning = true
            let attachmentModel = feature.attachments
            if(attachmentModel) {
                attachmentModel.fetchAttachmentsStatusChanged.connect(function() {
                    if(attachmentModel.fetchAttachmentsStatus === Enums.TaskStatusCompleted){
                        attachmentListModel = attachmentModel;
                        if (attachmentListModel.count < 1){
                            identifyPage.isAttachmentsEmpty = true;
                        } else {
                            identifyPage.isAttachmentsEmpty = false;
                        }
                    }
                });

                attachmentModel.fetchAttachments()
            }
            else {
                if (attachmentListModel.count < 1) identifyPage.isAttachmentsEmpty = true;
                getAttachmentCompleted()
            }
        }
    }

    // ------- Function that handles onClick the directions button in CarouselDelegate and identifyPage
    function handleDirectionsOnClick(pageIdentifier){
        if ( app.isDesktop ){
            // Check if directions button is pressed from IdentifyPage and redirect to map page to show in-app directions
            if ( pageIdentifier === "identifyPage" ){
                identifyPage.close();
                listPage.close();
            }

            // Show in-app directions using mapviewer
            mapView.destinationPoint = mapView.featuresModel.features[identifyPage.currentIndex].geometry.extent.center;
            isInRouteMode = true
            panelDockItem.addDock("route")
        } else {

            // Function to get the latitude and longitude from the selected source point - to facilitate navigation
            let sourcePointWGS84Geometry = GeometryEngine.project(mapView.selectedBufferPoint, Factory.SpatialReference.createWgs84());
            let sourcePointLatitude = sourcePointWGS84Geometry.y;
            let sourcePointLongitude = sourcePointWGS84Geometry.x;

            // Function to get the latitude and longitude from the selected destination point - to facilitate navigation
            let destPointprojectedGeometry = mapView.featuresModel.features[identifyPage.currentIndex].geometry;
            let destPointWGS84Geometry = GeometryEngine.project(destPointprojectedGeometry, Factory.SpatialReference.createWgs84());
            let destPointLatitude = destPointWGS84Geometry.y;
            let destPointLongitude = destPointWGS84Geometry.x;

            // To redirect to appropriate apps depending on whether the app is installed or not
            let isGoogleMapsInstalledInIOS = AppFramework.isAppInstalled("comgooglemaps://");
            let isGoogleMapsInstalledInAndroid = AppFramework.isAppInstalled("com.google.android.apps.maps");

            // Google/ apple store url for Google/ apple maps to download (in case the device does not have them already installed)
            let googleMapsPlayStoreLink = "https://play.google.com/store/apps/details?id=com.google.android.apps.maps&hl=en_US&gl=US";
            let googleMapsAppStoreLink = "https://apps.apple.com/us/app/google-maps/id585027354";
            let appleMapsStoreLink = "https://apps.apple.com/us/app/apple-maps/id915056765";

            // Loader QMLtype to dynamically load the Navigation bottom sheet into the directions page
            let navigationShareSheetLoader = ( pageIdentifier === "mapPage" ) ? nearbyMapPageNavSheetLoader : identifyPage.identifyPageNavSheetLoader

            navigationShareSheetLoader.source = "./NavigationShareSheet.qml";

            // Getting the item from the dynamically loaded page to initialize UI and functionality
            let navigationShareSheet = navigationShareSheetLoader.item;

            // resets the settings in the navigation bottom sheet
            navigationShareSheet.clearSettings();

            // Settings UI properties to display the navigationShareSheet

            navigationShareSheet.maximumHeight = app.height;
            navigationShareSheet.sheetTitle = strings.open_in;
            navigationShareSheet.iconColor = colors.primary_color;

            // Settings the strings, onClick function for each item in the List model for the bottom sheet
            let canShowInAppDirection = true
            if(mapProperties.isMapArea && !isOnline)
                canShowInAppDirection = false


            if(canShowInAppDirection){
                navigationShareSheet.listModel.append({ isColorOverlay: true, itemLabel: strings.in_app_directions, itemEnabled: true });

                // Function that handles onClick of in-app directions
                navigationShareSheet.functions.push(() => {
                                                        if ( pageIdentifier === "identifyPage" ){
                                                            identifyPage.close();
                                                            listPage.close();
                                                        }
                                                        mapView.destinationPoint = mapView.featuresModel.features[identifyPage.currentIndex].geometry.extent.center;
                                                        isInRouteMode = true
                                                        panelDockItem.addDock("route");
                                                    });

            }
            // Function that handles onClick of Google maps
            navigationShareSheet.listModel.append({ isColorOverlay: true, itemLabel: strings.google_maps, itemEnabled: true });
            navigationShareSheet.functions.push(() => {
                                                    if ( isGoogleMapsInstalledInIOS || isGoogleMapsInstalledInAndroid ){
                                                        AppFramework.openUrlExternally(`https://www.google.com/maps/dir/?api=1&origin=${sourcePointLatitude},${sourcePointLongitude}&destination=${destPointLatitude},${destPointLongitude}`);
                                                    } else {
                                                        if ( Qt.platform.os === "ios" ){
                                                            // open apple app store to download google maps
                                                            Qt.openUrlExternally(googleMapsAppStoreLink);
                                                        } else if ( Qt.platform.os === "android" ){
                                                            //open google play store to download google maps
                                                            Qt.openUrlExternally(googleMapsPlayStoreLink);
                                                        }
                                                    }
                                                });

            // Function that handles onClick of Apple maps
            if ( Qt.platform.os === "ios" ){
                navigationShareSheet.listModel.append({ isColorOverlay: true, itemLabel: strings.apple_maps, itemEnabled: true });
                navigationShareSheet.functions.push(() => {
                                                        AppFramework.openUrlExternally(`http://maps.apple.com/?saddr=${sourcePointLatitude},${sourcePointLongitude}&daddr=${destPointLatitude},${destPointLongitude}`);
                                                    });
            }

            // function that opens the bottom sheet
            navigationShareSheet.displaySheet();
        }
    }
}
