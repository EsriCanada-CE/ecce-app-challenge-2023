import QtQuick 2.7
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework.Platform 1.0

import "../controls" as Controls

ColumnLayout {
    id: searchView

    property real headerHeight: 0.8 * app.headerHeight
    property real expandIconSize: app.units(40)
    property alias listView: listView
    property string defaultSearchViewTitleText: ""
    property string searchViewTitleText: defaultSearchViewTitleText
    property string sectionPropertyAttr: ""
    property bool searching
    property bool hideResults: false
    property string locationWarningText:qsTr("Enable location permission in settings to show search results by distance")


    signal searchResultSelected(var feature, var featureIndex, bool closeSearchPageOnSelection)


    Controls.BaseText {
        id: searchViewTitle

        LayoutMirroring.enabled: app.isRightToLeft
        LayoutMirroring.childrenInherit: app.isRightToLeft

        visible: !searching && !hideResults
        text: searchViewTitleText
        Layout.alignment: Qt.AlignTop || Qt.AlignLeft

        Layout.topMargin: app.defaultMargin
        Layout.leftMargin: app.units(12)
        rightPadding: app.defaultMargin

        Layout.bottomMargin: 0

        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        maximumLineCount: 6
        Layout.fillWidth: true
        elide: Text.ElideRight
    }

    Rectangle{
        Layout.topMargin: 6 * scaleFactor
        Layout.leftMargin: (parent.width - ((323/360) * parent.width))/2
        Layout.preferredHeight:locationPermissionWarning.height + 16 * scaleFactor
        Layout.preferredWidth: (323/360) * parent.width
        radius: 4
        visible:((Qt.platform.os === "ios") || (Qt.platform.os == "android"))?app.hasLocationPermission ? false:true:false

        Rectangle{
            anchors.fill: parent
            color:app.primaryColor
            opacity:0.33
            radius:4
            visible:((Qt.platform.os === "ios") || (Qt.platform.os == "android"))?app.hasLocationPermission ? false:true:false

        }


        RowLayout{
            spacing:0
            width:parent.width
            height:parent.height

            Rectangle {
                id: layerIcon
                Layout.preferredHeight: 20 * scaleFactor
                Layout.preferredWidth: 20 * scaleFactor
                Layout.topMargin: (parent.height - 16 * scaleFactor)/2
                Layout.bottomMargin: (parent.height - 16 * scaleFactor)/2
                Layout.leftMargin: 11 * scaleFactor
                color:"transparent"


                Image {
                    id: lyr
                    source: "../images/round_info_white_48dp.png"
                    anchors.fill: parent
                }

                ColorOverlay {
                    id: layerMask
                    anchors {
                        fill: lyr
                    }
                    source: lyr
                    color: app.primaryColor
                }
            }
            Controls.CustomText {
                id: locationPermissionWarning
                Layout.preferredWidth: 250/360 * parent.width
                text: locationWarningText

                color: app.baseTextColor
                Layout.leftMargin: 12 * scaleFactor
                wrapMode: Text.WordWrap

                elide: Text.ElideRight
            }



        }
        }

    ListView {
        id: listView

        property string firstSection: (count && sectionPropertyAttr > "") ? listView.model.get(0)[sectionPropertyAttr] : ""
        property var sectionsCount: new Object
        property alias buttonGroup: buttonGroup

        ButtonGroup {
            id: buttonGroup
        }

        Layout.alignment: Qt.AlignTop
        Layout.preferredWidth: parent.width
        Layout.fillHeight: true
        visible: !hideResults
        //headerPositioning: ListView.PullBackHeader
        currentIndex: -1
        clip: true
        spacing: 0
        section {
            id: sectionItem

            property: sectionPropertyAttr
            delegate: Pane {
                id: sectionDelegate

                clip: true
                height: app.units(66)//headerHeight
                width: parent.width
                z: app.baseUnit
                Material.background: "white" //Qt.darker(app.backgroundColor, 1.1)
                padding: 0

                RowLayout {
                    anchors {
                        leftMargin: 2  * app.baseUnit
                        rightMargin: app.baseUnit
                        fill: parent
                    }

                    Label{
                        text:listView.sectionsCount.hasOwnProperty(section) ?
                          ( app.isRightToLeft ? "(%L1) %2".arg(listView.sectionsCount[section]).arg(section) : "%1 (%L2)".arg(section).arg(listView.sectionsCount[section]) )
                          : ""
                        color:"#2B2B2B"//app.subTitleTextColor
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: parent.width  - expandIcon.width
                        Layout.preferredHeight: parent.height
                        font.pixelSize: 0.8 * 14 //* app.scaleFactor
                        font.bold: true
                        font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                        rightPadding: app.units(16)
                    }

                    Item{
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }



                    Controls.Icon {
                        id: expandIcon

                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: expandIconSize
                        Layout.preferredHeight: Layout.preferredWidth
                        maskColor: "#2B2B2B"//app.subTitleTextColor
                        imageSource: "../images/arrowDown.png"
                        rotation: state === "EXPANDED" ? 180 : 0

                        onClicked: {
                            sectionDelegate.toggle()
                        }
                    }
                }



                Rectangle {
                    width: parent.width
                    height: app.units(1)
                    color: app.separatorColor//Qt.darker(app.separatorColor, 1.2)
                    anchors.top: parent.top
                    opacity: 0.5
                }
                 Rectangle {
                    width: parent.width
                    height: app.units(1)
                    color: app.separatorColor//Qt.darker(app.separatorColor, 1.2)
                    anchors.bottom: parent.bottom
                    opacity: 0.5
                }

                state: section === listView.firstSection ? "EXPANDED" : ""
                states: [
                    State {
                        name: "EXPANDED"

                        PropertyChanges {
                            target: expandIcon
                            rotation: 180
                        }
                    }
                ]

                onStateChanged: {
                    if (state === "EXPANDED") {
                        listView.expandSection(listView.section.property, section, true)
                    } else {
                        listView.collapseSection(listView.section.property, section, false)
                    }
                }

                function toggle () {
                    state = state === "EXPANDED" ? "" : "EXPANDED"
                }
            }
        }

        onCountChanged: {
            setSectionsCount()
        }

        function setSectionsCount () {
            listView.sectionsCount = new Object
            for (var i=0; i<listView.model.count; i++) {
                var item = listView.model.get(i)
                if (!listView.sectionsCount.hasOwnProperty(item[sectionPropertyAttr])) {
                    listView.sectionsCount[item[sectionPropertyAttr]] = 1
                } else {
                    listView.sectionsCount[item[sectionPropertyAttr]] = listView.sectionsCount[item[sectionPropertyAttr]] + 1
                }
            }
        }

        function expandSection (sectionProperty, section, expand) {
            for (var i=0; i<listView.model.count; i++) {
                var item = listView.model.get(i)
                if (item[sectionProperty] === section) {
                    item["showInView"] = expand
                }
            }
        }

        function collapseSection (sectionProperty, section, expand) {
            for (var i=0; i<listView.model.count; i++) {
                var item = listView.model.get(i)
                if (item[sectionProperty] === section) {
                    item["showInView"] = expand
                }
            }
        }
    }

    onSearchingChanged: {
        if (!searching) {
            listView.currentIndex = -1
        }
    }

    function reset () {
        searchViewTitleText = defaultSearchViewTitleText
    }
}
