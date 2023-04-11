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
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1


import Esri.ArcGISRuntime 100.14
import ArcGIS.AppFramework.Platform 1.0

import "../controls" as Controls

Controls.BasePage {
    id: startPage

    Material.background: app.primaryColor
    property var promiseToGoToNextPageOnSignIn: onNextPage(stackView)


    contentItem: Rectangle {
        anchors.fill: parent
        color: "transparent"

        AnimatedImage {
            source: app.startBackground
            fillMode: Image.PreserveAspectCrop
            anchors.fill: parent
            opacity: 0.5
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 2 * app.defaultMargin

            Controls.SpaceFiller {
            }

            Controls.TitleText {
                id: title

                Layout.preferredWidth: parent.width
                Layout.maximumWidth: app.preferredContentWidth
                Layout.alignment: Qt.AlignHCenter
                text: app.info.title
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Controls.BaseText {
                id: subtitle

                Layout.preferredWidth: parent.width
                Layout.maximumWidth: app.preferredContentWidth
                Layout.alignment: Qt.AlignHCenter
                color: app.titleTextColor
                text: app.info.snippet
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Controls.SpaceFiller {
            }

            Controls.SpaceFiller {
            }

            Controls.SpaceFiller {
            }

            Button {
                id: startBtn

                property string kSignIn: strings.sign_in
                property string kStart: qsTr("START")
                enabled: app.canShowStartButton

                visible: !isSigningInIndicator.visible
                text: app.supportSecuredMaps ? kSignIn : kStart
                Material.background: app.backgroundColor
                Material.accent: app.accentColor
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.min(0.33 * parent.width, app.units(140))
                Layout.preferredHeight: 6 * app.baseUnit
                Layout.bottomMargin: skip.visible ? 0 : height
                contentItem: Controls.BaseText {
                    text: startBtn.text
                    font: startBtn.font
                    color: app.primaryColor //control.down ? "#17a81a" : "#21be2b"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {

                    if (startBtn.text === kSignIn) {
                        if(!app.isClientIDNeeded || app.clientId) {
                            mapViewerCore.createSignInPage()
                        }
                        else{
                            messageDialog.show(app.strings.clientID_missing,app.strings.clientID_missing_message)
                        }
                    } else {
                        app.loadPublicPortal()
                        nextPage()
                    }
                }
            }

            Controls.BaseText {
                id: skip
                enabled: app.canShowStartButton

                visible: startBtn.visible && startBtn.text === startBtn.kSignIn && app.enableAnonymousAccess
                text: qsTr("Skip")
                color: app.titleTextColor
                horizontalAlignment: Text.AlignHCenter
                Layout.bottomMargin: startBtn.height
                Layout.preferredWidth: contentWidth + app.defaultMargin
                Layout.alignment: Qt.AlignHCenter

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                    if(app.isOnline)
                       app.loadPublicPortal()
                    nextPage()
                    }
                }
            }

            BusyIndicator {
                id: isSigningInIndicator

                visible: {
                    var publicPortalNotLoaded = app.publicPortal ? app.publicPortal.loadStatus !== Enums.LoadStatusLoaded : true
                    var securedPortalLoadingOrLoaded = app.portal  && !app.portal.error && app.portal.credential? app.portal.loadStatus === Enums.LoadStatusLoading || app.portal.loadStatus === Enums.LoadStatusLoaded : false
                    return app.supportSecuredMaps && publicPortalNotLoaded && securedPortalLoadingOrLoaded
                }
                Layout.alignment: Qt.AlignHCenter
                Material.primary: app.primaryColor
                Material.accent: Qt.lighter(app.accentColor)
                Layout.bottomMargin: startBtn.height
            }

            Timer {
                id: autoSignInTimeOut

                property int timeoutCount: 0

                interval: 10000
                running: true
                repeat: false
                onTriggered: {
                    isSigningInIndicator.visible = false
                    timeoutCount += 1
                }
            }
        }
    }

    function onNextPage(){
        var  p = new Promise(function(resolve,reject) {
            if(stackView.depth === 1 && app.isSignedIn)
                resolve(stackView)
        })
        p.then(function(result){
//            if(app.supportSecuredMaps && app.isSignedIn)
                nextPage()
        })
    }

    function nextPage () {
       startPage.next()
        /*if ( app.webMapsModel.count === 1 ) {
            app.showBackToGalleryButton = false
            app.openMap(app.webMapsModel.get(0))
        } else {
            startPage.next()
        }*/
    }
}
