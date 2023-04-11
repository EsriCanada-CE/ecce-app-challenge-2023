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
import QtQuick.Layouts 1.1

import ArcGIS.AppFramework 1.0

Drawer {
    id: root

    property var menuItems: []
    property real defaultMargin: root.getAppProperty(app.defaultMargin, root.units(16))
    property real delegateHeight: root.units(56)
    property real iconSize: root.units(16)
    property color backgroundColor: "white"//root.getAppProperty(app.backgroundColor, "#F7F8F8")
    property color highlightColor: Qt.darker(root.getAppProperty(app.backgroundColor, "#F7F8F8"), 1.1)
    property color textColor: root.getAppProperty(app.baseTextColor, "#F7F8F8")
    property color primaryColor: root.getAppProperty(app.primaryColor, "#166DB2")
    property color iconColor: "#4C4C4C"

    property bool isCompact: false

    property real fontScale: 1.0

    property real controlsFontSize: 16
    property string fontFamilyName: ""


    property QtObject contentHeader

    signal menuItemSelected (string itemLabel)

    edge: app.isRightToLeft ? Qt.RightEdge : Qt.LeftEdge


    Material.background:"white"

    width: parent.width
    height: parent.height
    padding: 0



    contentItem: BasePage {
        id: menu

        padding: 0
        anchors {
            fill: parent
            margins: 0
        }
        Material.background:"white"
        LayoutMirroring.enabled: app.isRightToLeft
        LayoutMirroring.childrenInherit: app.isRightToLeft

        contentItem: Pane {
            padding: 0
            anchors {
                top: parent.top//pageHeader.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                //topMargin: root.contentHeader ? undefined : root.defaultMargin
            }

            ColumnLayout{
                id: sideMenuLayout
                width: parent.width
                height:parent.height
                spacing: 0


                UserProfileSection {
                 visible:app.isSignedIn
                    onClickSignIn: {

                        sideMenu.close();
                        app.focus = true;
                        app.openSignInPage();
                    }

                    onClickSignOut: {
                        if(app.urlParameters)
                            app.urlParameters = {}
                        mapViewerCore.signOut()
                        //app.signOut()
                        app.isMMPKsLoaded = false;
                        app.isWebMapsLoaded = false;
                        close();
                    }
                }

                Rectangle {
                    visible:app.isSignedIn
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: colors.blk_020
                }




                ListView {
                    id: menuView

                    clip: true
                    spacing:0 //app.units(4)
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.topMargin: 0//app.units(16)
                    interactive:false

                    model: menuModel

                    header: root.contentHeader

                    delegate: Card {
                        id: menuItem

                        headerHeight: 0
                        footerHeight: 0
                        padding: 0
                        borderColor: backgroundColor
                        hoverAllowed: false
                        height: root.delegateHeight
                        propagateComposedEvents: false
                        preventStealing: false
                        Material.elevation: 0
                        content:

                            ColumnLayout{
                                anchors.fill:parent
                                spacing:0


                                RowLayout {
                                    id: itemRow
                                    width:parent.width
                                    height:parent.height// - app.units(5)


                                    //anchors.fill: parent
                                    spacing: 0



                                    //                                Rectangle {
                                    //                                    id: iconImg

                                    //                                    Layout.fillHeight: true
                                    //                                    //Layout.fillWidth: true
                                    //                                    Layout.leftMargin: app.units(6)
                                    //                                    Layout.preferredWidth:menuIcon.width//app.units(56) //height
                                    //                                    //Layout.maximumHeight: root.headerHeight
                                    //                                    color: "transparent"

                                    //                                    Icon {
                                    //                                    id:menuIcon
                                    //                                        anchors {
                                    //                                            left: parent.left
                                    //                                            verticalCenter: iconImage > "" ? parent.verticalCenter : undefined
                                    //                                        }
                                    //                                        visible: imageSource > ""
                                    //                                        imageSource: typeof iconImage !== "undefined" ? iconImage : ""
                                    //                                        maskColor: iconColor
                                    //                                        height: Math.min(root.iconSize, parent.height)
                                    //                                        width: height
                                    //                                        leftPadding: 0
                                    //                                    }
                                    //                                }
                                    Item{
                                        Layout.fillHeight: true
                                        Layout.preferredWidth:app.units(16)

                                    }

                                    //BaseText {
                                    Label{

                                        id: label
                                        font.pixelSize: 16 * scaleFactor
                                        font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")                           
                                        text: itemLabel                                     
                                        horizontalAlignment: Text.AlignLeft                                      
                                        Layout.alignment: Qt.AlignVCenter                                      
                                        color: root.textColor
                                        elide: Text.ElideRight
                                        maximumLineCount: 2
                                    }

                                    Item{
                                        Layout.fillHeight: true
                                        Layout.fillWidth: true

                                    }


                                }

                                Rectangle {
                                    width: root.width
                                    height: app.units(1)
                                    color: colors.blk_020
                                    visible:index !== menuModel.count - 1
                                }
                            }


                        onClicked: {
                            if (!control.length) {
                                menuItemSelected(itemLabel)
                            }
                        }
                    }
                }


            }
            ListModel {
                id: menuModel
            }
        }
    }

    onMenuItemSelected: {
        close()
    }

    onVisibleChanged: {
        menuModel.clear()
        if (visible) {
            updateMenu()
        }
    }

    function updateMenu () {
        menuModel.clear()
        for (var i=0; i<root.menuItems.length; i++) {
            menuModel.append(root.menuItems[i])
        }
    }

    function toggle () {
        return visible ? close () : open ()
    }

    function getAppProperty (appProperty, fallback) {
        if (!fallback) fallback = ""
        try {
            return appProperty ? appProperty : fallback
        } catch (err) {
            return fallback
        }
    }

    function appendItemsToMenuList (items) {
        root.menuItems = items.concat(root.menuItems)
    }

    function insertItemToMenuList (idx, item) {
        root.menuItems.splice(idx, 0, item)
    }

    function removeItemsFromMenuListByAttribute (attr, value) {
        var newArr = []
        for (var i=0; i<menuItems.length; i++) {
            if (menuItems[i][attr] !== value) {
                newArr.push(menuItems[i])
            }
        }
        menuItems = newArr
    }

    function removeItemsFromMenuListByString (str) {
        var newArr = []
        for (var i=0; i<menuItems.length; i++) {
            var hasString = false
            for (var key in menuItems[i]) {
                if (menuItems[i].hasOwnProperty(key)) {
                    if (key.includes(str) || menuItems[i][key].includes(str)) {
                        hasString = true
                        break
                    }
                }
            }
            if (!hasString) newArr.push(menuItems[i])
        }
        menuItems = newArr
    }

    function units (num) {
        return num ? num * AppFramework.displayScaleFactor : num
    }

}
