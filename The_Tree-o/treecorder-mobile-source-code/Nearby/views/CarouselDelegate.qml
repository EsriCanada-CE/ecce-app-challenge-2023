import QtQuick 2.7
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Platform 1.0

import Esri.ArcGISRuntime 100.14

import "../../MapViewer/controls" as Controls
import "../../MapViewer/views" as Views

Item{
    id: carouselDelegate
    width: app.units(184)
    height: 160 * app.scaleFactor

    //color: "transparent"

    property string pageName: "media"
    property int  largeSourceHeight: 0
    property int  largeSourceWidth: 0
    property bool isSelected:false
    property alias _distanceText:distanceText
    property var distanceToFeature
    //signal mediaClicked(var key)

    signal openRoute()
    signal openDetail()
    signal openDamage()
    signal openCitSci()
    signal drawDistanceLine()
    signal clearDistanceLine()
    signal openElevationProfile()

    Rectangle {
        id: attachmentCards

        anchors.fill: parent
        anchors.margins: app.baseUnit
        radius: 8 * app.scaleFactor
        color: "white"
        z:1
        MouseArea {
            width:parent.width
            height:parent.height

            onClicked: {

                if(!isSelected)
                {
                    isSelected = true
                    if(mapView.includeDistance && !elevationButtonContainer.visible)
                    {
                        drawDistanceLine()
                        //zoomToDistanceLine()
                    }
                    distanceText.font.bold = true
                }
                else
                {
                    isSelected = false
                    distanceText.font.bold = false
                    clearDistanceLine()
                    mapPageCarouselView.highlightResult(mapView.featuresModel.get(index).initialIndex);
                }
            }
        }


        ColumnLayout {
            anchors.fill: parent
            anchors.margins: app.defaultMargin

            spacing: 0

            Label {
                id: featureName

                Layout.fillWidth: true
                Layout.preferredHeight: 32 * app.scaleFactor
                width: parent.width
                clip: true
                maximumLineCount: 2
                elide: Label.ElideRight
                wrapMode: Text.Wrap
                lineHeight: 16 * app.scaleFactor
                lineHeightMode: Text.FixedHeight
                font.pixelSize: 14 * app.scaleFactor
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                textFormat: /*isHTML(text)? Text.RichText:*/Text.PlainText

                font.bold: true
                color:  colors.blk_200
                //text: search_attr.trim() > ""? (isHTML(search_attr.trim()) ?convertHTMLtoPlainText (search_attr.trim()) : search_attr.trim() ): layerName.trim()
                text: "Tree"


                function isHTML(text){
                    var result = RegExp.prototype.test.bind(/(<([^>]+)>)/i);

                    return result(text);
                }

                function convertHTMLtoPlainText (text) {
                    let plainText = text;
                    plainText = plainText.replace(/\n/gi, "");
                    plainText = plainText.replace(/<style([\s\S]*?)<\/style>/gi, "");
                    plainText = plainText.replace(/<script([\s\S]*?)<\/script>/gi, "");
                    plainText = plainText.replace(/<a.*?href="(.*?)[\?\"].*?>(.*?)<\/a.*?>/gi, " $2 $1 ");
                    plainText = plainText.replace(/<\/div>/gi, "\n\n");
                    plainText = plainText.replace(/<\/li>/gi, "\n");
                    plainText = plainText.replace(/<li.*?>/gi, "  *  ");
                    plainText = plainText.replace(/<\/ul>/gi, "\n\n");
                    plainText = plainText.replace(/<\/p>/gi, "\n\n");
                    plainText = plainText.replace(/<br\s*[\/]?>/gi, "\n");
                    plainText = plainText.replace(/<[^>]+>/gi, "");
                    plainText = plainText.replace(/^\s*/gim, "");
                    plainText = plainText.replace(/ ,/gi, ",");
                    plainText = plainText.replace(/ +/gi, " ");
                    plainText = plainText.replace(/\n+/gi, "\n\n");
                    return plainText;
                }
            }

            Item {
                Layout.preferredHeight: 12 * app.scaleFactor
                Layout.fillWidth: true
            }

            Item {
                Layout.preferredHeight: 28 * app.scaleFactor
                Layout.fillWidth: true


                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    RowLayout{
                        id:distanceRow
                        //Layout.fillWidth: true
                        Layout.preferredHeight: 16 * app.scaleFactor
                        visible: !elevationButtonContainer.visible
                        spacing:0

                        Label {
                            id: distanceText
                            width:distanceRow.width - 20 * app.scaleFactor
                            height:parent.height

                            clip: true
                            elide: Label.ElideRight
                            wrapMode: Text.Wrap
                            font.pixelSize: 14 * app.scaleFactor
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                            font.bold:isSelected ? true : false

                            color:  app.primaryColor
                            text: mapView.includeDistance ? qsTr("%1 %2 from ").arg(distanceToFeature).arg(mapView.measureUnitsString):""
                            Connections{
                                target:mapPageCarouselView
                                /*function onMovementEnded(){
                                    distanceText.font.bold = false
                                }*/

                                function onMakeFontBold(selectedIndex){
                                    if(index === selectedIndex)
                                    {
                                        distanceText.font.bold = true
                                    }
                                }

                                /* function onCallDrawLine(selectedIndex){
                                    drawDistanceLine()
                                }*/

                            }

                            Connections{
                                target:mapView
                                function onSelectedSearchDistanceModeChanged(){
                                    if(!isInRouteMode){
                                        if(mapView.selectedSearchDistanceMode === "bufferCenter")
                                        {
                                            distanceToFeature = distance
                                        }
                                        else
                                        {
                                            let featureIndex = mapView.featuresModel.get(index).initialIndex
                                            let targetFeature = mapView.featuresModel.features[featureIndex]
                                            let centerPointOfFeature = targetFeature.geometry.extent.center
                                            let currentLocation  = mapView.locationDisplay.mapLocation
                                            let mydistance = mapView.getDistance(currentLocation, centerPointOfFeature);
                                            distanceToFeature = mapView.getNewDistance(mydistance, mapView.measureUnits);

                                        }
                                        if(mapView.featuresModel.count > 0)
                                        {
                                            if(distanceText.font.bold)
                                            {
                                                drawDistanceLine()
                                            }
                                        }
                                    }
                                }
                            }
                        }


                        Item {
                            id: directionsPinContainer
                            width: 24 * app.scaleFactor
                            height:parent.height

                            visible:mapView.includeDistance
                            Image {
                                id: locImg1
                                source:"../../MapViewer/images/redPin.png"
                                width: visible ?app.units(18):0
                                height:width //24//width
                                mipmap: true
                                anchors.centerIn: parent
                                visible:mapView.selectedSearchDistanceMode === "bufferCenter"
                            }



                            Image {
                                id: locImg2
                                source:"../../MapViewer/images/button_current_location.png"
                                width: visible?parent.width:0
                                height: width
                                mipmap: true
                                visible:mapView.selectedSearchDistanceMode != "bufferCenter"
                                anchors.centerIn: parent
                                fillMode: Image.PreserveAspectFit

                            }
                            ColorOverlay {
                                anchors.fill: locImg2
                                source: locImg2
                                visible: locImg2.visible
                                color: "steelblue"
                            }
                        }
                    }

                    Item {
                        id: fillerItem
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    Item {
                        id: elevationButtonContainer
                        Layout.preferredWidth: visible ? ( elevationButtonText.visible ? elevationButtonText.width : elevationButtonIcon.width ) : 0
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignRight
                        z: 100
                        visible: isElevationEnabled && geometryType === Enums.GeometryTypePolyline

                        RoundButton {
                            id: elevationButtonText

                            width: implicitWidth
                            height: 28 * app.scaleFactor
                            radius: 14 * app.scaleFactor
                            padding: 16 * app.scaleFactor
                            anchors.centerIn: parent

                            text: strings.elevation
                            Material.foreground: "white"

                            background: Rectangle{
                                anchors.fill: parent
                                color: "transparent"
                                radius: 15 * app.scaleFactor
                                border.color: app.primaryColor
                                border.width:1
                            }

                            Material.elevation: 1

                            visible: !elevationButtonIcon.visible

                            contentItem: Text {
                                text: elevationButtonText.text
                                font.pixelSize: 12 * app.scaleFactor
                                font.bold: true
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                color: app.primaryColor
                            }

                            onClicked:{
                                isInRouteMode = true
                                openElevationProfile();
                            }
                        }

                        RoundButton {
                            id: elevationButtonIcon

                            radius: 20 * app.scaleFactor
                            padding: 1 * app.scaleFactor
                            anchors.centerIn: parent

                            Material.foreground: "white"
                            Material.background: app.primaryColor
                            Material.elevation: 1

                            icon.source: "../../MapViewer/images/Elevation_icon.png"
                            icon.height: 24 * app.scaleFactor
                            icon.width: icon.width

                            visible: detailButtonIcon.visible || ( elevationButtonText.implicitWidth > 156 * app.scaleFactor )

                            onClicked:{
                                isInRouteMode = true

                                openElevationProfile();
                            }
                        }
                    }

                    Item {
                        id: detailBtnContainer
                        Layout.preferredWidth: detailButtonText.visible ? detailButtonText.width : detailButtonIcon.width
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignRight
                        z:100


                        RoundButton {
                            id: detailButtonText

                            width: implicitWidth
                            height: 40 * app.scaleFactor
                            radius: 20 * app.scaleFactor
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            padding: 16 * app.scaleFactor

                            text: strings.details
                            Material.foreground: "white"
                            Material.background: app.primaryColor
                            Material.elevation: 1

                            contentItem: Text {
                                text: detailButtonText.text
                                font.pixelSize: 12 * app.scaleFactor
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                color: "white"
                            }

                            visible: !detailButtonIcon.visible

                            onClicked :{
                                openDetail();
                            }
                        }

                        RoundButton {
                            id: detailButtonIcon

                            radius: 20 * app.scaleFactor
                            padding: 1 * app.scaleFactor
                            anchors.centerIn: parent

                            Material.foreground: "white"
                            Material.background: app.primaryColor
                            Material.elevation: 1

                            icon.source: "../../MapViewer/images/Detail_icon.png"
                            icon.height: 24 * app.scaleFactor
                            icon.width: icon.width

                            visible: ( detailButtonText.width + ( elevationButtonContainer.visible ? elevationButtonText.width : distanceRow.implicitWidth ) + 4 * app.baseUnit ) > carouselDelegate.width
                                     || ( detailButtonText.implicitWidth > 156 * app.scaleFactor )

                            onClicked :{
                                openDetail();
                            }
                        }
                    }
                }
            }

            Item {
                Layout.preferredHeight: 12 * app.scaleFactor
                Layout.fillWidth: true
            }

            Item {
                Layout.preferredHeight: 28 * app.scaleFactor
                Layout.fillWidth: true

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Item {
                        id: damageBtnContainer
                        Layout.preferredWidth: damageButtonText.visible ? damageButtonText.width : damageButtonIcon.width
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignRight
                        z:100


                        RoundButton {
                            id: damageButtonText

                            width: implicitWidth
                            height: 40 * app.scaleFactor
                            radius: 20 * app.scaleFactor
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            padding: 16 * app.scaleFactor

                            text: "Report Damage"
                            Material.foreground: "white"
                            Material.background: app.primaryColor
                            Material.elevation: 1

                            contentItem: Text {
                                text: damageButtonText.text
                                font.pixelSize: 12 * app.scaleFactor
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                color: "white"
                            }

                            visible: !damageButtonIcon.visible

                            onClicked :{
                                openDamage();
                            }
                        }

                        RoundButton {
                            id: damageButtonIcon

                            radius: 20 * app.scaleFactor
                            padding: 1 * app.scaleFactor
                            anchors.centerIn: parent

                            Material.foreground: "white"
                            Material.background: app.primaryColor
                            Material.elevation: 1

                            icon.source: "../../MapViewer/images/Detail_icon.png"
                            icon.height: 24 * app.scaleFactor
                            icon.width: icon.width

                            visible: false

//                            visible: ( damageButtonText.width + ( citSciButtonContainer.visible ? citSciButtonText.width : citSciButtonIcon.width ) + 4 * app.baseUnit ) > carouselDelegate.width
//                                     || ( damageButtonText.implicitWidth > 156 * app.scaleFactor )

                            onClicked :{
                                openDamage();
                            }
                        }
                    }
                    Item {
                        id: citSciBtnContainer
                        Layout.preferredWidth: citSciButtonText.visible ? citSciButtonText.width : citSciButtonIcon.width
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignRight
                        z:100


                        RoundButton {
                            id: citSciButtonText

                            width: implicitWidth
                            height: 40 * app.scaleFactor
                            radius: 20 * app.scaleFactor
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            padding: 16 * app.scaleFactor

                            text: "Wildlife Sightings"
                            Material.foreground: "white"
                            Material.background: app.primaryColor
                            Material.elevation: 1

                            contentItem: Text {
                                text: citSciButtonText.text
                                font.pixelSize: 12 * app.scaleFactor
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                color: "white"
                            }

                            visible: !citSciButtonIcon.visible

                            onClicked :{
                                openCitSci();
                            }
                        }

                        RoundButton {
                            id: citSciButtonIcon

                            radius: 20 * app.scaleFactor
                            padding: 1 * app.scaleFactor
                            anchors.centerIn: parent

                            Material.foreground: "white"
                            Material.background: app.primaryColor
                            Material.elevation: 1

                            icon.source: "../../MapViewer/images/Detail_icon.png"
                            icon.height: 24 * app.scaleFactor
                            icon.width: icon.width

                            visible: false

//                            visible: ( citSciButtonText.width + ( damageButtonContainer.visible ? damageButtonText.width : damageButtonIcon.width ) + 4 * app.baseUnit ) > carouselDelegate.width
//                                     || ( citSciButtonText.implicitWidth > 156 * app.scaleFactor )

                            onClicked :{
                                openCitSci();
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: parent.height
            anchors.bottom: attachmentCards.bottom
            radius: 10 * app.scaleFactor
            color: "transparent"
            border.color: "#70D5D5D5"
            border.width: app.scaleFactor
        }
    }
}
