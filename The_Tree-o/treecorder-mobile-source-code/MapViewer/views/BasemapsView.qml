import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1

import "../controls" as Controls

GridView {
    id: basemapsView
    footer:Rectangle{
        height:isIphoneX?36 * scaleFactor :16 * scaleFactor
        width:basemapsView.width
        color:"transparent"
    }

    signal basemapSelected (int index)

    property real columns: app.isLarge ? 2 : 3

    cellWidth: width/columns
    cellHeight: cellWidth
    flow: GridView.FlowLeftToRight
    clip: true

    delegate: Pane {

        height: GridView.view.cellWidth
        width: GridView.view.cellHeight
        topPadding: app.defaultMargin
        bottomPadding: 0
        leftPadding: 0
        rightPadding: 0

        contentItem: Item{
            ColumnLayout {
                id:imagecol
                anchors.fill: parent
                spacing: 0

                Image {
                    id: thumbnailImg
                    source: thumbnailUrl > "" ? thumbnailUrl : "../../assets/default_basemap_image.png"
                    Layout.preferredHeight:0.60 * parent.height
                    Layout.preferredWidth: parent.width
                    Layout.bottomMargin: 0
                    fillMode: Image.PreserveAspectFit
                    BusyIndicator {
                        anchors.centerIn: parent
                        running: thumbnailImg.status === Image.Loading
                    }

                }

                Rectangle{
                    Layout.preferredWidth: parent.width
                    Layout.preferredHeight:imagecol.height - thumbnailImg.height
                    Layout.topMargin: app.units(16)

                    Controls.BaseText {
                        text: index === 0 ? qsTr("%1%2").arg(basemapsView.model.get(index).json.title).arg(strings.default_basemap) : basemapsView.model.get(index).json.title
                        maximumLineCount: 2
                        font.pointSize: app.textFontSize
                        color: app.subTitleTextColor
                        anchors.centerIn: parent
                        width:parent.width
                        height:parent.height
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    basemapSelected(index)
                }
            }
        }
    }
}
