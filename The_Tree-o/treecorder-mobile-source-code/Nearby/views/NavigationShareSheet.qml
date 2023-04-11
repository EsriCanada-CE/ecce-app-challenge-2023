import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15

import ArcGIS.AppFramework 1.0


import QtGraphicalEffects 1.0

import "../CustomizedItems" as CustomizedItems

import "../../MapViewer/controls" as Controls

// ------ NavigationShareSheet UI to display navigation bottom sheet in IdentifyPage and NearbyMapPage ------
CustomizedItems.BottomSheet {
    id: root

    property color backgroundColor: colors.white_100
    property color titleColor: colors.black_54
    property color labelTextColor: colors.black_87
    property color iconColor: colors.black_54
    property color disabledLabelTextColor: colors.grey_100
    property real maximumHeight: 0.0
    property color highlightColor: "#05000000"//Qt.lighter(root.getAppProperty(app.backgroundColor, "#F7F8F8"), 0.5)

    property string sheetTitle: ""

    property alias listModel: sheetListModel

    property bool isDisplayed: root.visible

    property var functions: []

    ListModel {
        id: sheetListModel
    }

    onClicked: {
        hideSheet();
    }

    Pane {
        id: sheetPane

        width: Math.min(parent.width, app.maximumScreenWidth)
        height: Math.min(sheetColumn.height, maximumHeight)
        Material.background: backgroundColor
        Material.elevation: state === "idle" ? 0 : 16
        anchors.top: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        state: "idle"
        padding: 0

        transitions: Transition {
            AnchorAnimation { easing.type: Easing.OutQuart; duration: interval }
        }

        // Handle changes in transition from BottomSheet open vs close
        states: [
            State {
                name: "idle"
                AnchorChanges { target: sheetPane; anchors { top: parent.bottom; bottom: undefined }}
            },
            State {
                name: "displaySheet"
                AnchorChanges { target: sheetPane; anchors { top: undefined; bottom: parent.bottom }}
            }
        ]

        Flickable {
            id: flickable

            anchors.fill: parent
            contentWidth: sheetColumn.width
            contentHeight: sheetColumn.height
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            ColumnLayout {
                id: sheetColumn

                width: flickable.width
                spacing: 0

                Label {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56 * app.scaleFactor

                    text: sheetTitle
                    clip: true
                    elide: Text.ElideRight

                    font.pixelSize: 16 * app.scaleFactor
                    color: titleColor


                    horizontalAlignment: Label.AlignLeft
                    verticalAlignment: Label.AlignVCenter

                    leftPadding: 16 * app.scaleFactor
                    rightPadding: 16 * app.scaleFactor
                    visible: sheetTitle > ""
                }

                Repeater {
                    model: sheetListModel

                    delegate: CustomizedItems.TouchGestureRectangle {
                        id: delegate

                        Layout.fillWidth: true
                        Layout.preferredHeight:itemrow.height
                        //Layout.preferredHeight: 48 * app.scaleFactor

                        color: colors.white_100
                        enabled: typeof(itemEnabled) === 'undefined'? false : itemEnabled

                        onClicked: {
                            functions[index]();
                            hideSheet();
                        }

                        RowLayout {
                            id:itemrow
                            height:itemName.height + app.units(22)
                            //anchors.fill: parent
                            spacing: 0

                            Label {
                                id:itemName

                                Layout.preferredWidth: sheetPane.width
                                //Layout.fillWidth: true
                                // Layout.fillHeight: true

                                text:itemLabel
                                //clip: true
                                elide: Text.ElideRight
                                font.bold: true
                                font.pixelSize: 16 * app.scaleFactor
                                color: ( typeof(itemEnabled) === 'undefined' || !itemEnabled ) ? disabledLabelTextColor : labelTextColor

                                horizontalAlignment: Label.AlignLeft
                                verticalAlignment: Label.AlignVCenter
                                maximumLineCount: 2
                                wrapMode: Text.Wrap


                                leftPadding: 16 * app.scaleFactor
                                rightPadding: 16 * app.scaleFactor
                            }


                        }

                        //
                        //property alias ink: ink


                        Controls.Ink {
                            id: ink

                            visible: true//delegate.clickable
                            propagateComposedEvents: true//delegate.propagateComposedEvents
                            //preventStealing: delegate.preventStealing
                            anchors.centerIn: parent
                            enabled: true
                            centered: true
                            circular: true
                            //hoverEnabled: delegate.hoverAllowed
                            width: parent.width
                            height: parent.height
                            states: [
                                State {
                                    name: "HOVERED"
                                    PropertyChanges {
                                        target: delegate
                                        color:root.highlightColor

                                    }
                                }
                            ]

                            transitions: Transition {
                                ColorAnimation {
                                    duration: 200
                                }
                            }

                            onClicked: {

                                delegate.state = "SELECTED"
                                delegate.clicked()
                            }

                            onEntered: {
                                ink.state = "HOVERED"
                                //delegate.entered()
                            }

                            onExited: {
                                ink.state = ""
                                // delegate.exited()
                            }
                        }

                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: app.isLandscape ? 48 * app.scaleFactor : 16 * app.scaleFactor
                }
            }
        }
    }

    function clearSettings() {
        sheetListModel.clear();

        backgroundColor = colors.white_100;
        titleColor = colors.black_54;
        labelTextColor = colors.black_87;
        iconColor = colors.black_54;
        maximumHeight = 0.0;
        sheetTitle = "";
        functions = [];
    }

    function displaySheet() {
        root.open();
        sheetPane.state = "displaySheet";
    }

    function hideSheet() {
        sheetPane.state = "idle";
        root.close();
    }
}
