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
import QtGraphicalEffects 1.0
import QtQuick.Controls.Material 2.1

import ArcGIS.AppFramework 1.0

Pane {
    id: root

    property int transitionDuration: 200
    property real pageExtent: 0
    property real base: root.height
    property real panelHeaderHeight:root.units(10)
    property real defaultMargin: root.units(16)
    property real appHeaderHeight: 0
    property real iconSize: units(16)
    property string transitionProperty: "y"
    property string title: ""
    property color backgroundColor: "#FFFFFF"
    property color headerBackgroundColor: "#CCCCCC"
    property color titleColor: "#4c4c4c"
    property color separatorColor: "#4C4C4C"
    property bool fullView: false
    property bool isIntermediateScreen:false
    property bool isMoreMenuVisible:false
    property bool isExpandIconVisible:true

    property bool showPageCount: false
    property int pageCount: 1
    property int currentPageNumber: 1
    property bool isHeaderVisible:true

    property Item content: Item {}

    property alias panelContent: panelContent
    property var panelPageHeight:parent?(fullView ?parent.height:parent.height - root.pageExtent): undefined

    signal expandButtonClicked ()
    signal previousButtonClicked ()
    signal nextButtonClicked ()

    signal backButtonPressed ()
    signal hidePanelPage()

    signal showMoreMenu(var x, var y)

    contentWidth: parent.width

    height:parent.height

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: app.isIphoneX ? app.units(16) : 0

    anchors {
               fill: parent

           }



    Item {
        id: screenSizeState

        states: [

            State {
                name: "LARGE"
                when: app.isLandscape

                PropertyChanges {
                    target: root
                    fullView: true
                }

                PropertyChanges {
                    target: closeBtn
                    visible: true
                }
                PropertyChanges {
                    target: backBtn
                    visible: false
                }

                PropertyChanges {
                    target: expandBtn
                    visible: false
                }
                 PropertyChanges {
                    target: menuicon
                    visible: isMoreMenuVisible ? true : false
                }

                PropertyChanges {
                    target: panelHeader
                    Material.elevation: 0
                }
            }
            ,

            State {
                name: "SMALL"
                when: !app.isLandscape

                PropertyChanges {
                    target: root
                    fullView: false
                    width: parent.width
                }

                PropertyChanges {
                    target: backBtn
                    visible: false
                }
                PropertyChanges {
                    target: closeBtn
                    visible: true
                }

                PropertyChanges {
                    target: menuicon
                    visible: isMoreMenuVisible ? true : false
                }

                PropertyChanges {
                    target: expandBtn
                    visible: isExpandIconVisible ? true : false
                }

                PropertyChanges {
                    target: panelHeader
                    Material.elevation: 0
                }
            }
        ]
    }


    contentItem:
        BasePage {
        id: panelContent

        //width:parent.width//app.units(200)
        contentWidth: parent.width

        padding: 0

        Material.background: root.backgroundColor

        header: ToolBar {
            id: panelHeader
            visible:isHeaderVisible

            height: root.panelHeaderHeight
            width:parent.width
            topPadding: panelPage.fullView ? app.notchHeight : 0
            //spacing: 0

            Material.background: root.headerBackgroundColor
            //Material.elevation: 0

            FocusScope {
                anchors.fill: parent
                focus: true
                Keys.onReleased: {
                    if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape){
                        event.accepted = true
                        backButtonPressed()
                    }
                }
                ColumnLayout {
                    anchors {
                        fill: parent
                        margins: 0
                    }

                    spacing: 0

                    RowLayout {
                        id: headerBtns
                        spacing: 0


                        Layout.fillWidth: true
                        Layout.margins: 0

                        Icon {
                            id: closeBtn
                            visible:false



                            Material.background: root.backgroundColor
                            Material.elevation: 0
                            maskColor: "#4c4c4c"
                            imageSource: "images/close.png"

                            onClicked: {
                                pageView.hidePanelItem()
                            }
                        }

                        Icon {
                            id: backBtn

                            visible:false
                            Material.background: root.backgroundColor
                            Material.elevation: 0
                            Layout.alignment: Qt.AlignVCenter
                            maskColor: "#4c4c4c"
                            rotation: app.isRightToLeft ? 180 : 0
                            imageSource: "images/back.png"

                            onClicked: {
                                root.collapseFullView()
                            }
                        }

                        BaseText {
                            id: titleText

                            visible: !root.showPageCount
                            text: mapView !== null ? mapView.panelTitle : title
                            font.pixelSize: 15
                            color: titleColor
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            font.family: titleFontFamily
                            Layout.alignment: Qt.AlignVCenter
                            verticalAlignment: Text.AlignVCenter
                            Layout.preferredWidth: parent.width - closeBtn.width - expandBtn.width - 4 * root.defaultMargin
                            Layout.preferredHeight: contentHeight


                        }

                        RowLayout {
                            id: pageCount
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                            visible: root.showPageCount
                            Layout.rightMargin: app.defaultMargin
                            SpaceFiller { Layout.preferredWidth: panelPage.width/4 }
                            //SpaceFiller { Layout.preferredWidth: parent.width/4 }

                            Icon {
                                id: previousPage

                                Material.background: root.backgroundColor
                                Material.elevation: 0
                                maskColor: "#4c4c4c"
                                enabled: root.currentPageNumber > 1
                                rotation: 90
                                imageSource: "images/arrowDown.png"
                                Layout.alignment: Qt.AlignHCenter

                                onClicked: {
                                    previousButtonClicked()
                                }
                            }

                            BaseText {
                                id: countText

                                text: qsTr("%1 of %2").arg(root.currentPageNumber).arg(root.pageCount)
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                font.family: titleFontFamily
                                verticalAlignment: Text.AlignVCenter
                                Layout.alignment: Qt.AlignHCenter

                            }

                            Icon {
                                id: nextPage

                                Material.background: root.backgroundColor
                                Material.elevation: 0
                                maskColor: "#4c4c4c"
                                enabled: root.currentPageNumber < root.pageCount
                                rotation: -90
                                imageSource: "images/arrowDown.png"
                                Layout.alignment: Qt.AlignHCenter

                                onClicked: {
                                    nextButtonClicked()
                                }
                            }

                            SpaceFiller { Layout.preferredWidth: panelPage.width/4 + closeBtn.width }
                            // SpaceFiller { Layout.preferredWidth: parent.width/4 + closeBtn.width }
                        }

                        SpaceFiller { Layout.fillHeight: false }

                          Rectangle{
                            Layout.preferredWidth: menuicon.visible ?app.units(30) : 0
                            Layout.rightMargin: app.baseUnit
                            Layout.fillHeight: true
                            color:"transparent"

                            Icon {
                                id: menuicon
                                visible:true
                                anchors.centerIn: parent

                                //Material.background: root.backgroundColor
                                Material.elevation: 0
                                maskColor: "#4c4c4c"
                                //rotation: 180
                                imageSource: "../../MapViewer/images/more.png"

                                onClicked: {
                                    showMoreMenu(menuicon.parent.x, menuicon.parent.y)

                                }
                            }

                        }
                        Rectangle{
                            Layout.preferredWidth: expandBtn.visible ?app.units(30) : 0
                            Layout.rightMargin: app.baseUnit
                            Layout.fillHeight: true
                            color:"transparent"

                            Icon {
                                id: expandBtn
                                visible:true
                                anchors.centerIn: parent

                                //Material.background: root.backgroundColor
                                Material.elevation: 0
                                maskColor: "#4c4c4c"
                                rotation: 180
                                imageSource: "images/arrowDown.png"

                                onClicked: {
                                    backBtn.visible = true
                                    closeBtn.visible = false
                                    expandBtn.visible = false
                                    fullView = true
                                    expandButtonClicked()
                                }
                            }
                        }
                    }
                }
            }
        }

        contentItem: root.content
    }

    MouseArea {
        anchors.fill: parent
        preventStealing: true
        onWheel: {
            wheel.accepted = true
        }
    }



    onCurrentPageNumberChanged: {
        nextPage.enabled = root.currentPageNumber < root.pageCount
        previousPage.enabled = root.currentPageNumber > 1
    }

    onPageCountChanged: {
        nextPage.enabled = root.currentPageNumber < root.pageCount
        previousPage.enabled = root.currentPageNumber > 1
    }

    onNextButtonClicked: {
        if (root.currentPageNumber < root.pageCount) {
            root.currentPageNumber += 1
        }
    }

    onPreviousButtonClicked: {
        if (root.currentPageNumber > 1) {
            root.currentPageNumber -= 1
        }
    }



    function reset () {
        root.title = ""
        root.showPageCount = false
        root.pageCount = 1
        root.currentPageNumber = 1
    }

    function collapseFullView () {
        expandBtn.visible = true
        backBtn.visible = false
        closeBtn.visible = true
        fullView = false
        panelContent.state = "INTERMEDIATE"
        dockToBottom()
    }

    function createTransition (transitionProperty, duration, from, to, easingType) {
        var transition = transitionObject.createObject(root)
        transition.transitionProperty = transitionProperty || "y"
        transition.duration = duration || 200
        transition.from = from || root.height
        transition.to = to || 0
        transition.easingType = easingType || Easing.InOutQuad
        return transition
    }

    function toggle () {
        return visible ? close () : open ()
    }

    function units (num) {
        return num ? num * AppFramework.displayScaleFactor : num
    }
}
