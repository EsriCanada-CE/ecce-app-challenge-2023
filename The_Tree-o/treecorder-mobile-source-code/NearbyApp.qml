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
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1
import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0
import ArcGIS.AppFramework.Authentication 1.0
import ArcGIS.AppFramework.WebView 1.0
import ArcGIS.AppFramework.Platform 1.0

import Esri.ArcGISRuntime 100.14

import "MapViewer/controls" as Controls
import "MapViewer/views" as Views
import "Nearby"
import "MapViewer/modules"
import "MapViewer"
import "assets" //as Assets
import "Nearby/modules"
import "Nearby/views"
import "./utility"
import "./utility/Controller"



App {
    id: app

    height: 690
    //    width: 950 //420 //
    width: 375
    property alias mapPage: mapPage
    property alias strings: strings
    //property alias colors: colors

    readonly property string appId: app.info.itemInfo.id
    readonly property real baseUnit: app.units(8)
    readonly property real defaultMargin: 2 * app.baseUnit
    readonly property real textSpacing: 0.5 * app.defaultMargin
    readonly property real iconSize: 5 * app.baseUnit
    readonly property real mapControlIconSize: 6 * app.baseUnit
    readonly property real headerHeight: 7 * app.baseUnit
    readonly property real preferredContentWidth: 75 * app.baseUnit
    readonly property real maxMenuWidth: 36 * app.baseUnit
    readonly property real baseElevation: 1
    readonly property real raisedElevation: 2
    readonly property real compactThreshold: app.units(496)
    readonly property real heightOffset: isIphoneX ? app.units(20) : 0
    readonly property real widthOffset: isIphoneX && isLandscape ? app.units(40) : 0
    property bool isIphoneX: false
    property bool isWindows7: false
    property bool isIphoneXAndLandscape: mapViewerCore.isNotchAvailable() && !isPortrait
    property real notchHeight: ( Qt.platform.os === "ios") ? ( isPortrait ? getHeightPortrait() : getHeightLandscape() ) : 0
    property bool isPortrait: app.width < app.height
    property real fontScale: app.isDesktop? 0.8 : 1
    readonly property real baseFontSize: fontScale * 14 //app.getProperty("baseFontSize", Qt.platform.os === "windows" ? 10 : 14)
    readonly property real subtitleFontSize: 1.5 * app.baseFontSize
    readonly property real titleFontSize: 2 * app.baseFontSize
    readonly property real textFontSize: 0.9 * app.baseFontSize
    readonly property real labelFontSize: 1.8 * app.baseFontSize
    readonly property real scaleFactor: AppFramework.displayScaleFactor

    property bool isOnline: Networking.isOnline
    readonly property bool isCompact: app.width <= app.compactThreshold
    readonly property bool isMidsized: (app.width > app.compactThreshold) && (app.width <= 800)
    readonly property bool isLarge: !app.isCompact && !app.isMidsized
    readonly property bool isThreeColumn: app.width > 550 * app.scaleFactor
    readonly property bool isLandscape: app.width > app.height
    readonly property bool isDebug: false

    // portal and security
    property url portalUrl:app.getProperty("portalUrl")
    property string portalSortField:app.getProperty("portalSortField","modified")
    property int portalSortOrder:app.getSortOrderAsInt("portalSortOrder")
    property bool supportSecuredMaps: app.getProperty("supportSecuredMaps", false) && isOnline
    property bool enableAnonymousAccess: app.getProperty("enableAnonymousAccess", false)
    property string clientId: mapViewerCore.getClientId()
    property int portalType: 0
    property bool isIWAorPKI: false
    property bool isClientIDNeeded: false
    property bool isWebMapsLoaded: false
    property bool isMMPKsLoaded: false
    property int currentTab: 1//app.showOfflineMapsOnly? 2 : 1
    readonly property string unableToAccessPortal: qsTr("Unable to access portal at this time. Please check the network.")
    readonly property string loginRequiredNotification:  qsTr("Sign in required to access maps for this portal.")
    property var portalUserInfo:({})
    property string routeApiKey: app.getProperty("APIKey","")

    readonly property color primaryColor: app.isDebug ? app.randomColor("primary") : app.getProperty("brandColor", "#166DB2")
    readonly property color backgroundColor: app.isDebug ? app.randomColor("background") : "#EFEFEF"
    readonly property color foregroundColor: app.isDebug ? app.randomColor("foreground") : "#22000000"
    readonly property color separatorColor: Qt.darker(app.backgroundColor, 1.2)
    readonly property color accentColor: Qt.lighter(app.primaryColor)
    readonly property color titleTextColor: app.backgroundColor
    readonly property color subTitleTextColor: Qt.darker(app.backgroundColor)
    readonly property color baseTextColor: Qt.darker(app.subTitleTextColor)
    readonly property color iconMaskColor: "transparent"
    readonly property color black_87: "#DE000000"
    readonly property color white_100: "#FFFFFFFF"
    readonly property color warning_color:"#D54550"
    readonly property url license_appstudio_icon: "./Images/appstudio.png"


    readonly property color darkIconMask: "#4c4c4c"

    readonly property bool canUseBiometricAuthentication: BiometricAuthenticator.supported && BiometricAuthenticator.activated
    property bool hasFaceID: isIphoneX

    // start page
    readonly property color startForegroundColor: app.foregroundColor
    readonly property color startBackgroundColor: app.backgroundColor
    readonly property url startBackground: app.folder.fileUrl(app.getProperty("startBackground"))
    property bool isSignInPageOpened:false
    // gallery page
    property string searchQuery: app.getProperty("galleryMapsQuery")
    readonly property int maxNumberOfQueryResults: app.getProperty("maxNumberOfQueryResults", 20)

    readonly property string feedbackEmail: app.getProperty("feedbackEmail", "")

    readonly property bool hasDisclaimer: app.info.itemInfo.licenseInfo > ""
    property bool showDisclaimer: app.info.propertyValue("showDisclaimer", true)
    property bool disableDisclaimer: app.settings.boolValue("disableDisclaimer", false)
    property bool showMapUnits: true
    property bool showGrid: false
    property bool showGridLabel: false

    // menu
    property bool showBackToGalleryButton: true

    // Use mobile data strings
    readonly property string kUseMobileData: qsTr("Use your mobile data to download the Mobile Map Package %1")
    readonly property string kWaitForWifi: qsTr("Wait for Wi-Fi")

    // Check capabilities
    readonly property string locationAccessDisabledTitle: qsTr("Location access disabled")
    readonly property string locationAccessDisabledMessage: qsTr("Please enable Location access permission for %1 in the device Settings.")
    readonly property string ok_String: qsTr("OK")
    readonly property bool isDesktop: Qt.platform.os === "ios" || Qt.platform.os === "android" ? false:true
    property bool hasLocationPermission:false
    property bool isTablet: (Math.max(app.width, app.height) > 1000 * scaleFactor) || (AppFramework.systemInformation.family === "tablet")

    property string kBackToGallery:qsTr("Back to Gallery")
    property string kBack:qsTr("Back")

    // Offline Routing strings
    // property bool identifyInProgress:false
    property bool isWebMap:false

    // RTL - Internationalization
    property bool isRightToLeft: ( AppFramework.localeInfo().esriName === "ar" || AppFramework.localeInfo().esriName === "he" )

    readonly property string map_title: qsTr("Map Title")
    readonly property string north_arrow: qsTr("North Arrow")
    readonly property string scale_bar: qsTr("Scale Bar")
    readonly property string draw_settings_date: qsTr("Date")
    readonly property string draw_settings_logo: qsTr("Logo")
    readonly property string draw_settings_legend: qsTr("Legend")

    // Animation
    readonly property int normalDuration: 250
    readonly property int fastDuration: 250
    property real maximumScreenWidth: app.width > 1000 * scaleFactor ? 800 * scaleFactor : 568 * scaleFactor

    // EmailComposerErrorMessage
    readonly property string invalid_attachment: qsTr("Invalid attachment.")
    readonly property string attachment_file_not_found: qsTr("Cannot find attachment.")
    readonly property string mail_client_open_failed: qsTr("Cannot open mail client.")
    readonly property string mail_service_not_configured: qsTr("Mail service not configured.")
    readonly property string platform_not_supported: qsTr("Platform not supported.")
    readonly property string send_failed: qsTr("Failed to send email.")
    readonly property string save_failed: qsTr("Failed to save email.")
    readonly property string unknown_error: qsTr("Unknown error.")
    readonly property string invalid_request: qsTr("Invalid Request.")
    readonly property string permission_error: qsTr("Permission Error")
    property bool isPhone:AppFramework.systemInformation.family === "phone"
    property var screenShotsCacheFolder:null
    property var viewerType:({})
    //holds the webmapids for attachmentViewers
    property var attachmentViewers:[]
    //dictionary for storing the attachmentviewerJson<appid,data_json>
    property var viewerJsonDict:({})
    //dictionary for storing the attachmentviewerJson<appid,thumbnailUrl>
    property var thumbnailDict:({})
    //dictionary for storing the attachmentviewerJson<appid,mapid>
    property var appDict:({})
    //dictionary for storing the <webmapid,[appids]>
    property var webmapsDic:({})
    property string templateName:"Nearby"
    property string currentAppId:""
    property var maxAttachmentCount:10
    property string mapSearchText:qsTr("Searching for nearbys ...")
    property bool appOpened:false
    property var urlParameters:({})
    property bool isAppInitialized:false
    property bool isWebMapQueryFinished:false
    property bool appLink:true
    property bool applinkProcessed:false
    property bool searchQueryUpdated:false
    property bool webmapQueryStarted:false

    //this stores the original definition expression defined in the layers
    property var definitionExpressionDic:({})
    property bool canShowStartButton:true
    property string activeSearchTab:app.tabNames.kPlaces
    property string appJsonFolder:"appJsonCache"
    property alias appJsonCacheManager:appJsonCacheManager
    property var authChallenge
    property AuthenticationController controller: AuthenticationController {}

    readonly property var mapsWithMapAreas:[]

    signal fetchedConfiguredApps()
    signal populateGalleryTab()
    signal refreshGallery()
    signal backButtonPressed()


    onFetchedConfiguredApps: app.processAppLink()

    Component.onDestruction: {
        //this is added because on opening secured maps the refreshtoken changes
        if(securedPortal && securedPortal.credential)
            secureStorage.setContent("oAuthRefreshToken", securedPortal.credential.oAuthRefreshToken)
    }


    MapViewerCore{
        id:mapViewerCore

    }

    Strings { id: strings }

    Colors {
        id: colors
    }

    Fonts {
        id: fonts
    }

    Sources {
        id: sources
    }

    function getHeightLandscape() {
        return isNotchAvailable() ? 0 : 20
    }

    function getHeightPortrait() {
        return isNotchAvailable() ? 40 : 20;
    }


    function openSignInPage() {

        if(app.clientId || app.isIWAorPKI)
        {
            app.isWebMapsLoaded = false;
            app.isMMPKsLoaded = false;
            mapViewerCore.createSignInPage()
        }
        else
            messageDialog.show(app.strings.clientID_missing,app.strings.clientID_missing_message)


    }

    //--------------------------------------------------------------------------
    function isNotchAvailable(){
        let unixName

        if ( AppFramework.systemInformation.hasOwnProperty("unixMachine") )
            unixName = AppFramework.systemInformation.unixMachine;

        if ( typeof unixName === "undefined" )
            return false

        if ( unixName.match(/iPhone([1-9][0-9])/) ) {
            switch ( unixName ){
            case "iPhone10,1":
            case "iPhone10,4":
            case "iPhone10,2":
            case "iPhone10,5":
            case "iPhone12,8":
                return false
            default:
                return true
            }
        }

        return false
    }

    function isiPadHomeIndicatorAvailable() {
        var unixName;

        if (AppFramework.systemInformation.hasOwnProperty("unixMachine")){
            unixName = AppFramework.systemInformation.unixMachine;
        }

        // ipad pro 11 inch, ipad pro 12.9 inch
        if (unixName.match(/iPad(8|\d\d)/)) {
            return true;
        }

        if (unixName.match(/iPad(13|\d\d)/)) {
            switch(unixName) {
                //iPad air 4th gen
            case "iPad13,1":
            case "iPad13,2":
                return true;

            default:
                return false;
            }
        }

        return false;
    }

    function getSortOrderAsInt(name)
    {
        let sortorder = app.info.propertyValue(name)
        if(sortorder > "")
        {
            sortorder = sortorder.toLowerCase()
            if(sortorder === "asc")
                return Enums.SortOrderAscending
            else if(sortorder === "desc")
                return Enums.SortOrderDescending
            else
                return Enums.SortOrderDescending

        }
        else
            return Enums.SortOrderDescending

    }

    function getProperty (name, fallback) {
        if (!fallback && typeof fallback !== "boolean") fallback = ""
        return app.info.propertyValue(name, fallback) || fallback
    }

    onFontScaleChanged: {
        app.settings.setValue("fontScale", fontScale)
    }

    property alias baseFontFamily: baseFontFamily.name
    FontLoader {
        id: baseFontFamily

        source: app.folder.fileUrl(app.getProperty("regularFontTTF", ""))
    }

    property alias titleFontFamily: titleFontFamily.name
    FontLoader {
        id: titleFontFamily

        source:  app.folder.fileUrl(app.getProperty("mediumFontTTF", ""))
    }


    //--------------------------------------------------------------------------

    property alias tabNames: tabNames
    QtObject {
        id: tabNames

        property string kLegend: qsTr("LEGEND")
        property string kContent: qsTr("CONTENT")
        property string kInfo: qsTr("INFO")
        property string kBookmarks: qsTr("BOOKMARKS")
        property string kMapAreas: qsTr("MAPAREAS")
        property string kFeatures: qsTr("FEATURES")
        property string kPlaces: qsTr("PLACES")
        property string kBasemaps: qsTr("BASEMAPS")
        property string kElevation: qsTr("ELEVATIONPROFILE")
        property string kMapUnits: qsTr("MAP UNITS")
        property string kOfflineMaps: qsTr("OFFLINE MAPS")
        property string kGraticules: qsTr("GRATICULES")
        property string kMedia: qsTr("MEDIA")
        property string kAttachments: qsTr("ATTACHMENTS")
        property string kRelatedRecords: qsTr("RELATED")
        property string kAbout: qsTr("ABOUT")
        property string kFilters: strings.filter
        property string kDirections: strings.direction
    }

    //--------------------------------------------------------------------------

    property alias stackView: stackView
    StackView {
        id: stackView

        anchors.fill: parent
        initialItem: startPage
    }

    function openMap (portalItem, mapProperties) {

        if (!mapProperties) mapProperties = {"fileUrl": "","isMapArea":false,"mapId":portalItem.id}

        currentAppId = portalItem.viewerId

        stackView.push(mapPage, {destroyOnPop: true, "mapProperties": mapProperties, "portalItem": portalItem})

    }

    //--------------------------------------------------------------------------

    Component {
        id: startPage

        Views.StartPage {
            objectName: "startPage"
            onNext: {
                stackView.push(galleryPage, {destroyOnPop: true})
            }
        }
    }

    Component{
        id:customBtn
        Controls.CustomButton{

        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: galleryPage


        Views.GalleryPage {
            objectName: "galleryPage"

            onPrevious: {
                stackView.pop()
            }

            Component.onCompleted: {
                if(!app.isAppInitialized)
                {
                    if (app.showDisclaimer && app.hasDisclaimer && !app.disableDisclaimer) {
                        app.disclaimerDialog.open()
                    }

                    if((!app.supportSecuredMaps && app.webMapsModel.count === 1) || (app.supportSecuredMaps && app.isSignedIn  && app.webMapsModel.count === 1))
                    {
                        if(!appOpened)
                        {
                            app.openMap(app.webMapsModel.get(0))
                            appOpened = true
                        }
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: mapPage

        NearbyMapPage {
            objectName: "mapPage"
            onPrevious: {

                //this is for the case when the app opened from applink and wants to go back to galleryPage

                if((stackView.currentItem.objectName === "mapPage") && (stackView.depth === 2))
                {
                    app.urlParameters = ({})
                    stackView.replace(mapPage, galleryPage);
                }
                else
                {
                    //this is for handling the case where the map does not load and user wants to go back
                    if((stackView.currentItem.objectName === "mapPage") && (stackView.depth === 3))
                    {
                        stackView.pop()
                    }
                }

                populateGalleryTab()
            }
        }
    }

    NavigationShareSheet {
        id: navigationShareSheetPage
    }

    MapUnitsManager{
        id:mapUnitsManager
    }

    RelatedRecordsManager {
        id: relatedRecordsManager
    }

    LegendManager{
        id:legendManager

    }
    MapAreaManager{
        id:mapAreaManager

    }

    UtilityManager{
        id:utilityManager
    }

    LayerManager{
        id:layerManager

    }

    UtilityFunctions{
        id:utilityFunctions

    }


    //--------------------------------------------------------------------------

    property alias aboutAppPage: aboutAppPage
    Views.AboutAppPage {
        id: aboutAppPage
    }

    Component {
        id:searchPage
        Views.SearchPage{
            objectName:searchPage

        }
    }


    //--------------------------------------------------------------------------

    Component {
        id: webPageComponent

        Controls.WebPage {

        }
    }


    Component {
        id: safariBrowserComponent

        BrowserView {

        }
    }





    Component {
        id: webComponent
        Controls.WebPage {

        }
    }



    //--------------------------------------------------------------------------

    property alias messageDialog: messageDialog
    Controls.MessageDialog {
        id: messageDialog

        Material.primary: app.primaryColor
        Material.accent: app.accentColor
        pageHeaderHeight: app.headerHeight

    }

    //--------------------------------------------------------------------------

    property alias disclaimerDialog: disclaimerDialog
    Views.DisclaimerView {
        id: disclaimerDialog
    }

    //--------------------------------------------------------------------------

    property alias networkConfig: networkConfig
    Controls.NetworkConfig {
        id: networkConfig
    }

    property alias parentCache: parentCache
    Controls.NetworkCacheManager {
        id: parentCache

        subFolder: portalSearch.subFolder
    }

    property alias onlineCache: onlineCache
    Controls.NetworkCacheManager {
        id: onlineCache

        subFolder: [portalSearch.subFolder, portalSearch.onlineFolder].join("/")
    }

    property alias offlineCache: offlineCache
    Controls.NetworkCacheManager {
        id: offlineCache

        subFolder: [portalSearch.subFolder, portalSearch.offlineFolder].join("/")
    }

    property alias offlineMapAreaCache: offlineMapAreaCache
    Controls.NetworkCacheManager {
        id: offlineMapAreaCache
        subFolder: [portalSearch.subFolder, portalSearch.offlineMapAreaFolder].join("/")

    }

    Controls.NetworkCacheManager {
        id: appJsonCacheManager
        //subFolder: [portalSearch.subFolder, app.appJsonFolder].join("/")
        subFolder: ["Nearby", app.appJsonFolder].join("/")

    }




    property alias portalSearch: portalSearch
    Controls.PortalSearch {
        id: portalSearch

        isOnline: app.isOnline
        subFolder: app.appId

        onUpdateModel: {
            if(portalSearch.portal.findItemsStatus === Enums.TaskStatusCompleted){
                portalSearch.populateSearcResultsModel(portalSearch.token)
                if(urlParameters && urlParameters.appid) {
                    var appId = urlParameters.appid
                    let webmapJson = getWebAppForAttachmentViewer(appId)
                    if(webmapJson && !appOpened) {
                        openMap(webmapJson)
                        appOpened = true
                    } else {
                        if(isAppInitialized && webmapQueryStarted && !webmapJson && !appOpened &&  isWebMapQueryFinished && applinkProcessed) {
                            if(app.isSignedIn) {
                                messageDialog.show(strings.error,strings.app_not_found)
                                canShowStartButton = true
                            }
                            else {
                                messageDialog.show(strings.error,strings.app_not_found_beforeSignIn)
                                canShowStartButton = true
                            }
                        }
                    }
                }
            }
        }

        onFindItemsResultsChanged: {
            //            portalSearch.populateSearcResultsModel(portalSearch.token)
        }

        function populateSearcResultsModel (token) {
            webMapsModel.clear()
            localMapPackages.clear()
            onlineMapPackages.clear()

            var flaggedForDeletion = app.settings.value("flaggedForDeletion", "")

            for (var i=0; i<findAttachmentViewerResults.length; i++) {
                var viewerjson = findAttachmentViewerResults[i]
                var appId = viewerjson.id
                var itemJsonArray = findItemsResults.filter(webapp => webapp.viewerId === appId)
                let itemJson = itemJsonArray[0]
                if (!itemJson) continue
                if(securedPortal && securedPortal.credential)
                    token = securedPortal.credential.token
                itemJson.token = token


                switch (itemJson.type) {
                case "Web Map":
                    itemJson.cardState = -2
                    //check the access of the app from the json in findAttachmentViewerResults
                    //and update the access if different

                    var access = viewerjson.access
                    if(access !== "public")
                        itemJson.access = access
                    webMapsModel.append(itemJson)
                    break
                case "Mobile Map Package":
                    if (flaggedForDeletion.indexOf(itemJson.id) !== -1) continue
                    mmpkManager.itemId = itemJson.id
                    if (showPublishedMmpksOnly && !isPublishedMap(itemJson)) continue
                    if (mmpkManager.hasOfflineMap()) {
                        continue
                    } else {
                        if (app.isSignedIn) {
                            itemJson.cardState = -1
                            itemJson.needsUnpacking = false
                            onlineMapPackages.append(itemJson)
                        }
                    }
                }
            }

            if(findAttachmentViewerResults.length === 1) {
                app.showBackToGalleryButton = false
                app.openMap(app.webMapsModel.get(0))
            }
        }

        function populateLocalMapPackages()
        {
            localMapPackages.clear()
            //updateLocalMaps()
            updateLocalMapAreas()
        }

    }

    function isPublishedMap (item) {
        return item.typeKeywords.indexOf("Published Map") !== -1
    }



    function updateLocalMaps () {
        var fileName = "mapinfos.json"


        if (offlineCache.fileInfo.folder.fileExists(fileName)) {
            var fileContent = offlineCache.fileInfo.folder.readJsonFile(fileName)


            localMapPackages.clear()
            if(fileContent.results)
            {
                for (var i=0; i<fileContent.results.length; i++) {
                    fileContent.results[i].cardState = 0;
                    localMapPackages.append(fileContent.results[i])

                }
            }
        }


    }

    function removeMapAreaFromLocal(mapareaid)
    {
        var indx = -1
        for(var k=0;k<localMapPackages.count;k++)
        {
            var item = localMapPackages.get(0)
            if(item.id === mapareaid)
                indx = k
        }
        if(indx > -1)
            localMapPackages.remove(indx)
    }


    function updateLocalMapAreas () {
        var fileName = "mapareasinfos.json"
        //iterate through the subfolders


        if (offlineMapAreaCache.fileInfo.folder.fileExists(fileName)) {
            var fileContent = offlineMapAreaCache.fileFolder.readJsonFile(fileName)
            var indx = localMapPackages.count

            for (var i=0; i<fileContent.results.length; i++) {

                var   basemaps =  fileContent.results[i].basemaps.join(",")
                fileContent.results[i].basemaps = basemaps
                fileContent.results[i].cardState = 0;

                localMapPackages.append(fileContent.results[i])

            }
        }
    }

    function loadViewerJson()
    {

        let fileName =  "appJsoninfos.json"

        var viewerJsonPath = appJsonCacheManager.fileFolder.path + "/"
        let appJsonfileInfo = AppFramework.fileInfo(viewerJsonPath)
        let appJsonFolder = appJsonfileInfo.folder//AppFramework.fileFolder(appJsonBasePath)

        let localnearbyApps = appJsonFolder.folderNames()

        for(var appId of localnearbyApps)
        {
            let _appJsonPath =  viewerJsonPath + appId + "/"  //app.currentAppId + "/"
            let _appJsonFolder = AppFramework.fileFolder(_appJsonPath)

            var appJson = _appJsonFolder.readJsonFile(fileName)
            viewerJsonDict[appId] = appJson

        }


    }

    /* function loadViewerJson()
    {
     let fileName =  "appJsoninfos.json"
      let appJsonBasePath = appJsonCacheManager.storagePath
      // var mapareacontents = [mapAreaPath,mapareaId].join("/")
       let appJsonFolder = AppFramework.fileFolder(appJsonBasePath)
       let localnearbyApps = appJsonFolder.folderNames()
       for(var appId of localnearbyApps)
       {
           let _appJsonPath =  appJsonCacheManager.storagePath + appId   //app.currentAppId + "/"
           let _appJsonFolder = AppFramework.fileFolder(_appJsonPath)

           var appJson = _appJsonFolder.readJsonFile(fileName)
           viewerJsonDict[appId] = appJson
       }


    }*/


    function saveCurrentViewerJson(appId,isUpdate)
    {
        // let _viewerJson = app.viewerJsonDict[appId]
        let appJsonBasePath =     appJsonCacheManager.storagePath + appId + "/"  //app.currentAppId + "/"
        let  appJsonCacheFolder = AppFramework.fileInfo(appJsonBasePath).folder//appJsonCacheManager.fileFolder//AppFramework.fileInfo(appJsonPath).folder
        //appJsonCacheManager.clearAllCache()
        if(isUpdate)
        {
            if(appJsonCacheFolder.exists)
            {
                writeToFile(appJsonBasePath,appId)
            }

        }
        else
        {
            writeToFile(appJsonBasePath,appId)
        }


    }

    function writeToFile(appJsonBasePath,appId){
        let _viewerJson = app.viewerJsonDict[appId]
        let  appJsonCacheFolder = AppFramework.fileInfo(appJsonBasePath).folder//appJsonCacheManager.fileFolder//AppFramework.fileInfo(appJsonPath).folder

        if(appJsonCacheFolder.exists)
            appJsonCacheManager.fileFolder.removeFolder(appId)

        if(!appJsonCacheFolder.exists)
        {
            appJsonCacheFolder.makeFolder()
        }

        let fileName =  "appJsoninfos.json"

        appJsonCacheFolder.writeJsonFile(fileName, _viewerJson)

    }

    property alias webMapsModel: webMapsModel
    ListModel {
        id: webMapsModel
    }

    property alias localMapPackages: localMapPackages
    ListModel {
        id: localMapPackages
    }

    property alias onlineMapPackages: onlineMapPackages
    ListModel {
        id: onlineMapPackages
    }

    property alias mmpkManager: mmpkManager
    Controls.MmpkManager {
        id: mmpkManager

        rootUrl: "%1/sharing/rest/content/items/".arg(portalUrl)
        subFolder: [app.appId, app.portalSearch.offlineFolder].join("/")
    }

    //---------------------------PORTAL-----------------------------------------

    property Portal portal: isSignedIn ? securedPortal : publicPortal
    property Portal securedPortal
    property Portal publicPortal

    property bool isSignedIn: app.securedPortal ? app.securedPortal.loadStatus === Enums.LoadStatusLoaded &&app.securedPortal.credential && app.securedPortal.credential.token > "" : false

    onIsSignedInChanged: {
        if (isSignedIn) {
            if(app.securedPortal.credential.authenticationType !== 0)
                portalType = app.securedPortal.credential.authenticationType;

            if(portalType === 1 )
                mapViewerCore.setRefreshToken();
            else if(portalType === 2 || portalType === 3)
                mapViewerCore.setUserNamePswd();

            refreshTokenTimer.start()

            if(app.securedPortal.portalUser) {
                portalUserInfo = app.securedPortal.portalUser;
            }

        } else {
            if (!refreshTokenTimer.isRefreshing) {
                mapViewerCore.clearRefreshToken()
            }
            refreshTokenTimer.stop()
            loadPublicPortal()

            portalUserInfo = {};
        }
    }

    Connections {
        target: app

        function onIsOnlineChanged() {

            if(!app.isOnline)
            {
                toastMessage.isBodySet = false
                toastMessage.show(qsTr("Your device is now offline."))
            }
        }
    }

    function loadSecuredPortal (callback) {
        var autoSignInProps = mapViewerCore.getAutoSignInProps()
        var failTimes = 0;

        var credentialInfo = {
            password:autoSignInProps.password,
            oAuthRefreshToken:autoSignInProps.oAuthRefreshToken,
            username:autoSignInProps.username
        }
        var credential = mapViewerCore.createCredential(app.clientId, credentialInfo, autoSignInProps.tokenServiceUrl)
        app.securedPortal = ArcGISRuntimeEnvironment.createObject("Portal", {url: portalUrl, credential: credential, sslRequired: false})

        app.securedPortal.onLoadStatusChanged.connect(function(){
            if(app.securedPortal.credential)
                if (app.securedPortal.credential.authenticationType !== 0) {
                    app.portalType = app.securedPortal.credential.authenticationType;
                    if(app.portalType === 2 || portalType === 3){
                        supportSecuredMaps = true;
                        isIWAorPKI = true;

                        //if the platform is windows, the app will automatically sign you in using iwa, so no need to have skip button
                        if (Qt.platform.os === "windows") enableAnonymousAccess = false;
                    }
                }

            switch (securedPortal.loadStatus) {
            case Enums.LoadStatusFailedToLoad:

                if(failTimes<3){

                    securedPortal.retryLoad();
                    ++failTimes;
                }else {
                    if(securedPortal.error.code === 404)
                        messageDialog.show(qsTr("Error"),unableToAccessPortal);
                    mapViewerCore.signOut()
                    mapViewerCore.clearRefreshToken()
                    loadPublicPortal();
                    if (mapViewerCore.hasVisibleSignInPage()) {
                        mapViewerCore.destroySignInPage()
                    }
                }
                break
            case Enums.LoadStatusLoaded:
                portalSearch.clearResults()
                webMapsModel.clear()
                localMapPackages.clear()
                onlineMapPackages.clear()
                portalSearch.findAttachmentViewerResults = []
                isWebMapQueryFinished = false
                applinkProcessed = false

                if(securedPortal.credential) {
                    webmapQueryStarted = false
                    var promiseToFindPortalItems = mapViewerCore.credentialChanged(securedPortal.credential.token)
                    app.searchQuery = app.getProperty("galleryMapsQuery")
                    if(app.searchQuery) {
                        portalSearch.findItems(securedPortal,attachmentviewerqueryParameters)
                        var getattachmentqueryitemspromise = new Promise((resolve, reject) =>{
                                                                             securedPortal.onFindItemsStatusChanged.connect(function(){
                                                                                 if(securedPortal.findItemsStatus === Enums.TaskStatusCompleted){
                                                                                     //fetch the attachmentquery webmaps
                                                                                     portalSearch.searchAttachmentViewers(resolve)
                                                                                 }
                                                                             })
                                                                         });

                        getattachmentqueryitemspromise.then(function(){
                            if(urlParameters.appid)
                                processAppLink()
                            else {
                                webmapQueryStarted = true
                                queryForWebmap(securedPortal)
                            }
                        })
                    }
                    else
                        app.mapSearchText = strings.no_nearbys_available;

                    securedPortal.fetchBasemaps()
                }
                if (app.settings.value("useBiometricAuthentication", "") !== true &&
                        app.settings.value("useBiometricAuthentication", "") !== false &&
                        app.canUseBiometricAuthentication) {
                    biometricController.showBiometricDialog()
                }
                break
            }
        })

        portalSearch.clearResults()
        app.securedPortal.load()

        if (callback) callback()
    }


    function loadPublicPortal () {
        var failTimes = 0;
        if (publicPortal) publicPortal.destroy()
        portalSearch.clearResults()
        app.publicPortal = ArcGISRuntimeEnvironment.createObject("Portal", {url: portalUrl})
        app.publicPortal.onLoadStatusChanged.connect(function(){
            if (app.publicPortal.credential)
                if (app.publicPortal.credential.authenticationType!== 0) {
                    app.portalType = app.publicPortal.credential.authenticationType;
                    if(app.portalType === 2 || portalType === 3){
                        supportSecuredMaps = true;
                        isIWAorPKI = true;

                        //if the platform is windows, the app will automatically sign you in using iwa, so no need to have skip button
                        if (Qt.platform.os === "windows") enableAnonymousAccess = false;

                    }
                }

            switch (publicPortal.loadStatus) {
            case Enums.LoadStatusFailedToLoad:
                if(failTimes <3){
                    publicPortal.retryLoad();
                    ++failTimes;
                }else{

                    //iwa or pki but has network error
                    if(portalType === 0){
                        supportSecuredMaps = true;
                        isIWAorPKI = true;
                    }
                }
                break
            case Enums.LoadStatusLoaded:
                portalSearch.clearResults()
                webMapsModel.clear()
                localMapPackages.clear()
                onlineMapPackages.clear()
                applinkProcessed = false
                isWebMapQueryFinished = false
                portalSearch.findAttachmentViewerResults = []
                app.searchQuery = app.getProperty("galleryMapsQuery")
                if(!app.searchQuery && app.urlParameters.appid)
                {
                    // create the query for applink if present
                    app.searchQuery = "id:"+ urlParameters.appid
                }

                //if (app.showAllMaps){
                if(app.searchQuery)
                {
                    portalSearch.findItems(publicPortal,attachmentviewerqueryParameters)
                    var getattachmentqueryitemspromise = new Promise((resolve, reject) =>{
                                                                         publicPortal.onFindItemsStatusChanged.connect(function(){
                                                                             if(publicPortal.findItemsStatus === Enums.TaskStatusCompleted)
                                                                             {
                                                                                 portalSearch.searchAttachmentViewers(resolve)

                                                                             }
                                                                         })
                                                                     });

                    getattachmentqueryitemspromise.then(function(){
                        if(urlParameters.appid)
                            processAppLink()
                        else
                        {
                            if(portalSearch.findAttachmentViewerResults.length > 0)
                            {
                                webmapQueryStarted = true
                                queryForWebmap(publicPortal)
                            }

                        }

                    })
                }
                else
                    app.mapSearchText = strings.no_nearbys_available;

                publicPortal.fetchBasemaps()
                break
            }
        })
        app.publicPortal.load();
    }

    function queryForWebmap(portal) {
        var promise = new Promise((resolve, reject) =>{
                                      portal.onFindItemsStatusChanged.connect(function(){
                                          if(portal.findItemsStatus === Enums.TaskStatusCompleted){
                                              portalSearch.searchEventHandler();
                                              isWebMapQueryFinished = true
                                              isAppInitialized = true
                                              portalSearch.updateModel()
                                          }
                                      })
                                  });
        portalSearch.findItems(portal, queryParameters)
    }

    PortalQueryParametersForItems {
        id: attachmentviewerqueryParameters

        types: {
            return [Enums.PortalItemTypeWebMappingApplication]

        }
        searchString: app.searchQuery
        sortOrder: app.portalSortOrder//Enums.PortalQuerySortOrderDescending
        sortField: app.portalSortField//"modified"
        limit: app.maxNumberOfQueryResults
        //        searchPublic: true
    }


    PortalQueryParametersForItems {
        id: queryParameters

        types: {
            //if (app.showAllMaps) {
            return [Enums.PortalItemTypeWebMap]
            //            } else if (app.showOfflineMapsOnly) {
            //                return [Enums.PortalItemTypeMobileMapPackage]
            //            } else {
            //                return [Enums.PortalItemTypeWebMap]
            //            }
        }
        searchString: app.searchQuery
        sortOrder: app.portalSortOrder//Enums.PortalQuerySortOrderDescending
        sortField: app.portalSortField//"modified"
        limit: app.maxNumberOfQueryResults
        //        searchPublic: true
    }

    QueryParameters {
        id: spatialqueryParameters
    }

    //--------------------------------------------------------------------------

    Controls.SecureStorageHelper {
        id: secureStorage
    }

    //------------------BIOMETRIC AUTHENTICATION--------------------------------

    Connections {
        id: biometricController

        property var biometricDialogs: []
        readonly property string kTouchIdFailed: qsTr("Unable to verify using Touch ID. Please sign in again.")
        readonly property string kFaceIdFailed: qsTr("Unable to verify using Face ID. Please sign in again.")

        target: BiometricAuthenticator

        function onAccepted() {
            loadSecuredPortal()
        }

        function onRejected() {
            mapViewerCore.signOut()
            mapViewerCore.clearRefreshToken()
            messageDialog.show("", app.hasFaceID ? biometricController.kFaceIdFailed : biometricController.kTouchIdFailed)
        }

        function showBiometricDialog () {
            biometricController.destroyBiometricDialogs()
            var biometricDialog = biometricDialogComponent.createObject(app)
            biometricDialog.open()
            biometricController.biometricDialogs.push(biometricDialog)
        }

        function destroyBiometricDialogs () {
            for (var i=0; i<biometricController.biometricDialogs.length; i++) {
                if (biometricController.biometricDialogs[i]) {
                    biometricController.biometricDialogs[i].destroy()
                }
            }
            biometricController.biometricDialogs = []
        }
    }

    Component {
        id: biometricDialogComponent

        Controls.MessageDialog {
            id: biometricDialog

            readonly property string kEnableTouchId: Qt.platform.os === "ios" || Qt.platform.os === "osx" ? qsTr("Enable Touch ID to sign in?") : qsTr("Enable Fingerprint Reader to sign in")
            readonly property string kEnableFaceId: qsTr("Enable Face ID to sign in?")
            readonly property string kTouchIdEnabled: qsTr("Touch ID enabled. Sign out to disable.")
            readonly property string kFaceIdEnabled: qsTr("Face ID enabled. Sign out to disable.")

            Material.primary: app.primaryColor
            Material.accent: app.accentColor
            title: app.hasFaceID ? kEnableFaceId : kEnableTouchId
            text: qsTr("Once enabled, the app will provide an easy and secured way to access your maps. You can always sign out at anytime to disable this feature.")
            standardButtons: Dialog.NoButton

            footer: DialogButtonBox {
                Button {
                    text: qsTr("Cancel")
                    Material.background: "transparent"
                    DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                }
                Button {
                    text: qsTr("Enable")
                    Material.background: "transparent"
                    DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                }
            }

            onAccepted: {
                app.settings.setValue("useBiometricAuthentication", true)
                toastMessage.show(app.hasFaceID ? kFaceIdEnabled : kTouchIdEnabled)
                biometricDialog.destroy()
            }

            onRejected: {
                app.settings.setValue("useBiometricAuthentication", false)
                biometricDialog.destroy()
            }
        }
    }

    //--------------------------------------------------------------------------

    Controls.ToastDialog {
        id: toastMessage
        isBodySet: false

        enter: Transition {
            NumberAnimation { property: "y"; from:parent.height; to:parent.height - (toastMessage.isBodySet?units(76):units(56))}
        }
        exit:Transition {
            NumberAnimation { property: "y"; from:parent.height - (toastMessage.isBodySet?units(76):units(56)); to:parent.height}
        }

        textColor: app.titleTextColor
    }



    //--------------------------------------------------------------------------

    property var signInPages: []

    Component {
        id: signInPageComponent

        Views.SignInPage {

            portal: app.securedPortal
            iconSize: app.iconSize
            headerHeight: app.headerHeight

            onCloseButtonClickedChanged: {
                if (closeButtonClicked) {
                    mapViewerCore.signOut()
                }
            }
        }
    }


    //--------------------------------------------------------------------------

    focus: true
    Keys.onPressed: {
        if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape){
            event.accepted = true
            app.urlParameters = {}

            backButtonPressed ()
        }
    }

    onBackButtonPressed: {
        if (aboutAppPage.visible) {
            aboutAppPage.close()
        } else if (mapViewerCore.hasVisibleSignInPage()) {

            mapViewerCore.destroySignInPage()
        }

    }

    //--------------------------------------------------------------------------

    property alias refreshTokenTimer: refreshTokenTimer
    Timer {
        id: refreshTokenTimer

        property bool isRefreshing: false
        property date lastRefreshed: new Date()

        signal tokenRefreshed ()

        onTokenRefreshed: {
            lastRefreshed = new Date()
        }

        interval: 1800000 // 30 minutes
        running: false
        repeat: true

        onTriggered: {
            refreshToken ()
        }

        function refreshToken () {
            isRefreshing = true
            getNewToken(function () {
                isRefreshing = false
                tokenRefreshed()
            })

        }

        function getNewToken(){
            var autoSignInProps = mapViewerCore.getAutoSignInProps()

            var credentialInfo = {
                password:autoSignInProps.password,
                oAuthRefreshToken:autoSignInProps.oAuthRefreshToken,
                username:autoSignInProps.username
            }

            var credential = mapViewerCore.createCredential(app.clientId, credentialInfo, autoSignInProps.tokenServiceUrl)

            securedPortal.credential = credential;

            if(portalType === 1 )
                mapViewerCore.setRefreshToken();
            else if(portalType === 2 || portalType === 3)
                mapViewerCore.setUserNamePswd();

        }
    }

    Connections {
        target: Qt.application

        function onStateChanged() {
            switch (Qt.application.state) {
            case Qt.ApplicationActive:
                var autoSignInProps = mapViewerCore.getAutoSignInProps()
                if (autoSignInProps.oAuthRefreshToken && autoSignInProps.tokenServiceUrl && app.supportSecuredMaps) {
                    if (!refreshTokenTimer.isRefreshing && (new Date() - refreshTokenTimer.lastRefreshed >= refreshTokenTimer.interval)) {
                        refreshTokenTimer.refreshToken()
                    }
                }
                if(!isOnline)
                    toastMessage.show(strings.show_offline_message)

            }
        }
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        initialize()
    }

    function initialize () {
        let isSignedOut = false

        if(StatusBar.supported && Qt.platform.os === "ios") {
            StatusBar.theme = StatusBar.Dark;
        }

        mapViewerCore.setPortalUrl();
        var autoSignInProps = mapViewerCore.getAutoSignInProps()
        mapViewerCore.setSystemProps()

        if (app.isOnline){
            if (app.supportSecuredMaps && autoSignInProps.username > "" && (app.portalUrl.toString() !== app.settings.value("portalUrl") || autoSignInProps.clientId !== app.clientId)) {
                AuthenticationManager.credentialCache.removeAllCredentials()
                mapViewerCore.clearRefreshToken()
                isSignedOut = true
            }
            else{
                //check whether autosign in is possible
                if ((autoSignInProps.oAuthRefreshToken > ""||autoSignInProps.password > "") && autoSignInProps.tokenServiceUrl > "" && autoSignInProps.previousPortalUrl === app.portalUrl.toString()) {
                    if (app.isOnline && app.settings.value("useBiometricAuthentication", false) && app.canUseBiometricAuthentication) {
                        if (Qt.platform.os === "osx") {
                            BiometricAuthenticator.message = qsTr("authenticate")
                        } else {
                            BiometricAuthenticator.message = qsTr("Please authenticate to proceed.")
                        }
                        BiometricAuthenticator.authenticate()
                    } else {
                        loadSecuredPortal()
                    }
                } else {
                    if(!isSignedOut){
                        AuthenticationManager.credentialCache.removeAllCredentials()
                        mapViewerCore.clearRefreshToken()
                    }
                }
            }
        }
        else
        {
            loadViewerJson()
            portalSearch.populateLocalMapPackages()
        }
        //loadViewerJson()
        //portalSearch.populateLocalMapPackages()
        app.fontScale = app.settings.value("fontScale", 1.0)
    }

    function units (num) {
        return num ? num * AppFramework.displayScaleFactor : num
    }

    onOpenUrl : {
        if(app.isOnline)
            canShowStartButton = false
        webmapQueryStarted = false

        var urlInfo = AppFramework.urlInfo(url);

        if (urlInfo.hasQuery) {
            var inputparameters = urlInfo.queryParameters;

            var parameters = {}
            //convert all the parameters to lowercase
            for(var prop in inputparameters){
                var propStr = prop.toString()
                var suppliedprop = propStr.toLowerCase()
                //need to just the change the mapping in case the parameters are different
                switch(suppliedprop){
                case "appid":
                    parameters["appid"] = inputparameters[prop]
                    break
                case "layerid":
                    parameters["layerid"] = inputparameters[prop]
                    break
                case "objectid":
                    parameters["objectid"] = inputparameters[prop]

                }

            }

            urlParameters = parameters
            var urlString = String(url).toLowerCase()

            if(urlParameters)
            {

                if(urlParameters.appid)
                {
                    if(isAppInitialized)
                    {
                        backButtonPressed()
                        processAppLink()
                    }

                }

            }

        }
    }

    function processAppLink()
    {
        while (stackView.depth > 2)
            stackView.pop()
        appOpened = false
        applinkProcessed = true
        var appId = urlParameters.appid
        if(appId)
        {
            let webapp = getWebAppForAttachmentViewer(appId)
            if(!webapp)
            {
                fetchAttachmentViewer(appId)
            }
            else
            {
                if(!appOpened)
                    app.openMap(webapp)
            }


        }
    }




    //check if the app is already fetched
    function getWebAppForAttachmentViewer(appId)
    {
        for(let k=0;k<webMapsModel.count;k++)
        {
            let webmapJson =  webMapsModel.get(k)
            if(webmapJson.viewerId === appId)
            {
                return webmapJson

            }
        }
        return ""

    }

    function fetchAttachmentViewer(appId,resolve)
    {
        app.searchQuery = "id:"+appId
        appLink = true
        //portalSearch.findItems(publicPortal,attachmentviewerqueryParameters)
        searchAttachmentViewers_applink(resolve)

    }

    //it will search the app passed in app link and after getting it
    //it will search the webapp associated with the viewer. The event is already
    //attached with the findItems in SearchAttachmentViewers method
    function searchAttachmentViewers_applink(resolve)
    {
        if(app.isSignedIn)
        {
            portalSearch.findItems(securedPortal,attachmentviewerqueryParameters)

        }
        else
        {
            portalSearch.findItems(publicPortal,attachmentviewerqueryParameters)

        }

    }

}
