import QtQuick 2.9
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.3

import ArcGIS.AppFramework 1.0
import "../../MapViewer/controls" as Controls
import "../../MapViewer/widgets" as Widgets
Drawer {
    id: listPagePopup

    property bool isInteractive: true
    property bool groupResultsByLayer: false
    property var layers: []

    property int count: featureResultsListModel.count
    property ListModel featureResultsListModel: featureResults
    property ListModel unsortedFeatureResultsListModel: unsortedFeatureResults
    signal clicked(int index)

    modal: true

    height: parent.height
    width: parent.width
    transformOrigin: Popup.Right
    edge: app.isRightToLeft ? Qt.LeftEdge : Qt.RightEdge
    focus: isInteractive
    interactive: mapView.featuresModel.count > 0 || mapView.layerResults.length > 0

    topMargin: ( parent.height > app.height ) ? ( app.heightOffset + ( app.isIphoneX ? app.defaultMargin + 4 * app.scaleFactor : 0 ) ) : 0
    bottomPadding: app.isIphoneX ? 2 * app.defaultMargin : 0

    Material.background: "#F4F4F4"

    ListModel {
        id: featureResults
    }

    //Listmodel that store the layer basic info
    ListModel {
        id: layerResults
    }

    ListModel {
        id: unsortedFeatureResults
    }

    Page {
        id: multiLayerResultsPage

        width: parent.width
        height: parent.height
        Material.background: "#F4F4F4"

        LayoutMirroring.enabled: app.isRightToLeft
        LayoutMirroring.childrenInherit: app.isRightToLeft

        header: ToolBar {
            id: mapPageHeader
            height: app.headerHeight + app.notchHeight

            width: parent.width
            Material.background: app.primaryColor
            Material.elevation: 2

            RowLayout {
                anchors {
                    fill: parent
                    rightMargin: app.isLandscape ? app.widthOffset: 0
                    leftMargin: app.isLandscape ? app.widthOffset: 0
                    topMargin: app.notchHeight
                }
                spacing: 0


                Controls.Icon {
                    id: backIcon

                    iconSize: 6 * app.baseUnit

                    imageSource: "../../MapViewer/images/back.png"

                    rotation: app.isRightToLeft ? 180 : 0

                    onClicked: {
                        listPagePopup.close()
                    }
                }

                Item{
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                }
            }
        }

        ColumnLayout {
            height: parent.height
            width: Math.min(parent.width, app.maximumScreenWidth)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 0

            Item {
                Layout.preferredHeight: app.defaultMargin
                Layout.fillWidth: true
            }

            Item {
                Layout.preferredHeight: 14 * app.scaleFactor
                Layout.fillWidth: true

                Controls.BaseText {
                    id: totalText

                    elide: Text.ElideRight
                    height: parent.height
                    width: parent.width
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    text: ("%1: %L2").arg(strings.total).arg(unsortedFeatureResultsListModel.count)
                    fontsize: 12 * app.scaleFactor
                    color: "#6A6A6A"
                    leftPadding: app.defaultMargin
                    rightPadding: app.defaultMargin
                }
            }


            Item {
                Layout.preferredHeight:  app.defaultMargin
                Layout.fillWidth: true
            }

            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true

                ListView {
                    id: resultsSortByLayerList

                    visible: groupResultsByLayer
                    anchors.fill: parent
                    model: layerResults
                    spacing: 2 * app.baseUnit
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    footer: Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 2 * app.defaultMargin
                    }

                    delegate: Rectangle {
                        width: Math.min(resultsSortByLayerList.width, app.maximumScreenWidth)
                        height: layerResultsColumn.height

                        ColumnLayout {
                            id: layerResultsColumn
                            width: parent.width
                            spacing: 0

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: layerResultColumn.height

                                ColumnLayout {
                                    id: layerResultColumn
                                    height: layerNameText.height + 36 * app.scaleFactor
                                    width: parent.width
                                    spacing: 0

                                    Item {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: app.scaleFactor

                                        Rectangle {
                                            anchors.fill: parent
                                            color: colors.blk_020
                                        }
                                    }

                                    Item {
                                        Layout.preferredHeight:  app.baseUnit
                                        Layout.fillWidth: true
                                    }

                                    Item {
                                        Layout.fillHeight: true
                                        Layout.fillWidth: true

                                        RowLayout {
                                            anchors.fill: parent
                                            spacing: 0

                                            Label {
                                                id: layerNameText
                                                elide: Text.ElideMiddle
                                                maximumLineCount: 3
                                                Layout.preferredWidth: Math.min(implicitWidth, parent.width - 40 * scaleFactor - layerCount.width)
                                                Layout.alignment: Qt.AlignVCenter
                                                horizontalAlignment: Text.AlignLeft
                                                verticalAlignment: Text.AlignVCenter
                                                text: layerName
                                                font.pixelSize: 14 * app.scaleFactor
                                                font.bold: true
                                                font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                                                color: colors.blk_200
                                                wrapMode: Text.WordWrap
                                                leftPadding: app.defaultMargin
                                                rightPadding: app.baseUnit
                                            }

                                            Label {
                                                id: layerCount
                                                Layout.preferredWidth: implicitWidth
                                                Layout.alignment: Qt.AlignVCenter
                                                horizontalAlignment: Text.AlignLeft
                                                verticalAlignment: Text.AlignVCenter
                                                text: "(%L1)".arg(count)
                                                font.pixelSize: 14 * app.scaleFactor
                                                font.bold: true
                                                font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                                                color: colors.blk_200
                                                rightPadding: app.defaultMargin
                                                wrapMode: Text.WrapAnywhere
                                            }

                                            Item {
                                                Layout.fillHeight: true
                                                Layout.fillWidth: true
                                            }

                                            Item {
                                                Layout.preferredHeight: 24 * scaleFactor
                                                Layout.preferredWidth: 24 * scaleFactor
                                                Layout.alignment: Qt.AlignVCenter

                                                Widgets.Icon {
                                                    anchors.fill: parent

                                                    source: "../../MapViewer/images/baseline_expand_less_white_48dp.png"
                                                    indicatorColor: colors.blk_200
                                                    rotation: nameRepeater.isOpen ? 0 : 180
                                                }
                                            }

                                            Item {
                                                Layout.fillHeight: true
                                                Layout.preferredWidth: 16 * app.scaleFactor
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                nameRepeater.isOpen = !nameRepeater.isOpen
                                            }
                                        }

                                    }

                                    Item {
                                        Layout.preferredHeight:  app.baseUnit
                                        Layout.fillWidth: true
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: app.scaleFactor

                                        Rectangle {
                                            anchors.fill: parent
                                            color: colors.blk_020
                                        }
                                    }
                                }
                            }

                            Repeater {
                                id:nameRepeater

                                model: layers[index] //Get the single listmodel for the current layer from the listmodel array

                                property bool isOpen: true
                                property int currentIndex: index
                                delegate:Item {
                                    id: featureResultsName

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: featureName.height

                                    Behavior on Layout.preferredHeight {
                                        NumberAnimation { duration: 0.5 * app.normalDuration }
                                    }

                                    ColumnLayout {
                                        id: featureName
                                        width: parent.width
                                        spacing: 0

                                        Item {
                                            Layout.preferredHeight:  app.baseUnit
                                            Layout.fillWidth: true

                                            visible: nameRepeater.isOpen
                                        }

                                        RowLayout {
                                            Layout.preferredHeight: nameRepeater.isOpen ? featureNameText.implicitHeight: 0
                                            Layout.fillWidth: true
                                            spacing: 0

                                            Label {
                                                id: featureNameText

                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: nameRepeater.isOpen ? implicitHeight: 0
                                                Layout.alignment: Qt.AlignVCenter
                                                horizontalAlignment: Text.AlignLeft
                                                verticalAlignment: Text.AlignVCenter
                                                text: search_attr.trim() > ""? (isHTML(search_attr.trim()) ?convertHTMLtoPlainText (search_attr.trim()) : search_attr.trim() ): layerName.trim()
                                                font.pixelSize: 14 * app.scaleFactor
                                                font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                                                color: colors.blk_200
                                                lineHeight: 18 * app.scaleFactor
                                                lineHeightMode: Text.FixedHeight
                                                wrapMode: Text.WrapAnywhere
                                                maximumLineCount: 2
                                                leftPadding: app.defaultMargin
                                                rightPadding: app.defaultMargin
                                                topPadding: app.baseUnit
                                                bottomPadding: app.baseUnit
                                                textFormat: isHTML(text) && nameRepeater.isOpen? Text.RichText:Text.PlainText

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

                                            Label {
                                                id: distanceText

                                                visible: mapView.includeDistance

                                                Layout.preferredWidth: 56 * app.scaleFactor
                                                Layout.fillHeight: true
                                                clip: true
                                                elide: Label.ElideRight
                                                wrapMode: Text.Wrap
                                                font.pixelSize: 12 * app.scaleFactor
                                                verticalAlignment: Text.AlignVCenter
                                                horizontalAlignment: Text.AlignRight

                                                color:  colors.blk_140
                                                text: mapView.includeDistance ? "%1 %2".arg(distance).arg(mapView.measureUnitsString) :""
                                                //text: mapView.includeDistance ? "%1 %2".arg(parseFloat(distance).toLocaleString(Qt.locale())).arg(mapView.measureUnitsString) :""
                                            }

                                            Item {
                                                visible: mapView.includeDistance

                                                Layout.preferredWidth: app.defaultMargin
                                                Layout.fillHeight: true
                                            }
                                        }

                                        Item {
                                            Layout.preferredHeight:  app.baseUnit
                                            Layout.fillWidth: true

                                            visible: nameRepeater.isOpen
                                        }

                                        Item {
                                            Layout.preferredHeight:  nameRepeater.isOpen? app.scaleFactor : 0
                                            Layout.fillWidth: true

                                            visible: nameRepeater.isOpen

                                            Rectangle {
                                                anchors.fill: parent
                                                anchors.leftMargin: (index === layers[nameRepeater.currentIndex].count - 1) ? 0 : app.defaultMargin
                                                color: colors.blk_020
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            let currentFeatureNumber = index + ( nameRepeater.currentIndex > 0 ? layerResults.get(nameRepeater.currentIndex - 1).totalFeaturesCount : 0 )
                                            listPagePopup.clicked(initialIndex);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {

                    anchors.fill: parent
                    spacing: 0
                    visible: !groupResultsByLayer

                    Item {
                        Layout.preferredHeight: app.scaleFactor
                        Layout.preferredWidth: Math.min(unsortedResultsList.width, app.maximumScreenWidth)

                        Rectangle {
                            anchors.fill: parent
                            color: colors.blk_020
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                        Layout.fillWidth: true

                        ListView {
                            id: unsortedResultsList
                            anchors.fill: parent
                            model: unsortedFeatureResultsListModel
                            boundsBehavior: Flickable.StopAtBounds
                            clip: true
                            footer: Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 2 * app.defaultMargin
                            }

                            delegate: Rectangle {
                                width: Math.min(unsortedResultsList.width, app.maximumScreenWidth)
                                height: unsortedResultsNameColumn.height

                                ColumnLayout {

                                    id: unsortedResultsNameColumn
                                    width: parent.width
                                    spacing: 0

                                    Item {
                                        Layout.preferredHeight:  app.baseUnit
                                        Layout.fillWidth: true
                                    }

                                    RowLayout {
                                        Layout.preferredHeight: unsortedFeatureNameText.implicitHeight
                                        Layout.fillWidth: true
                                        spacing: 0

                                        Label {
                                            id: unsortedFeatureNameText

                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: implicitHeight
                                            Layout.alignment: Qt.AlignVCenter
                                            horizontalAlignment: Text.AlignLeft
                                            verticalAlignment: Text.AlignVCenter
                                            text: search_attr.trim() > ""? (isHTML(search_attr.trim()) ?convertHTMLtoPlainText (search_attr.trim()) : search_attr.trim() ): layerName.trim()
                                            font.pixelSize: 14 * app.scaleFactor
                                            font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                                            color: colors.blk_200
                                            lineHeight: 18 * app.scaleFactor
                                            lineHeightMode: Text.FixedHeight
                                            wrapMode: Text.WrapAnywhere
                                            maximumLineCount: 2
                                            leftPadding: app.defaultMargin
                                            rightPadding: app.defaultMargin
                                            topPadding: app.baseUnit
                                            bottomPadding: app.baseUnit
                                            textFormat: Text.PlainText

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

                                        Label {
                                            visible: mapView.includeDistance

                                            Layout.preferredWidth: 56 * app.scaleFactor
                                            Layout.fillHeight: true
                                            clip: true
                                            elide: Label.ElideRight
                                            wrapMode: Text.Wrap
                                            font.pixelSize: 12 * app.scaleFactor
                                            verticalAlignment: Text.AlignVCenter
                                            horizontalAlignment: Text.AlignRight

                                            color:  colors.blk_140
                                            text: mapView.includeDistance ? "%1 %2".arg(distance).arg(mapView.measureUnitsString) :""
                                        }

                                        Item {
                                            visible: mapView.includeDistance

                                            Layout.preferredWidth: app.defaultMargin
                                            Layout.fillHeight: true
                                        }
                                    }

                                    Item {
                                        Layout.preferredHeight:  app.baseUnit
                                        Layout.fillWidth: true
                                    }

                                    Item {
                                        Layout.preferredHeight: app.scaleFactor
                                        Layout.fillWidth: true

                                        Rectangle {
                                            anchors.fill: parent
                                            anchors.leftMargin: (index === unsortedFeatureResultsListModel.count - 1) ? 0 : app.defaultMargin
                                            color: colors.blk_020
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        listPagePopup.clicked(initialIndex);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    //Move the layer info from layers array to layerResults model
    function bindModel(){
        let totalCount = 0;
        layerResults.clear();
        layers.forEach(layerTemp => {
                           totalCount += layerTemp.count;
                           layerResults.append({
                                                   "layerId": layerTemp.get(0).layerId,
                                                   "layerName": layerTemp.get(0).layerName,
                                                   "count": layerTemp.count,
                                                   "totalFeaturesCount": totalCount
                                               })
                       })
    }
}
