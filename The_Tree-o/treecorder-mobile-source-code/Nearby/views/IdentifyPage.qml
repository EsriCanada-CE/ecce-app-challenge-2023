import QtQuick 2.9
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.11
import QtQuick.Controls.Material 2.3
import QtGraphicalEffects 1.0

import Esri.ArcGISRuntime 100.14

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Platform 1.0
import ArcGIS.AppFramework.InterAppCommunication 1.0

import "../../MapViewer/controls" as Controls
import "../../MapViewer/widgets" as Widgets
import "../../MapViewer/views" as Views

Drawer {
    id: identifyPagePopup

    // ------------ Features properties --------------

    property int totalNumOfFeatures: 0
    property int currentIndex: 0
    property int listIndex: 0

    // ------------ Attributes properties --------------

    property bool isInteractive: true
    property string popupLayerName: ""
    property string popupTitleText: ""
    property string distanceText:""
    property string distanceFromCurrentLocation:""
    property bool showDistance: true
    property bool showDirections: true
    property bool isDirLyr: false

    // ------------ Attachments properties --------------

    property bool fullView:false
    property bool photoMode: false
    property bool isPhotoFullScreen : false
    property real minDelegateHeight: 2 * app.units(56)
    property real headerHeight: app.headerHeight + app.notchHeight
    property int currentPhotoIndex: -1
    property alias featuresList: featuresList
    property bool showDetails: true
    property bool isZooming: false
    property color pageBackgroundColor: "#EAEAEA"
    property color backgroundColor: Qt.lighter(pageBackgroundColor) //panelThreshold ? "#FAFAFA" : "#000000"
    property color pictureBackgroundColor: "black"  //panelThreshold ? "#FAFAFA" : "transparent"
    property color headerBackgroundColor: Qt.darker(backgroundColor, 1.1)//panelThreshold ? "#E8E8E8" : "transparent"
    property real smallSizeThreshold: units(450)
    property bool isSmallScreen: (width || height) < smallSizeThreshold
    property color maskColor: getAppProperty(app.iconMaskColor, "transparent")
    property bool isShowHeader: true
    property bool panelThreshold: !isSmallScreen
    property color headerColor :"#EDEDED"
    property color headerComponentsColor : "#4C4C4C"

    property bool isAttachmentsEmpty: true

    property var routeFromLocation:mapView.selectedBufferPoint
    property var searchDistanceMode:"currentLocation"


    closePolicy: Popup.NoAutoClose
    modal: true
    height: parent.height - ( ( parent.height > app.height ) ? ( app.heightOffset + ( app.isIphoneX ? app.defaultMargin + 4 * app.scaleFactor : 0 ) ) : 0 )
    width: parent.width
    transformOrigin: Popup.Bottom
    edge: Qt.BottomEdge
    focus: isInteractive
    interactive: true

    topMargin: app.heightOffset + ( app.isIphoneX ? app.defaultMargin + 4 * app.scaleFactor : 0 )
    bottomPadding: app.isIphoneX ? 2 * app.defaultMargin : 0

    Material.background: "#F4F4F4"

    // ------------ List models --------------

    property ListModel identifyListModel
    property var attachmentsListModel

    // ------------ Signals --------------

    signal openRoutePage(var selectedSearchDistanceMode)
    signal openRoute(var selectedSearchDistanceMode)
    signal prevFeatureSelected(int prevIndex)
    signal nextFeatureSelected(int nextIndex)

    // ------------ Drawer toolbar --------------

    ToolBar {
        id: mapPageHeader

        height: app.headerHeight + app.notchHeight
        width: identifyPagePopup.width
        Material.background: app.primaryColor
        Material.elevation: 2
        visible: !photoMode

        RowLayout {
            anchors {
                fill: parent
                rightMargin: app.isLandscape ? app.widthOffset: 0
                leftMargin: app.isLandscape ? app.widthOffset: 0
                topMargin: app.units(4) + app.notchHeight
            }
            spacing: 0


            Item {
                id: closeIconContainer

                Layout.fillHeight: true
                Layout.preferredWidth: app.units(20)


                Controls.Icon {
                    id: closeIcon

                    iconSize: 6 * app.baseUnit

                    anchors.left: parent.left


                    imageSource: "../../MapViewer/images/close.png"

                    onClicked: {
                        identifyPagePopup.close()
                    }
                }
            }

            // Row to display current feature and allow users to switch between previous, current and next features
            Item {
                id: changeCurrentFeatureRowContainer
                Layout.fillHeight: true
                Layout.fillWidth: true


                RowLayout {
                    id: changeCurrentFeatureRow
                    anchors.centerIn: parent
                    Layout.fillHeight: true
                    spacing: 0

                    Controls.Icon {
                        id: selectPreviousFeatureIcon

                        iconSize: 6 * app.baseUnit

                        imageSource: "../../MapViewer/images/arrowDown.png"

                        maskColor: listIndex > 0 ? "#FFFFFF" : "#4c4c4c"

                        rotation: app.isRightToLeft ? 270 : 90

                        enabled: listIndex > 0

                        onClicked: {
                            prevFeatureSelected(listIndex - 1);
                            photoModeHeader.forceActiveFocus();
                        }
                    }

                    Label {
                        text: app.isRightToLeft ? qsTr("%L1 of %L2").arg(totalNumOfFeatures).arg(listIndex + 1) : qsTr("%L1 of %L2").arg(listIndex + 1).arg(totalNumOfFeatures)
                        visible: text > ""
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        elide: Text.ElideRight
                        font.bold: true
                        font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        color: "white"
                    }


                    Controls.Icon {
                        id: selectNextFeatureIcon

                        iconSize: 6 * app.baseUnit

                        enabled: listIndex < totalNumOfFeatures - 1

                        imageSource: "../../MapViewer/images/arrowDown.png"

                        maskColor: listIndex < totalNumOfFeatures - 1 ? "#FFFFFF": "#4c4c4c"

                        rotation: app.isRightToLeft ? 90 : 270

                        onClicked: {
                            nextFeatureSelected(listIndex + 1);
                            photoModeHeader.forceActiveFocus();
                        }
                    }
                }
            }

            Item{
                Layout.fillHeight: true
                Layout.preferredWidth: app.units(20)
                //Layout.fillWidth: true
            }
      }
    }

    // ------------ Photo mode toolbar --------------

    ToolBar {
        id: photoModeHeader

        width: identifyPagePopup.width
        height: app.headerHeight + app.notchHeight
        anchors.top: identifyBasePage.top
        visible: photoMode && !isPhotoFullScreen
        Material.background: mapPage.headerColor
        Material.elevation: 2

        LayoutMirroring.enabled: app.isRightToLeft
        LayoutMirroring.childrenInherit: app.isRightToLeft

        Keys.onPressed:{
            if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape){
                event.accepted = true
                if(photoMode)
                {
                    if( isPhotoFullScreen ){
                        isPhotoFullScreen = false;
                    } else
                        photoMode = false;

                    // close the detailPanel (sharesheet) if left open in the photoMode
                    detailPanel.visible = false;
                }
                else
                {
                    identifyPagePopup.close()
                }
            }
        }

        RowLayout {
            anchors {
                fill: parent
                topMargin: app.units(4) + app.notchHeight
            }

            spacing: 0

            Controls.Icon {
                id: backIcon
                iconSize: 6 * app.baseUnit

                imageSource: "../../MapViewer/images/back.png"

                rotation: app.isRightToLeft ? 180: 0

                onClicked: {
                    photoMode = false
                    featuresList.height = app.height * 0.45
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
            }

            Label {
                id: imgcount
                text: typeof popupTitleText !== 'undefined' && popupTitleText > "" ? popupTitleText.trim() : popupLayerName
                visible: text > ""
                Layout.fillWidth: true
                Layout.fillHeight: true
                elide: Text.ElideRight
                font.bold: true
                font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                font.pixelSize: 2.5 * app.baseUnit
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                color: "white"
            }

            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
            }

            Controls.Icon {
                id: moreIcon
                visible: true
                objectName: "download"
                imageSource: "../../MapViewer/images/more.png"
                checkable: false


                MouseArea {
                    anchors.fill: parent
                    visible:true
                    onClicked: {
                        detailPanel.visible = !detailPanel.visible;
                    }
                }
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: 100
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#80000000"
            visible: detailPanel.visible

            MouseArea {
                anchors.fill: parent
                enabled: parent.visible
                preventStealing: true

                onClicked: {
                    detailPanel.visible = false
                }
            }
        }

        function downloadImage(){
            var component = networkRequestComponent;
            var networkRequest = component.createObject(parent);
            var attachmentUrl =  attachmentsListModel[currentPhotoIndex].attachmentUrl
            var pictureid = attachmentsListModel[currentPhotoIndex].pictureid
            var downloadPath = AppFramework.standardPaths.standardLocations(StandardPaths.PicturesLocation)[0]+"/" + pictureid + ".png"
            if(securedPortal && securedPortal.credential)
                var picUrl = attachmentUrl + "?token="+ securedPortal.credential.token
            networkRequest.downloadImage(picUrl,downloadPath,imageDownloaded);
        }
    }

    // ------------ Base page --------------

    contentItem: Page {

        id: identifyBasePage
        anchors.fill: parent
        Material.background: "#F4F4F4"

        LayoutMirroring.enabled: app.isRightToLeft
        LayoutMirroring.childrenInherit: app.isRightToLeft

        contentItem: Flickable {
            id:flickable

            anchors.fill: parent
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick

            interactive: photoMode ? false: true
            contentHeight: attributeslist.height + ( !isAttachmentsEmpty ? ( fakeFooter.height + mapPageHeader.height + ( app.isDesktop ? app.defaultMargin : app.headerHeight )) : 0 )
            clip: true

            property real startContentY: 0

            ColumnLayout {
                id: attributeslist
                width:parent.width
                spacing: 0

                // ------------ Topmargin to compensate for the mapPageHeader toolbar --------------

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: app.headerHeight + app.notchHeight
                    visible: !photoMode
                }

                // ------------ Attachments list view --------------

                ListView {
                    id:featuresList
                    Layout.preferredWidth: parent.width
                    Layout.preferredHeight:!photoMode ? app.height * 0.45 : app.height
                    spacing: 0
                    orientation: ListView.Horizontal
                    interactive: true
                    boundsBehavior: Flickable.StopAtBounds

                    snapMode: ListView.SnapOneItem
                    preferredHighlightBegin: 0;
                    preferredHighlightEnd: 0  //this line means that the currently highlighted item will be central in the view
                    highlightRangeMode: ListView.StrictlyEnforceRange
                    highlightFollowsCurrentItem: true  //updates the current index property to match the currently highlighted item
                    highlightResizeDuration: 10
                    highlightResizeVelocity: 2000
                    highlightMoveVelocity: 2000
                    highlightMoveDuration: 10

                    currentIndex: -1

                    model: attachmentListModel
                    visible: !isAttachmentsEmpty

                    property int delegateWidth: (function(){
                        var value = 100;

                        if(photoMode) {
                            value = Math.min(parent.width, 1024*app.scaleFactor)
                        } else {
                            value = isSmallScreen ? parent.width : featuresList.height*1.5
                        }

                        return value;
                    })();

                    delegate: featuresListDelegate

                    // ------------ Bottom page indicator --------------

                    PageIndicator {
                        id: pageIndicator
                        anchors {
                            bottom: parent.bottom
                            bottomMargin: 8 * app.scaleFactor
                            horizontalCenter: parent.horizontalCenter
                        }

                        count: visible ? attachmentsListModel.count : 0
                        currentIndex: 1
                        visible: typeof attachmentsListModel !== "undefined" ? attachmentsListModel.count > 1 : false
                        scale: 0.8

                        delegate: Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 10 * app.scaleFactor
                            height: width
                            radius: width / 2
                            opacity: index === featuresList.currentIndex ? 1.0 : 0.5
                            Behavior on opacity {
                                OpacityAnimator {
                                    duration: 250
                                }
                            }

                            Behavior on x {
                                NumberAnimation { duration : 250}
                            }
                        }
                    }

                    onFlickEnded: {
                        currentIndex = indexAt(contentX, contentY);
                    }
                }

                // ------------ Attributes list view --------------

                ListView {
                    id: featuresListView
                    Layout.fillWidth: true
                    Layout.preferredHeight: contentItem.height
                    boundsBehavior:  Flickable.StopAtBounds
                    Layout.topMargin: photoMode ? app.defaultMargin : 0
                    interactive: false
                    visible: true
                    clip: true
                    spacing: 0
                    model: identifyListModel

                    property real startContentY: 0
                    property real minDelegateHeight: 2 * app.units(56)
                    property real listViewHeaderHeight: app.headerHeight + app.notchHeight


                    Behavior on contentY {
                        enabled:true
                        NumberAnimation {
                            duration: 500
                            easing.type: Easing.InOutQuad
                        }
                    }

                    // ------------ List view header and directions column --------------

                    header: Item {
                        id: featuresListViewHeader
                        width: parent.width
                        height: headerColumn.height
                        visible: true

                        ColumnLayout {
                            id: headerColumn

                            width: parent.width
                            spacing: 0

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: headerHeight
                                Layout.leftMargin: app.defaultMargin
                                Layout.rightMargin: app.defaultMargin
                                Layout.topMargin: 4 * app.scaleFactor
                                Layout.bottomMargin: directionMileRow.visible ? 0 : 8 * app.scaleFactor

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 0

                                    Rectangle {
                                        id: layerIcon
                                        Layout.preferredHeight: Math.min(parent.height - app.defaultMargin, app.iconSize)
                                        Layout.preferredWidth:Layout.preferredHeight
                                        visible: !popupTitleText > ""
                                        color: "#F4F4F4"

                                        Image {
                                            id: lyr
                                            source: "../../MapViewer/images/layers.png"
                                            anchors.fill: parent
                                        }

                                        ColorOverlay {
                                            id: layerMask
                                            anchors {
                                                fill: lyr
                                            }
                                            source: lyr
                                            color: "#6E6E6E"
                                        }
                                    }

                                    Item {
                                        Layout.preferredWidth: app.defaultMargin
                                        Layout.fillHeight: true
                                        visible:!popupTitleText > ""

                                    }

                                    Label {
                                        id: layerNameText

                                        elide: Text.ElideRight
                                        Layout.alignment: Qt.AlignVCenter
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignLeft
                                        verticalAlignment: Text.AlignVCenter
                                        text: popupTitleText > "" ? popupTitleText.trim() : popupLayerName
                                        font.pixelSize: 16 * app.scaleFactor
                                        font.bold: true
                                        font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                                        color: colors.blk_200
                                        wrapMode: Text.WrapAnywhere

                                        textFormat: isHTML(text)? Text.RichText : Text.PlainText

                                        function isHTML(text){
                                            var result = RegExp.prototype.test.bind(/(<([^>]+)>)/i);

                                            return result(text);
                                        }
                                    }
                                }
                            }

                            Item {
                                id:directionMileRow

                                Layout.fillWidth: true
                                Layout.preferredHeight: app.units(56)
                                Layout.leftMargin: app.defaultMargin
                                Layout.rightMargin: app.defaultMargin

                                visible: (showDirections && isDirLyr) || showDistance

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 0

                                    RowLayout{

                                    Layout.fillHeight: true
                                    spacing:0
                                    Label {
                                        id: distanceLabel
                                        elide: Text.ElideRight
                                        Layout.alignment: Qt.AlignVCenter
                                        //Layout.preferredWidth: Math.min(implicitWidth,parent.width - 180)
                                        Layout.fillHeight: true
                                        horizontalAlignment: Text.AlignLeft
                                        verticalAlignment: Text.AlignVCenter
                                        text: mapView.selectedSearchDistanceMode === "bufferCenter" ?qsTr("%1 from ").arg(distanceText) :qsTr("%1 %2  from ").arg(distanceFromCurrentLocation).arg(mapView.measureUnitsString)
                                        font.pixelSize: 16 * app.scaleFactor
                                        font.bold: true
                                        font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                                        color: colors.blk_200
                                        wrapMode: Text.WrapAnywhere
                                        visible:showDistance
                                    }

                                    Item {
                                        Layout.preferredWidth: 4 * app.scaleFactor
                                        Layout.fillHeight: true
                                    }

                                    Image {
                                        id: locImg1
                                        source: "../../MapViewer/images/redPin.png"
                                        width: 18 * app.scaleFactor
                                        height: 18 * app.scaleFactor
                                        mipmap: true
                                        visible: mapView.selectedSearchDistanceMode === "bufferCenter" && showDistance
                                    }

                                    Item{
                                            width: 24 * app.scaleFactor
                                            height: width
                                            visible: mapView.selectedSearchDistanceMode !== "bufferCenter" && showDistance

                                            Image {
                                                id: locImg2
                                                source: "../../MapViewer/images/button_current_location.png"
                                                //sourceSize: Qt.size(parent.width, parent.height)
                                                width: parent.width
                                                height: width
                                                mipmap: true
                                                visible: mapView.selectedSearchDistanceMode !== "bufferCenter" && showDistance

                                            }

                                            ColorOverlay {
                                                anchors.fill: locImg2
                                                source: locImg2
                                                color: "steelblue"

                                            }
                                        }


                                   }

                                    Item {
                                        Layout.fillHeight: true
                                        Layout.fillWidth: true
                                    }

                                    Item {
                                        Layout.preferredWidth: directionsButtonRowLayout.width
                                        Layout.preferredHeight: 32 * app.scaleFactor
                                        Layout.alignment: Qt.AlignRight
                                        visible: showDirections && isDirLyr

                                        Rectangle {
                                            width: directionsButtonRowLayout.width
                                            height: parent.height
                                            radius: 4 * app.scaleFactor
                                            color: "transparent"
                                            border.color: "#BBBBBB"
                                            border.width: app.scaleFactor

                                            RowLayout {
                                                id: directionsButtonRowLayout
                                                width: implicitWidth
                                                anchors.centerIn: parent
                                                spacing: 0

                                                Item {
                                                    Layout.preferredWidth: 8 * app.scaleFactor
                                                    Layout.fillHeight: true
                                                }

                                                Item {
                                                    Layout.preferredWidth: 20 * app.scaleFactor
                                                    Layout.fillHeight: true

                                                    Image {
                                                        id: directionImg
                                                        source: "../../MapViewer/images/ic_directions_white_48dp.png"
                                                        width: 20 * app.scaleFactor
                                                        height: width
                                                        rotation: app.isRightToLeft ? 180 : 0
                                                        mipmap: true
                                                        anchors.centerIn: parent

                                                        ColorOverlay {
                                                            anchors.fill: directionImg
                                                            source: directionImg
                                                            color: colors.blk_200
                                                        }
                                                    }
                                                }

                                                Item {
                                                    Layout.fillHeight: true
                                                    Layout.preferredWidth: 8 * app.scaleFactor
                                                }

                                                Item {
                                                    Layout.fillHeight: true
                                                    Layout.preferredWidth: directionText.width
                                                    Layout.alignment: Qt.AlignHCenter
                                                    visible:mapProperties.isMapArea? (app.isDesktop?app.isOnline:true):true

                                                    Label {
                                                        id: directionText
                                                        anchors.centerIn: parent
                                                        Layout.preferredHeight: parent.height
                                                        clip: true
                                                        elide: Label.ElideRight
                                                        wrapMode: Text.Wrap
                                                        maximumLineCount: 2
                                                        font.pixelSize: 14 * app.scaleFactor
                                                        verticalAlignment: Text.AlignVCenter
                                                        horizontalAlignment: Text.AlignHCenter
                                                        font.bold: true
                                                        color:  colors.blk_200
                                                        text: strings.direction
                                                    }
                                                }

                                                Item {
                                                    Layout.fillHeight: true
                                                    Layout.preferredWidth: 8 * app.scaleFactor
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                            //isInRouteMode = true
                                            // mapView.distanceLineGraphicsOverlay.graphics.clear()
                                                if(mapView.selectedSearchDistanceMode === "bufferCenter")
                                                {
                                                    panelPage.mapView.routeStartIconName = "redPin.png"
                                                    panelPage.mapView.selectedSearchDistanceMode = "bufferCenter"


                                                    mapView.routeFromPoint = mapView.selectedBufferPoint
                                                }
                                                else
                                                {
                                                    panelPage.mapView.routeStartIconName = "button_current.png"
                                                    mapView.routeFromPoint = mapView.locationDisplay.mapLocation
                                                     panelPage.mapView.selectedSearchDistanceMode = "currentLocation"
                                                }

                                                openRoute(mapView.selectedSearchDistanceMode);
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: app.units(1)
                                color: colors.blk_020
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: app.units(8)
                            }
                        }
                    }

                    delegate: Pane {
                        id: delegateContent

                        width: parent ? parent.width : 0
                        height: this.visible ? contentItem.height : 0
                        padding: 0
                        spacing: 0
                        clip: true

                        contentItem: Item {
                            width: parent.width
                            height: contentColumn.height

                            ColumnLayout {
                                id: contentColumn

                                width: parent.width
                                spacing: 0

                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: app.units(12)
                                }

                                Rectangle {
                                    id: item
                                    Layout.preferredWidth: panelPage.width - app.units(32)
                                    Layout.preferredHeight:text1.height
                                    visible: description > ""
                                    Layout.alignment: Qt.AlignCenter
                                    color: "#F4F4F4"

                                    Text {
                                        id: text1
                                        text: description !== undefined ? description : ""
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        wrapMode: Text.WordWrap
                                        textFormat: Text.RichText
                                        visible:description > ""
                                        horizontalAlignment: Text.AlignLeft
                                        onLinkActivated: mapViewerCore.openUrlInternally(link)
                                    }

                                }

                                Label {
                                    id: lbl

                                    elide: Text.ElideMiddle
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignLeft
                                    verticalAlignment: Text.AlignVCenter
                                    text: typeof label !== undefined ? (label ? label : "") : ""
                                    font.pixelSize: 14 * app.scaleFactor
                                    font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                                    color: colors.blk_140
                                    wrapMode: Text.WrapAnywhere
                                    leftPadding: app.defaultMargin
                                    rightPadding: app.defaultMargin
                                }

                                Item {
                                    Layout.preferredHeight: app.units(12)
                                    Layout.fillWidth: true
                                }

                                Label {
                                    id: desc
                                    objectName: "description"

                                    elide: Text.ElideMiddle
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignLeft
                                    verticalAlignment: Text.AlignVCenter
                                    font.pixelSize: 14 * app.scaleFactor
                                    font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                                    leftPadding: app.defaultMargin
                                    rightPadding: app.defaultMargin
                                    color: colors.blk_200
                                    wrapMode: Text.WordWrap

                                    textFormat: Text.StyledText
                                    Material.accent: app.accentColor
                                    onLinkActivated: {
                                        mapViewerCore.openUrlInternally(link)
                                    }

                                    Component.onCompleted: {
                                        text = (typeof formattedValue !== "undefined" ? (formattedValue ? formattedValue : " ") : (typeof fieldValue !== "undefined" ? (fieldValue ? fieldValue : " ") : " ")).replace(/(http:\/\/[^\s]+)/gi , '<a href="$1">$1</a>').replace(/(https:\/\/[^\s]+)/gi , '<a href="$1">$1</a>');
                                        elide = Text.ElideLeft;
                                    }
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: app.units(12)
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: app.scaleFactor
                                    visible: !item.visible

                                    Rectangle {
                                        anchors.fill: parent
                                        color: colors.blk_020
                                    }
                                }
                            }
                        }
                    }

                    Controls.BaseText {
                        id: message

                        visible: identifyListModel.length === 0
                        width: parent.width
                        height: parent.height
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: strings.no_attributes
                    }

                    // ------ Busy indicator to show loading of attributes ------

                    BusyIndicator {
                        id: busyIndicator

                        width: app.iconSize
                        visible: identifyInProgress
                        height: width
                        anchors.centerIn: parent
                        Material.primary: app.primaryColor
                        Material.accent: app.accentColor

                        Timer {
                            id: timeOut

                            interval: 3000
                            running: true
                            repeat: false
                            onTriggered: {
                                busyIndicator.visible = false
                            }
                        }
                    }
                }

                // ------ Footer to leave some space below the list view to allow free scrolling ------
                Item {
                    id: fakeFooter
                    Layout.fillWidth: true
                    Layout.preferredHeight: app.headerHeight + ( app.isIphoneX ? 24 * app.scaleFactor : 0 )
                }
            }

            // ------ Reset flickable's orientation to top & left every time it is opened

            Component.onCompleted :{
                flickable.contentX = 0;
                flickable.contentY = 0;

            }
        }
    }

    // ------------ Attachments list view delegate --------------

    Component {
        id: featuresListDelegate

        Rectangle {
            id: itemOuterBox

            color: pictureBackgroundColor
            height: featuresList.height
            width: featuresList.width
            clip: true

            Rectangle {
                id: photoFrame

                property bool supportsRotation: true

                Behavior on scale { NumberAnimation { duration: 200 } }
                Behavior on rotation { NumberAnimation { duration: 200 } }
                Behavior on x { NumberAnimation { duration: 200 } }
                Behavior on y { NumberAnimation { duration: 200 } }
                width: parent.width
                height:!photoMode ? parent.height : itemOuterBox.height
                color: contentType.split("/")[0]!=="image" ? "white":pictureBackgroundColor
                scale: 1
                smooth: true
                antialiasing: true

                // ------------ Attachments Image --------------

                Image {
                    id: itemImage

                    anchors.fill: parent
                    anchors.centerIn: parent
                    asynchronous: true

                    visible: contentType.split("/")[0] === "image"
                    source: contentType.split("/")[0] === "image" ? attachmentUrl: ""

                    smooth: true
                    autoTransform: true
                    fillMode: Image.PreserveAspectFit
                    sourceSize.width: app.width
                    sourceSize.height: app.height

                    PinchArea {
                        id: pinchArea

                        property real minScale: 1
                        property real maxScale: 4
                        property bool enableRotation: false

                        anchors.fill:itemImage //parent
                        enabled: photoMode //&& !is_video
                        pinch.target: photoFrame
                        pinch.minimumRotation: enableRotation ? -360 : 0
                        pinch.maximumRotation: enableRotation ? 360 : 0
                        pinch.minimumScale: minScale
                        pinch.maximumScale: maxScale
                        pinch.dragAxis: Pinch.XAndYAxis
                        pinch.minimumX: -Math.abs(itemImage.width - photoFrame.scale * itemImage.width)/2
                        pinch.maximumX: +Math.abs(itemImage.width - photoFrame.scale * itemImage.width)/2
                        pinch.minimumY: -Math.abs(itemImage.height - photoFrame.scale * itemImage.height)/2
                        pinch.maximumY: +Math.abs(itemImage.height - photoFrame.scale * itemImage.height)/2

                        onSmartZoom: {
                            if (pinch.scale > 0) {
                                photoFrame.rotation = 0;
                                photoFrame.scale = Math.min(itemOuterBox.width, itemOuterBox.height) / Math.max(itemImage.sourceSize.width, itemImage.sourceSize.height) * 0.85
                                photoFrame.x = itemOuterBox.x + (itemOuterBox.width - photoFrame.width) / 2
                                photoFrame.y = itemOuterBox.y + (itemOuterBox.height - photoFrame.height) / 2
                            } else {
                                photoFrame.rotation = pinch.previousAngle
                                photoFrame.scale = pinch.previousScale
                                photoFrame.x = pinch.previousCenter.x - photoFrame.width / 2
                                photoFrame.y = pinch.previousCenter.y - photoFrame.height / 2
                            }
                        }

                        onPinchStarted: {
                            isPhotoFullScreen = true;
                        }

                        onPinchFinished: {
                            if(photoFrame.scale<minScale || photoFrame.scale==minScale) {
                                photoFrame.scale=minScale;
                                isPhotoFullScreen = false;
                            }
                            photoFrame.rotation = Math.round(photoFrame.rotation/90)*90
                        }

                        // ------------ Attachments Image swipe area --------------

                        SwipeArea {
                            id: swipeArea

                            enableDrag: (photoFrame.scale > pinchArea.minScale) || (photoFrame.x !== 0) || (photoFrame.y !== 0)

                            anchors.fill:parent
                            drag.target: photoFrame
                            drag.axis:  !enableDrag ? Drag.None : Drag.XAndYAxis
                            drag.minimumX: -Math.abs(itemImage.width - photoFrame.scale * itemImage.width)/2
                            drag.maximumX: +Math.abs(itemImage.width - photoFrame.scale * itemImage.width)/2
                            drag.minimumY: -Math.abs(itemImage.height - photoFrame.scale * itemImage.height)/2
                            drag.maximumY: +Math.abs(itemImage.height - photoFrame.scale * itemImage.height)/2
                            scrollGestureEnabled: false
                            propagateComposedEvents: false

                            onWheel: {
                                if(photoMode)
                                    if (wheel.modifiers & Qt.ControlModifier) {
                                        photoFrame.rotation += wheel.angleDelta.y / 120 * 5
                                        if (Math.abs(photoFrame.rotation) < 4)
                                            photoFrame.rotation = 0
                                    } else {
                                        photoFrame.rotation += wheel.angleDelta.x / 120;
                                        if (Math.abs(photoFrame.rotation) < 0.6)
                                            photoFrame.rotation = 0
                                        var scaleBefore = photoFrame.scale;
                                        var currentScale = photoFrame.scale + photoFrame.scale * wheel.angleDelta.y / 120 / 10
                                        if (currentScale > pinchArea.maxScale) {
                                            isPhotoFullScreen = true
                                            photoFrame.scale = pinchArea.maxScale
                                        } else if (currentScale < pinchArea.minScale) {
                                            isPhotoFullScreen = false
                                            photoFrame.scale = pinchArea.minScale

                                            photoFrame.reset()
                                        } else {
                                            isPhotoFullScreen = true
                                            photoFrame.scale = currentScale
                                        }

                                    }
                            }

                            onClicked: {
                                detailPanel.visible = false;
                                mouse.accepted = true;
                                if(!photoMode) {
                                    photoMode = !photoMode
                                    currentPhotoIndex = index
                                } else {
                                    isPhotoFullScreen = !isPhotoFullScreen;
                                }
                            }


                            onReleased: {
                                if(scale<pinchArea.minScale) photoFrame.scale=pinchArea.minScale;
                                photoFrame.rotation = Math.round(photoFrame.rotation/90)*90
                            }
                        }
                    }
                }

                // ------------ For attachments other than image --------------

                Image {
                    id: typeIcon

                    anchors.top: parent.top
                    anchors.topMargin: photoMode ? 14 * app.baseUnit : 16 * app.scaleFactor
                    anchors.bottom: fileName.top
                    anchors.bottomMargin: 16 * app.scaleFactor
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 0.25 * photoFrame.width
                    height: width
                    fillMode: Image.PreserveAspectFit
                    visible: contentType.split("/")[0]!=="image"

                    source: {
                        var type = contentType//modelData.contentType;
                        if (typeof type === "undefined") {
                            return "../../MapViewer/images/file-32.svg"
                        } else if (!type) {
                            return "../../MapViewer/images/file-32.svg"
                        } else if (type.endsWith(".csv")) {
                            return "../../MapViewer/images/file-csv-32.svg"
                        } else if (type.split("/")[0] === "text") {
                            return "../../MapViewer/images/file-text-32.svg"
                        } else if (type.split("/")[0] === "video") {
                            return "../../MapViewer/images/file-video-32.svg"
                        } else if (type.split("/")[0] === "audio") {
                            return "../../MapViewer/images/file-sound-32.svg"
                        } else if (type.endsWith("excel")) {
                            return "../../MapViewer/images/file-excel-32.svg"
                        } else if (type.endsWith("pdf")) {
                            return "../../MapViewer/images/file-pdf-32.svg"
                        } else if (type.endsWith("word")) {
                            return "../../MapViewer/images/file-word-32.svg"
                        }
                        else if (name.endsWith(".docx")) {
                            return "../../MapViewer/images/file-word-32.svg"
                        } else if (name.endsWith(".doc")) {
                            return "../../MapViewer/images/file-word-32.svg"
                        } else if (type.endsWith("zip")) {
                            return "../../MapViewer/images/file-zip-32.svg"
                        } else if (name.endsWith(".xlsx")) {
                            return "../../MapViewer/images/file-excel-32.svg"
                        } else if (name.endsWith(".xls")) {
                            return "../../MapViewer/images/file-excel-32.svg"
                        }
                        return "../../MapViewer/images/file-32.svg"
                    }
                }

                ColorOverlay {
                    id: typeIconColorOverLay

                    anchors.fill: typeIcon
                    source: typeIcon
                    color: mapPage.headerColor
                    visible: typeIcon.visible
                }

                Label {
                    id: fileName

                    width: parent.width
                    height: 28 * app.scaleFactor
                    visible: typeIcon.visible
                    text: name > ""? name.trim() :strings.unknown
                    anchors.bottom: openBtn.top
                    anchors.bottomMargin: 36 * app.scaleFactor
                    anchors.horizontalCenter: parent.horizontalCenter
                    leftPadding: 56 * app.scaleFactor
                    rightPadding: 56 * app.scaleFactor
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2

                    elide: Text.ElideRight
                    font.pixelSize: 14 * app.scaleFactor
                    font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                    color: mapPage.headerColor
                }

                RoundButton {
                    id: openBtn

                    visible: typeIcon.visible
                    width: 12.5 * app.baseUnit
                    height: 6 * app.baseUnit
                    radius: 3 * app.baseUnit
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 40 * app.scaleFactor
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: strings.open
                    Material.foreground: mapPage.headerColor
                    Material.background: "white"
                    Material.elevation: 2
                    z : fileName.z + 1


                    contentItem: Text {
                        text: openBtn.text
                        font.family: "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                        font.pixelSize: 14 * app.scaleFactor
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: mapPage.headerColor
                    }
                    onClicked:{
                        attachmentImagePanel.shareModifiedAttachmentUrl("open")
                    }
                }

                LinearGradient {
                    id: mask
                    anchors.fill: parent
                    visible: contentType.split("/")[0]!=="image"
                    source: parent
                    gradient: Gradient {
                        GradientStop { position: 0; color: "transparent"}
                        GradientStop { position: 1; color: "#35000000" }
                    }
                }

                BusyIndicator {
                    visible: contentType.split("/")[0]==="image" && itemImage.status !== (Image.Ready || Image.Error)
                    anchors.centerIn: parent
                    Material.primary: app.primaryColor
                    Material.accent: app.accentColor

                    onScaleChanged: {
                        if (scale > pinchArea.minScale) {
                            isZooming = true
                        } else {
                            isZooming = false
                        }
                    }

                    Connections {
                        target: identifyPagePopup

                        function onPhotoModeChanged() {
                            photoFrame.reset()
                        }
                    }

                    Connections {
                        target: featuresList

                        function onCurrentIndexChanged() {
                            photoFrame.reset()
                        }
                    }

                    Component.onCompleted: {
                        if (scale > pinchArea.minScale) {
                            isZooming = true
                        } else {
                            isZooming = false
                        }
                    }
                }

                function reset () {
                    scale = pinchArea.minScale
                    x = 0
                    y = 0
                }
            }
        }
    }

    // ------------ More page details panel (only in photo mode toolbar and if the atttachment is a photo) --------------

    Rectangle {
        id: detailPanel

        height: 23 * app.baseUnit + (isIphoneX ? 2 * app.baseUnit : 0)
        width: parent.width
        visible: false
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: visible ? 0 : -height

        ColumnLayout {
            id: attachmentImagePanel
            anchors.fill: parent
            anchors.leftMargin: 2 * app.baseUnit
            anchors.rightMargin: 2 * app.baseUnit
            anchors.topMargin: 2.5 * app.baseUnit
            anchors.bottomMargin: isIphoneX ? 4 * app.baseUnit : 2* app.baseUnit
            spacing: 0

            Item {
                Layout.preferredHeight: 3 * app.baseUnit
                Layout.fillWidth: true

                Label {
                    id: detailTitle

                    anchors.fill: parent
                    text: strings.details
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    elide: Text.ElideRight
                    font.pixelSize: 2.5 * app.baseUnit
                    font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                    font.bold: true
                    color: "#4C4C4C"
                }
            }

            Item {
                Layout.preferredHeight: 2 * app.baseUnit
                Layout.fillWidth: true
            }

            Item {
                Layout.preferredHeight: 5.5 * app.baseUnit
                Layout.fillWidth: true

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Item {
                        Layout.preferredWidth: 5 * app.baseUnit
                        Layout.fillHeight: true

                        Views.IconImage {
                            width: 3 * app.baseUnit
                            height: 3 * app.baseUnit
                            source: "../../MapViewer/images/image-32.svg"
                            color: Qt.lighter("#585858")
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 0

                            Item {
                                Layout.preferredHeight: 2.5 * app.baseUnit
                                Layout.fillWidth: true

                                Label {
                                    id: attachmentTitleText

                                    anchors.fill: parent
                                    text: featuresList.currentIndex > -1 ? ( attachmentsListModel.get(featuresList.currentIndex) && attachmentsListModel.get(featuresList.currentIndex).name > "" ? attachmentsListModel.get(featuresList.currentIndex).name : strings.unknown):  strings.unknown
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignLeft
                                    elide: Text.ElideRight
                                    font.pixelSize: 2 * app.baseUnit
                                    font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                                    color: "#4C4C4C"
                                }
                            }

                            Item {
                                Layout.preferredHeight:  app.baseUnit
                                Layout.fillWidth: true
                            }

                            Item {
                                Layout.preferredHeight: 2 * app.baseUnit
                                Layout.fillWidth: true

                                Label {
                                    id: detailText

                                    anchors.fill: parent
                                    text: {
                                        if( featuresList.currentIndex > -1 && attachmentsListModel.get(featuresList.currentIndex) ) {
                                            var origSize = parseInt(attachmentsListModel.get(featuresList.currentIndex).size);//parseInt(attachmentsModel[featuresList.currentIndex].size);
                                            let tempSize;
                                            if (origSize > 1024 * 1024){
                                                tempSize = origSize/1024/1024;
                                                return app.isRightToLeft ? qsTr("MB %L1").arg(Math.round(tempSize * 10) / 10) : qsTr("%L1 MB").arg(Math.round(tempSize * 10) / 10);
                                            } else{
                                                tempSize = origSize/1024;
                                                return app.isRightToLeft ? qsTr("KB %L1").arg(Math.round(tempSize * 10) / 10) : qsTr("%L1 KB").arg(Math.round(tempSize * 10) / 10);
                                            }
                                        } else return strings.size_unknown
                                    }
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignLeft
                                    elide: Text.ElideRight
                                    font.pixelSize: 14 * app.scaleFactor
                                    font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                                    color: "#818181"
                                }
                            }
                        }
                    }
                }
            }

            Item {
                Layout.preferredHeight: 2 * app.baseUnit
                Layout.fillWidth: true
            }

            Item {
                Layout.preferredHeight: 7 * app.baseUnit
                Layout.fillWidth: true

                Button {
                    id: shareButton

                    anchors.fill: parent
                    height: 7 * app.baseUnit
                    Material.foreground: "white"
                    Material.background: mapPage.headerColor

                    text: strings.share

                    contentItem: Text {
                        text: shareButton.text
                        font.family: "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                        font.pixelSize: 2 * app.baseUnit
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: "white"
                    }

                    onClicked: {
                        attachmentImagePanel.shareModifiedAttachmentUrl("share")
                    }
                }
            }

            function shareModifiedAttachmentUrl(action) {
                let currentAttachment = attachmentsListModel.get(featuresList.currentIndex);

                // fetch attachment data if not already fetched. This is required for attachments other than images
                currentAttachment.fetchDataStatusChanged.connect(() => {
                                                                     if( currentAttachment.fetchDataStatus === Enums.TaskStatusCompleted ) {
                                                                         let attachmentUrl =   attachmentsListModel.get(featuresList.currentIndex).attachmentUrl
                                                                         if (attachmentUrl > "") {
                                                                             let modPath = attachmentUrl.toString();
                                                                             if(Qt.platform.os === "windows") {
                                                                                 let tempPath;
                                                                                 if(modPath.includes("file:///")){
                                                                                     tempPath = modPath.split("file:///")[1]
                                                                                 }
                                                                                 else
                                                                                 tempPath = modPath.split("file://")[1]

                                                                                 modPath = tempPath.replace(":/","://")
                                                                             } else
                                                                             modPath = attachmentUrl.toString().split("file://")[1]

                                                                             let modifiedFileUrl = AppFramework.resolvedPathUrl(modPath);
                                                                             if (action === "share") {
                                                                                 if(AppFramework.clipboard.supportsShare) {
                                                                                     AppFramework.clipboard.share(modifiedFileUrl)
                                                                                 }
                                                                                 else {
                                                                                     let _attachments = []
                                                                                     let localfile = AppFramework.urlInfo(modifiedFileUrl).localFile
                                                                                     _attachments.push(localfile)
                                                                                     let _listattachments = _attachments.join(',')
                                                                                     emailcomposer.attachments = _listattachments
                                                                                     emailcomposer.show()

                                                                                 }
                                                                             } else if (action === "open") {
                                                                                 AppFramework.openUrlExternally(modifiedFileUrl)
                                                                             }
                                                                         }
                                                                     }
                                                                 })

                if(currentAttachment.fetchDataStatus  !== Enums.TaskStatusInProgress)
                    currentAttachment.fetchData()
            }
        }

        Behavior on anchors.bottomMargin { NumberAnimation { duration: 100 } }
    }

    // ------------ Compose and share via emails --------------

    EmailComposer {
        id: emailcomposer
        subject: ("%1 %2").arg(strings.attachment).arg(app.info.title || "Nearby")
        body: ""
        html: true

        onErrorChanged: {
            var reason = error.errorCode
            switch (reason) {
            case EmailComposerError.ErrorInvalidRequest:
                app.messageDialog.show("",app.invalid_request)
                break;
            case EmailComposerError.ErrorServiceMissing:
                app.messageDialog.show("",app.mail_service_not_configured)
                break;
            case EmailComposerError.ErrorFileRead:
                app.messageDialog.show("",app.invalid_attachment)
                break;
            case EmailComposerError.ErrorPermission:
                app.messageDialog.show("",app.permission_error)
                break;
            case EmailComposerError.ErrorNotSupportedFeature:
                messageDialog.open();
                app.messageDialog.show("",app.platform_not_supported)
                break;
            default:
                messageDialog.open();
                app.messageDialog.show("",app.unknown_error)
            }
        }
    }

    // ------------ Callback function for network request component --------------

    function imageDownloaded() {
        toastMessage.show(strings.image_downloaded)
    }

    // ------------ Network request component --------------

    Component {
        id: networkRequestComponent
        NetworkRequest{
            id: networkRequest

            property var name;
            property var callback;

            method: "GET"
            ignoreSslErrors: true

            onReadyStateChanged: {
                if (readyState === NetworkRequest.DONE ){
                    if(errorCode != 0){

                    } else {

                        if (callback) {
                            callback();
                        }
                    }
                }
            }

            function downloadImage(picUrl,downloadPath,callback){
                networkRequest.url = picUrl;
                networkRequest.responsePath = downloadPath
                networkRequest.callback = callback;
                networkRequest.send();
            }
        }
    }

    onOpenRoute:{
        openRoutePage(selectedSearchDistanceMode);
    }

    // On close of Drawer re-align the flickable's (x, y) to (0, 0)
    onClosed: {
        flickable.contentX = 0;
        flickable.contentY = 0;
    }

    // On open forceActiveFocus() to enable capturing Keys.onPressed and Keys.onReleased functionalities
    onOpened:{
        photoModeHeader.forceActiveFocus()
    }

    // ------ Alias item which represents the actual UI Item inside NavigationShareSheet.qml and Loader file

    property alias identifyPageNavSheet: identifyPageNavSheetLoader.item
    property alias identifyPageNavSheetLoader: identifyPageNavSheetLoader

    // ------ Loader QMLtype to dynamically load the Navigation bottom sheet into the directions page ------

    Loader {
        id: identifyPageNavSheetLoader
        width: parent.width
        height: parent.height
    }

}

