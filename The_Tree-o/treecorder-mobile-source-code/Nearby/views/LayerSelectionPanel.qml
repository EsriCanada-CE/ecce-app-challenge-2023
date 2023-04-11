import QtQuick 2.7
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.1
import QtGraphicalEffects 1.0
import QtQuick.Controls.Material 2.1

import Esri.ArcGISRuntime 100.14

import "../../MapViewer/controls" as Controls
import "../../MapViewer/views" as Views

Rectangle {
    id: layerSelectionPanel

    property real minDelegateHeight: 2 * app.units(56)
    property real headerHeight:0.8 * app.headerHeight
    property int currentIndex:0
    property ListModel layerModel
    signal applied(var layername)


    width: parent.width
    height: 200 * app.scaleFactor

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        anchors.leftMargin: app.defaultMargin
        anchors.rightMargin: app.defaultMargin

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 2 * app.baseUnit
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: headerHeight

            Label {
                id: headerText

                anchors.fill: parent
                text: strings.select_a_layer
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideLeft
                font.pixelSize: 20 * app.scaleFactor
                font.family: "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                font.bold: true
                color: "#4C4C4C"
            }

        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 2 * app.baseUnit
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: layerListView

                anchors.fill: parent

                clip: true

                model:layerModel

                spacing: 20 * app.scaleFactor

                delegate: Item {
                    width: parent.width
                    height: 2 * app.units(10)//app.baseUnit

                    RowLayout {
                        anchors.fill: parent

                        spacing: 0
                        Item {
                            Layout.fillHeight: true
                            Layout.preferredWidth: app.iconSize

                            RadioButton {
                                id: radioButton
                                anchors.centerIn: parent
                                checkable: true
                                checked: index === currentIndex//isChecked
                                Material.primary: app.primaryColor
                                Material.accent: app.accentColor
                                Material.theme:Material.Light
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                            Layout.preferredWidth: layerNameTxt.width
                            Controls.BaseText {
                                id: layerNameTxt

                                objectName: "layerName"

                                width:300
                                text: name
                                leftPadding: 0
                                wrapMode: Text.WordWrap
                                maximumLineCount: 1
                                textFormat: Text.StyledText
                                Material.accent: app.accentColor
                                //                            verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                                fontsize: 16 * app.scaleFactor
                                color: "#4C4C4C"
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {

                            layerListView.currentIndex = index;
                            currentIndex = index
                            applied(layerModel.get(layerListView.currentIndex));
                        }
                    }
                }
            }

        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 20 * app.scaleFactor
        }

    }

    BusyIndicator {
        id: busyIndicator

        width: app.iconSize
        visible: false//mapView.identifyProperties.featuresCount && !count
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

    Component.onCompleted: {
        for(var k=0;k<layerModel.count;k++)
        {
            if(layerModel.get(k) === mapPage.layerName)
            {
                layerListView.currentIndex = k
                break
            }
        }


    }

}



