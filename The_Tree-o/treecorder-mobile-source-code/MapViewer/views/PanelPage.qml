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
import QtQuick.Layouts 1.1
import QtQuick.Controls.Material 2.1

import Esri.ArcGISRuntime 100.14

import "../controls" as Controls
import "../../Nearby/views"

Controls.Panel {
    id: panelPage

    property MapView mapView:null
    property string mapTitle:""
    property string mapWelcomeText: ""
    property string owner:""
    property string modifiedDate:""

    property var headerTabNames: []
    property real headerRowHeight: 0.8 * app.headerHeight + ( panelPage.fullView ? app.notchHeight : 0 )
    property real preferredContentHeight:(panelPage.fullView ? (app.isLarge ? panelContent.parent.height - 55 * scaleFactor : parent.height - panelHeaderHeight) : parent.height - panelPage.pageExtent - panelHeaderHeight)
    property real tabButtonHeight: headerRowHeight
    property bool willDockToBottom:false
    property bool screenWidth:app.isLandscape
    property alias tabBar:tabBar
    property alias relatedDetails:relateddetails
    property alias panelContent:panelContent
    property bool isFull:false
    property color customColor: app.primaryColor

    signal hidepanelPage()
    signal dockToBottom()
    signal dockToLeft()
    signal dockToTop()
    signal dockToTopReduced()


    separatorColor: app.separatorColor
    panelHeaderHeight: headerRowHeight
    defaultMargin: app.defaultMargin
    appHeaderHeight: app.headerHeight
    headerBackgroundColor: app.backgroundColor
    backgroundColor: "#FFFFFF"
    isIntermediateScreen:false
    iconSize: app.iconSize
    property string headerText:""
    property int currentIndex:0

    LayoutMirroring.enabled: app.isRightToLeft
    LayoutMirroring.childrenInherit: app.isRightToLeft


    onExpandButtonClicked: {

        dockToTop()
    }

    onScreenWidthChanged: {
        if ( !app.isLandscape ){
            willDockToBottom = true
            dockToBottom()
            panelContent.state = "SMALL"

        } else{
            willDockToBottom = false
            dockToLeft()

        }
    }


    content: Item{
        width:parent.width

        ColumnLayout{
            id:relateddetails
            visible:false
            anchors.fill: parent
            spacing: 0

            ToolBar {

                id: identifyRelatedFeaturesViewheader

                Layout.preferredHeight:headerRowHeight
                Layout.fillWidth: true
                Material.background: headerBackgroundColor
                Material.elevation: 0

                RowLayout {
                    anchors.fill: parent
                    Controls.Icon {
                        id: closeBtn

                        visible: true
                        imageSource: "../controls/images/back.png"

                        leftPadding: 16 * scaleFactor

                        Material.background: app.backgroundColor
                        Material.elevation: 0
                        maskColor: "#4c4c4c"
                        onClicked: {
                            relateddetails.visible=false
                            panelContent.visible=true
                            isHeaderVisible = true

                        }
                    }

                    Rectangle{
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        color:"transparent"

                        Controls.BaseText {

                            width:parent.width

                            text: headerText
                            maximumLineCount: 1

                            anchors.centerIn: parent

                            elide: Text.ElideRight

                            color: app.baseTextColor
                            font {
                                pointSize: app.textFontSize
                            }
                            rightPadding: app.units(16)
                        }

                    }
                }
            }


            ListView {
                id: identifyRelatedFeaturesViewlst
                Layout.fillWidth: true
                Layout.fillHeight: true


                clip: true

                delegate: ColumnLayout {
                    id: contentColumn

                    width: parent.width
                    spacing: 0

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: app.units(6)
                    }

                    Controls.SubtitleText {
                        id: lbl

                        objectName: "label"


                        text: typeof FieldName !== "undefined" ? (FieldName ? FieldName : "") : ""
                        Layout.fillWidth: true

                        Layout.preferredHeight: visible ? implicitHeight:0
                        Layout.leftMargin: app.defaultMargin
                        Layout.rightMargin: app.defaultMargin
                        Layout.bottomMargin: 6 * scaleFactor

                        wrapMode: Text.WrapAnywhere
                    }



                    Controls.BaseText {
                        id: desc
                        Layout.preferredWidth: parent.width - 16 * scaleFactor
                        objectName: "description"
                        text: typeof FieldValue !== "undefined" ? (FieldValue ? FieldValue : "") : ""
                        //Layout.preferredHeight: visible ? implicitHeight:0
                        Layout.leftMargin: app.units(16)
                        Layout.rightMargin: app.units(16)
                        rightPadding: app.units(16)
                        Layout.bottomMargin: 10 * scaleFactor
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.Wrap
                        textFormat: Text.StyledText
                        Material.accent: app.accentColor
                    }

                }

            }

        }

        ColumnLayout {
            id: panelContent
            visible:true
            anchors.fill:parent
            spacing: 0

            TabBar {
                id: tabBar
                Layout.topMargin: 0
                Layout.fillWidth: true
                clip: true

                visible: tabView.model.length > 1

                padding: 0

                Material.primary: app.primaryColor
                currentIndex: swipeView.currentIndex
                position: TabBar.Header
                Material.accent: app.primaryColor
                Material.background: headerBackgroundColor

                property alias tabView: tabView
                Repeater {
                    id: tabView

                    model: panelPage.headerTabNames
                    anchors.horizontalCenter: parent.horizontalCenter

                    TabButton {
                        id: tabButton

                        contentItem: Controls.BaseText {
                            text: modelData
                            color: tabButton.checked ? (app.primaryColor) : app.subTitleTextColor
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }
                        clip: true
                        padding: 0
                        background.height: height
                        height: tabButtonHeight
                        width: Math.max(100,(panelContent.width)/tabView.model.length)
                    }
                }
            }


            Rectangle{
                Layout.fillWidth: true
                Layout.fillHeight: true
                SwipeView {
                    id: swipeView

                    property QtObject currentView

                    clip: true
                    anchors.fill:parent
                    bottomPadding: !panelPage.fullView ? app.heightOffset : 0
                    Material.background:"#FFFFFF"
                    currentIndex: tabBar.currentIndex
                    interactive: false

                    Repeater {
                        id: swipeViewDelegate

                        model: tabBar.tabView.model.length
                        Loader {
                            active: SwipeView.isCurrentItem || SwipeView.isNextItem || SwipeView.isPreviousItem
                            visible: SwipeView.isCurrentItem
                            sourceComponent: swipeView.currentView
                        }
                    }

                    onCurrentIndexChanged: {
                        addDataToSwipeView (swipeView.currentIndex)
                    }

                    Component.onCompleted: {
                        addDataToSwipeView (swipeView.currentIndex)
                    }

                    function addDataToSwipeView (index) {
                        index = tabBar.currentIndex
                        isExpandIconVisible = true
                        isMoreMenuVisible = false
                        if (panelPage.headerTabNames.length <= 0) return
                        switch (panelPage.headerTabNames[index]) {
                        case app.tabNames.kMapAreas:
                            swipeView.currentView = mapAreasView
                            break
                        case app.tabNames.kLegend:
                            legendManager.sortLegendContentByLyrIndex()
                            swipeView.currentView = legendView
                            break
                        case app.tabNames.kContent:
                            if(mapView.contentsModel.count === 0)
                                legendManager.sortLegendContent()
                            swipeView.currentView = contentView
                            break
                        case app.tabNames.kAbout:
                            mapView.updateMapInfo()
                            swipeView.currentView = infoView
                            break
                        case app.tabNames.kBookmarks:
                            swipeView.currentView = bookmarksView
                            break
                        case app.tabNames.kBasemaps:
                            swipeView.currentView = basemapsView
                            break
                        case app.tabNames.kMapUnits:
                            swipeView.currentView = mapunitsView
                            break
                        case app.tabNames.kGraticules:
                            swipeView.currentView = graticulesView
                            break
                        case app.tabNames.kFeatures:
                            swipeView.currentView = identifyFeaturesView
                            break
                        case app.tabNames.kAttachments:
                            swipeView.currentView = identifyAttachmentsView
                            break
                        case app.tabNames.kRelatedRecords:
                            swipeView.currentView = identifyRelatedFeaturesView
                            break
                        case app.tabNames.kMedia:
                            swipeView.currentView = identifyMediaView
                            break
                        case app.tabNames.kOfflineMaps:
                            swipeView.currentView = offlineMapsView
                            break
                        case app.tabNames.kFilters:
                            swipeView.currentView = filtersView
                            break

                        case app.tabNames.kDirections:
                            swipeView.currentView = routeView
                            break
                        default:
                            let _view = mapPage.getCurrentView(panelPage.headerTabNames[index])
                            //isExpandIconVisible = false
                            isMoreMenuVisible = true
                            swipeView.currentView = _view

                        }
                    }
                }
            }

            Rectangle{
                id:bottomRect
                Layout.fillWidth: true
                Layout.preferredHeight:app.units(5)
            }

        }
    }


    function hideFullView()
    {
        panelPage.collapseFullView()
    }

    //--------------------------------------------------------------------------
    function hideDetailsView()
    {
        relateddetails.visible=false
        panelContent.visible = true
    }

    function showFeaturesView()

    {
        relateddetails.visible=false
        panelContent.visible = true
        panelPage.isHeaderVisible = true
        swipeView.addDataToSwipeView(0)
        tabBar.currentIndex = 0
    }


    function showMapAreas()
    {
        relateddetails.visible=false
        panelContent.visible = true
        panelPage.isHeaderVisible = true
        swipeView.addDataToSwipeView(0)
        tabBar.currentIndex = 0
    }

    onCurrentIndexChanged: {
        swipeView.currentIndex = 0
    }

    onVisibleChanged: {
        if (!visible) {
            app.focus = true
        }
    }

    onNextButtonClicked: {

    }

    onPreviousButtonClicked: {

    }

    Component {
        id: defaultListModel

        ListModel {
        }
    }

    //--------------------------------------------------------------------------

    onCurrentPageNumberChanged: {
        if (visible) {
            mapView.identifyProperties.highlightFeature(currentPageNumber-1,true)
            mapView.identifyProperties.currentFeatureIndex = currentPageNumber-1
        }
    }

    Connections {
        target: mapView ? mapView.identifyProperties:null



        function onPopupManagersCountChanged() {
            if (mapView.identifyProperties.popupManagers.length) {
                pageCount = mapView.identifyProperties.popupManagers.length
                currentPageNumber = 1
            }
        }
    }

    Component {
        id: identifyFeaturesView

        IdentifyFeaturesView {
            id: featuresView
            model:attrListModel

            Component.onCompleted: {
                featuresView.bindModel()
            }

            Connections {
                target: mapView.identifyProperties

                onPopupManagersCountChanged: {
                    attrListModel.clear()
                    featuresView.bindModel()
                }

                onCurrentFeatureIndexChanged:{
                    attrListModel.clear()
                    featuresView.bindModel()
                }
            }

            Controls.CustomListModel {
                id: attrListModel
            }

            function bindModel() {

                try {
                    featuresView.layerName = ""
                    featuresView.popupTitle = ""

                    var popupManager = mapView.identifyProperties.popupManagers[mapView.identifyProperties.currentFeatureIndex]//[currentPageNumber-1]
                    if(popupManager.objectName)
                        featuresView.layerName = popupManager.objectName.toString()
                    if(popupManager.title)
                        featuresView.popupTitle = popupManager.title
                    if(popupManager)
                    {

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
                }catch (err) {
                    //featuresView.layerName = ""

                }

            }

        }


    }



    //
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
        var newHtmlText = utilityFunctions.scrubHtml(customHtml)
        attrListModel.append({
                                 "description": newHtmlText,
                                 "label":"",
                                 "fieldValue":""

                             })


    }



    function populateModel(popupManager,attrListModel)
    {
        attrListModel.clear()
        var popupModel = popupManager.displayedFields
        if (popupModel.count) {

            var feature1 = mapView.identifyProperties.features[currentPageNumber-1]
            var visiblefields = mapView.identifyProperties.fields[currentPageNumber-1]
            var attributeJson1 = feature1.attributes.attributesJson
            //attrListModel.clear()
            var _featuretable  = feature1.featureTable
            var fields = _featuretable.fields

            for(var key in visiblefields)
            {
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
                if(exprfld.length > 1)
                {
                    var expr =exprfld[1]
                    var exprResults = popupManager.evaluateExpressionsResults
                    for(var k = 0;k<popupManager.evaluateExpressionsResults.length;k++)
                    {
                        var exprobj = popupManager.evaluateExpressionsResults[k].popupExpression
                        if(exprobj.name === expr)
                        {
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

                if(!_fieldVal)
                {


                    var fieldValAttrJson = app.getCodedValue(fields,fldname,attributeJson1[fldname])
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
            var feature = mapView.identifyProperties.features[currentPageNumber-1]
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

    function getFormattedFieldValue(_fieldVal)
    {


        var isNotNumber = isNaN(_fieldVal)
        if(_fieldVal && !isNotNumber)
        {
            var formattedVal = _fieldVal.toLocaleString(Qt.locale())
            if(formattedVal)
                _fieldVal = formattedVal
        }
        //check if it is a date
        var dt = Date.parse(_fieldVal)
        if(dt)
        {
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

    function getPopupFieldValue(popupManager,fieldName)
    {

        var _popupfield = popupManager.fieldByName(fieldName)
        var fieldVal = popupManager.formattedValue(_popupfield)
        return fieldVal
    }

    function doesInclude(fields,key)
    {
        for(var k=0;k<fields.length;k++)
        {
            var field = fields[k]
            if(field.fieldName.toUpperCase() === key.toUpperCase())
                return true
        }
        return false
    }

    //--------------------------------------------------------------------------

    Component {
        id: identifyAttachmentsView

        IdentifyAttachmentsView {
            id: attachementsView

            Component.onCompleted: {
                attachementsView.bindModel()
            }

            Connections {
                target: mapView.identifyProperties

                onPopupManagersCountChanged: {
                    attachementsView.bindModel()

                }
            }

            Connections {
                target: panelPage

                onCurrentPageNumberChanged: {
                    //attachementsView.bindModel()
                    attachementsView.busyIndicator.visible = true
                }
            }

            function bindModel () {
                attachementsView.busyIndicator.visible = true
                attachementsView.model = defaultListModel
                attachementsView.model = Qt.binding(function () {
                    try {
                        var popupManager = mapView.identifyProperties.popupManagers[currentPageNumber-1]
                        if(popupManager.objectName)
                            attachementsView.layerName = popupManager.objectName.toString()
                        if(popupManager.title)
                            attachementsView.popupTitle = popupManager.title
                        return popupManager.attachmentManager.attachmentsModel
                    } catch (err) {
                        attachementsView.layerName = ""
                        return defaultListModel
                    }
                })
            }
        }
    }




    Component{
        id:identifyRelatedFeaturesView
        IdentifyRelatedFeaturesView {
            id:relatedFeaturesView
            featureList:relatedFeaturesModel

            Component.onCompleted: {
                relatedFeaturesView.bindModel()
            }
            Controls.CustomListModel {
                id: relatedFeaturesModel
            }

            Connections {
                target: mapView.identifyProperties

                onPopupManagersCountChanged: {
                    relatedFeaturesView.bindModel()
                }
                onCurrentFeatureIndexChanged:{

                    relatedFeaturesView.bindModel()
                }
            }


            Connections {
                target: panelPage

                onCurrentPageNumberChanged: {
                    relatedFeaturesView.bindModel()

                }
            }

            function getFeatureList()
            {
                relatedFeaturesModel.clear()
                var relatedFeatures = mapView.identifyProperties.relatedFeatures[currentPageNumber-1]

                var sortedFeatures =   getSortedRelatedFeatures(relatedFeatures)
                sortedFeatures.forEach(function(obj){
                    relatedFeaturesModel.append((obj))
                }
                )

            }

            function bindModel () {
                getFeatureList()

            }

            function getSortedRelatedFeatures(relatedFeaturesList)
            {
                var relatedFeatures = []
                if(relatedFeaturesList)
                {
                    relatedFeaturesList.forEach(function(feature){
                        var fclass = feature["serviceLayerName"]
                        var displayField = feature["displayFieldName"]


                        var fclassObject =  relatedFeatures.filter(function(featObj) {
                            return featObj.serviceLayerName === fclass;
                        });
                        if(fclassObject && fclassObject.length > 0)
                        {
                            relatedFeatures.map(function(featObj) {
                                if (featObj["serviceLayerName"] === fclass)
                                {
                                    var isPresent = false

                                    if(!isPresent)
                                    {
                                        var feat = {}
                                        feat["displayFieldName"] = displayField
                                        feat["serviceLayerName"] = fclass
                                        feat.fields = feature["fields"]
                                        if(feature["geometry"])
                                            feat["geometry"] = feature["geometry"]
                                        else
                                            feat["geometry"] = ""


                                        featObj.features.append(feat)

                                    }
                                }
                            })
                        }
                        else
                        {
                            fclassObject = {}
                            fclassObject["serviceLayerName"] = fclass
                            fclassObject["showInView"] = false

                            fclassObject.features =  featureListModel.createObject(parent);
                            var feat = {}
                            feat.fields = feature["fields"]
                            feat["displayFieldName"] = displayField
                            feat["serviceLayerName"] = fclass
                            if(feature["geometry"])
                                feat["geometry"] = feature["geometry"]
                            else
                                feat["geometry"] = ""

                            fclassObject.features.append(feat)
                            relatedFeatures.push(fclassObject)

                        }
                    }
                    )
                }
                return relatedFeatures
            }
        }
    }

    Component {
        id: featureListModel
        ListModel {
        }
    }
    //--------------------------------------------------------------------------

    Component {
        id: identifyMediaView

        IdentifyMediaView {
            id: mediaView

            defaultContentHeight: parent ? panelPage.preferredContentHeight : 0
            Component.onCompleted: {
                mediaView.bindModel()
            }

            Connections {
                target: mapView.identifyProperties

                onPopupManagersCountChanged: {
                    mediaView.bindModel()
                }
            }

            Connections {
                target: panelPage

                onCurrentPageNumberChanged: {
                    //mediaView.bindModel()
                    mediaView.busyIndicator.visible = true
                }
            }

            function bindModel () {
                mediaView.busyIndicator.visible = true
                media = Qt.binding(function () {
                    try {
                        var identifyProperties = mapView.identifyProperties
                        if(identifyProperties.popupManagers[currentPageNumber-1].objectName)
                            layerName = identifyProperties.popupManagers[currentPageNumber-1].objectName.toString()
                        if(identifyProperties.popupManagers[currentPageNumber-1].title)
                            popupTitle = identifyProperties.popupManagers[currentPageNumber-1].title
                        attributes = identifyProperties.features[currentPageNumber-1].attributes.attributesJson
                        fields = identifyProperties.fields[currentPageNumber-1]
                        return identifyProperties.popupDefinitions[currentPageNumber-1].media
                    } catch (err) {
                        layerName = ""
                        return []
                    }
                })
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: bookmarksView

        BookmarksView {

            model: mapView.map.bookmarks
            onBookmarkSelected: {
                mapView.setViewpointWithAnimationCurve(mapView.map.bookmarks.get(index).viewpoint, 2.0, Enums.AnimationCurveEaseInOutCubic)
                //panelPage.collapseFullView()
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: offlineMapsView

        OfflineMapsView {

            model: mapView.offlineMaps
            onMapSelected: {
                mapView.mmpk.loadMmpkMapInMapView(index)
                mapView.updateMapInfo()
                //panelPage.collapseFullView()
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: infoView

        InfoView {
            titleText: panelPage.mapTitle > ""? panelPage.mapTitle:mapView.mapInfo.title
            ownerText:panelPage.owner > ""? panelPage.owner : ""
            modifiedDateText: panelPage.modifiedDate > ""? panelPage.modifiedDate:""
            customDesc: ( app.viewerJsonDict[app.currentAppId].detailsContent && app.viewerJsonDict[app.currentAppId].detailsContent > "" ) ?
                            utilityFunctions.scrubHtml(app.viewerJsonDict[app.currentAppId].detailsContent, "", panelPage.width) :
                            ( app.viewerJsonDict[app.currentAppId].detailContent && app.viewerJsonDict[app.currentAppId].detailContent > "" ) ?
                                utilityFunctions.scrubHtml(app.viewerJsonDict[app.currentAppId].detailContent, "", panelPage.width) :
                                ( app.viewerJsonDict[app.currentAppId].introductionContent && app.viewerJsonDict[app.currentAppId].introductionContent > "" ) ?
                                    utilityFunctions.scrubHtml(app.viewerJsonDict[app.currentAppId].introductionContent, "", panelPage.width) : utilityFunctions.scrubHtml(mapView.mapInfo.snippet, "", panelPage.width)

            welcomeText: ( app.viewerJsonDict[app.currentAppId].detailTitle && app.viewerJsonDict[app.currentAppId].detailTitle > "" )
                         ? scrubHtml(app.viewerJsonDict[app.currentAppId].detailTitle) : "Welcome!"
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: legendView

        LegendView {

            model: mapView.orderedLegendInfos


            Component.onCompleted: {
                //legendManager.updateLegendInfos()
            }

        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: mapAreasView

        MapAreasView {

            model: mapAreasModel
            mapAreas: mapAreaslst
            onMapAreaSelected: {

            }


        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: contentView

        ContentView {

            model: mapView.contentsModel

            onChecked: {
                var layers = mapView.map.operationalLayers
                for (var i=0; i<layers.count; i++) {
                    var layer = layers.get(i)
                    if (!layer) continue
                    if (layer.name === name) {
                        layer.visible = checked
                        mapView.contentsModel.setProperty(index, "checkBox", checked)
                        break
                    }
                }
                //var item = mapView.contentsModel.get(index)

                //mapView.populateLegend(layer,item)
                //mapView.sortLegendContent()

                app.focus = true
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: basemapsView

        BasemapsView {

            model: app.portal.basemaps
            onBasemapSelected: {
                mapView.map.basemap = app.portal.basemaps.get(index);
                if(pageView.state === "anchortop")
                    panelPage.collapseFullView()
            }

            Component.onCompleted: {
                app.portal.basemaps.clear();
                if ( mapView.map.loadStatus === Enums.LoadStatusLoaded ) {
                    let defaultItemUrl = "%1/sharing/rest/content/items/%2/data".arg(portal.url).arg(portalItem.id);
                    defaultBasemap.url = defaultItemUrl;
                    defaultBasemap.load();
                    defaultBasemap.loadStatusChanged.connect(() => {
                                                                 if ( defaultBasemap.loadStatus === Enums.LoadStatusLoaded ) {
                                                                     app.portal.basemaps.append(defaultBasemap);
                                                                     addAlternateBasemaps();
                                                                 }
                                                             })
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: mapunitsView

        MapUnitsView {
            id: mapUnits

            model: mapView.mapunitsListModel
            onCurrentSelectionUpdated: {
                mapUnitsManager.updateMapUnitsModel()
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: graticulesView

        GraticulesView {
            id: graticules

            model: mapView.gridListModel
            onCurrentSelectionUpdated: {
                mapUnitsManager.updateGridModel()
            }
        }
    }

    Component{
        id:profileView1
        ElevationProfileView{
            width: app.width
            height:app.height/2

        }

    }

    Component {
        id: routeView

        RouteView {
            id: route
            mapView: panelPage.mapView
            startPoint: panelPage.mapView.routeFromPoint//panelPage.mapView.selectedBufferPoint
            endPoint: panelPage.mapView.destinationPoint
            measureUnitsString: panelPage.mapView.measureUnitsString
            startIcon: panelPage.mapView.routeStartIconName
        }

    }

    //--------------------------------------------------------------------------

    Basemap {
        id: basemapImagery
        initStyle: Enums.BasemapStyleArcGISImagery
    }

    Basemap {
        id: altBasemap
    }

    Basemap {
        id: defaultBasemap
    }

    function addAlternateBasemaps() {
        let altBasemapID = app.viewerJsonDict[app.currentAppId].altBasemap;
        let basemapSelector = app.viewerJsonDict[app.currentAppId].basemapSelector;
        if ( altBasemapID && altBasemapID > "" ) {
            switch ( altBasemapID ) {
            case "hybrid":
                basemapImagery.load();
                basemapImagery.loadStatusChanged.connect(() => {
                                                             if ( basemapImagery.loadStatus === Enums.LoadStatusLoaded ){
                                                                 app.portal.basemaps.append(basemapImagery);
                                                             }
                                                         })
                break

            default:
                let altBasemapItemUrl = "%1/sharing/rest/content/items/%2/data".arg(portal.url).arg(altBasemapID);
                altBasemap.url = altBasemapItemUrl;
                altBasemap.load();
                altBasemap.loadStatusChanged.connect(() => {
                                                         if ( altBasemap.loadStatus === Enums.LoadStatusLoaded ){
                                                             app.portal.basemaps.append(altBasemap);
                                                         }
                                                     })
                break
            }
        } else if ( basemapSelector && basemapSelector > "" ) {
            let basemapSelectorItemUrl = "%1/sharing/rest/content/items/%2/data".arg(portal.url).arg(basemapSelector);
            altBasemap.url = basemapSelectorItemUrl;
            altBasemap.load();
            altBasemap.loadStatusChanged.connect(() => {
                                                     if ( altBasemap.loadStatus === Enums.LoadStatusLoaded ){
                                                         app.portal.basemaps.append(altBasemap);
                                                     }
                                                 })
        }
    }
}


