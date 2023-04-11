import QtQuick 2.7
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.1
import QtGraphicalEffects 1.0
import QtQuick.Controls.Material 2.1

import Esri.ArcGISRuntime 100.14

import "../controls" as Controls

ListView {
    id: identifyFeaturesView

    property string layerName: "test"
    property string popupTitle: ""
    property string distanceText: ""
    property real minDelegateHeight: 2 * app.units(56)
    property real headerHeight:0.8 * app.headerHeight
    property bool showDistance: true
    property bool showDirections: true
    property bool isDirLyr: false

    signal openRoute()

    clip: true
    spacing: 0
    //headerPositioning: ListView.OverlayHeader
    //cacheBuffer: count * (delegateHeight + spacing)

    header: Item {
        width: parent.width
        height: headerColumn.height
        visible: true//count > 0 && headerText.text > ""

        ColumnLayout {
            id: headerColumn

            width: parent.width
            spacing: 0

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: headerHeight
                Layout.leftMargin: app.defaultMargin
                Layout.rightMargin: app.defaultMargin
                Layout.topMargin: 8 * app.scaleFactor
                Layout.bottomMargin: directionMileRow.visible ? 0 : 8 * app.scaleFactor

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Rectangle {
                        id: layerIcon
                        Layout.preferredHeight: Math.min(parent.height - app.defaultMargin, app.iconSize)
                        Layout.preferredWidth:Layout.preferredHeight
                        visible:!popupTitle > ""
                        color: "#F4F4F4"

                        Image {
                            id: lyr
                            source: "../images/layers.png"
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
                        visible:!popupTitle > ""

                    }

                    Label {
                        id: layerNameText

                        elide: Text.ElideRight
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        text: popupTitle > ""? popupTitle.trim() :layerName
                        font.pixelSize: 16 * app.scaleFactor
                        font.bold: true
                        font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                        color: colors.blk_200
                        wrapMode: Text.WrapAnywhere

                        textFormat: isHTML(text)? Text.RichText:Text.PlainText

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
                Layout.preferredHeight: app.units(64)
                Layout.leftMargin: app.defaultMargin
                Layout.rightMargin: app.defaultMargin

                visible: (showDirections && isDirLyr) || showDistance

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Label {
                        id: distanceLabel

                        elide: Text.ElideRight
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        text: showDistance ? distanceText : ""
                        font.pixelSize: 16 * app.scaleFactor
                        font.bold: true
                        font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                        color: colors.blk_200
                        wrapMode: Text.WrapAnywhere
                    }

                    Item {
                        Layout.preferredWidth: 16 * app.scaleFactor
                        Layout.fillHeight: true
                    }

                    Item {
                        Layout.preferredWidth: 120 * app.scaleFactor
                        Layout.preferredHeight: 32 * app.scaleFactor
                        Layout.alignment: Qt.AlignVCenter

                        visible: showDirections && isDirLyr

                        Rectangle {
                            anchors.fill: parent
                            radius: 4 * app.scaleFactor
                            color: "transparent"
                            border.color: "#BBBBBB"
                            border.width: app.scaleFactor

                            RowLayout {
                                anchors.fill: parent
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
                                    Layout.preferredWidth: 8 * app.scaleFactor
                                    Layout.fillHeight: true
                                }

                                Label {
                                    id: directionText

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true
                                    elide: Label.ElideRight
                                    wrapMode: Text.Wrap
                                    font.pixelSize: 14 * app.scaleFactor
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignLeft
                                    font.bold: true

                                    color:  colors.blk_200
                                    text: strings.direction
                                }

                                Item {
                                    Layout.preferredWidth: 8 * app.scaleFactor
                                    Layout.fillHeight: true
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                openRoute();
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

        //visible: (lbl.text > "" && desc.text > "")
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

                Rectangle{
                    id: item
                    Layout.preferredWidth: panelPage.width - app.units(32)
                    Layout.preferredHeight:text1.height
                    visible:description > ""
                    Layout.alignment: Qt.AlignCenter
                    color: "#F4F4F4"

                        Text {
                            id: text1
                            text: description !== undefined ? description : ""
                            anchors.left: parent.left
                            anchors.right: parent.right
//                            leftPadding: app.units(7)
                            wrapMode: Text.WordWrap
                            textFormat: Text.RichText
                            visible:description > ""
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

//                Controls.SubtitleText {
//                    id: lbl

//                    objectName: "label1"
//                    // visible:(lbl.text > "" && desc.text > "")
//                    text:typeof label !== undefined ? (label ? label : "") : ""
//                    Layout.fillWidth: true
//                    Layout.preferredHeight: implicitHeight
////                    Layout.leftMargin: app.defaultMargin
////                    Layout.rightMargin: app.defaultMargin
//                    elide: Text.ElideMiddle
//                    wrapMode: Text.WrapAnywhere

//                    color: colors.blk_140
//                    font.pixelSize: 14 * app.scaleFactor

//                }

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

//                Controls.BaseText {
//                    id: desc

//                    objectName: "description"
//                    // visible:(lbl.text > "" && desc.text > "")

//                    Layout.fillWidth: true
//                    Layout.preferredHeight: this.implicitHeight
////                    Layout.leftMargin: app.defaultMargin
////                    Layout.rightMargin: app.defaultMargin

//                    color: colors.blk_200
//                    font.pixelSize: 14 * app.scaleFactor

//                    wrapMode: Text.WordWrap
//                    textFormat: Text.StyledText
//                    Material.accent: app.accentColor

//                    onLinkActivated: {
//                        mapViewerCore.openUrlInternally(link)
//                    }

//                    Component.onCompleted: {
//                        text = (typeof formattedValue !== "undefined" ? (formattedValue ? formattedValue : " ") : (typeof fieldValue !== "undefined" ? (fieldValue ? fieldValue : " ") : " ")).replace(/(http:\/\/[^\s]+)/gi , '<a href="$1">$1</a>').replace(/(https:\/\/[^\s]+)/gi , '<a href="$1">$1</a>');

//                        elide = Text.ElideLeft;
//                    }
//                }

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

    footer:Rectangle{
        height:isIphoneX?36 * scaleFactor :16 * scaleFactor
        width:identifyFeaturesView.width
        color:"transparent"
    }

    Controls.BaseText {
        id: message

        visible: (count <= 0 && text > "" && !busyIndicator.visible) || (identifyFeaturesView.contentHeight <= headerHeight && !busyIndicator.visible)
        maximumLineCount: 5
        elide: Text.ElideRight
        width: parent.width
        height: parent.height
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: qsTr("There are no attributes configured.")
    }

    BusyIndicator {
        id: busyIndicator

        width: app.iconSize
        visible: identifyInProgress//mapView.identifyProperties.featuresCount && !count
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


