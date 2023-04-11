import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0




RoundButton {
    id: roundBtn

    property real textSize: fonts.bodyAccent.textSize
    property string textFontFamily: fonts.bodyAccent.textFontFamily
    property color textColor: colors.blk_000//app.isDarkMode || app.brandColorMode === "light"?colors.blk_200:colors.blk_000
    property color gradientStartColor: colors.gradient_start
    property color gradientEndColor: colors.gradient_end
    property url iconImage: ""

    property real contentWidth: contentLayout.width

    contentItem: Item {
        RowLayout {
            id: contentLayout

            height: roundBtn.height
            anchors.centerIn: parent
            spacing:0

            Item
            {
                id:imagePlayBtn
                Layout.preferredWidth: playBtn.visible ? 28 * app.scaleFactor:0
                Layout.preferredHeight: 28 * scaleFactor

            Image {
                id:playBtn
                anchors.fill:parent
                source: roundBtn.iconImage
                visible: source > ""
            }
            ColorOverlay{
                anchors.fill: playBtn
                source:playBtn
                color:textColor

                visible:source > ""

            }
            }
            Item{
               Layout.preferredWidth:playBtn.visible?8 * scaleFactor:0
               Layout.preferredHeight: 28 * scaleFactor
            }
            Label {

                text: roundBtn.text
                padding: 0
                elide: Text.ElideRight
                font.bold: true
                font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                font.pixelSize: textSize
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                color: "white"
            }


        }
    }

    background: LinearGradient {
        id: btnBackground

        opacity: roundBtn.enabled ? 1.0 : 0.3

        anchors.fill: parent
        start: Qt.point(0, 0)
        end: Qt.point(width, 0)
        source: Rectangle {
            width: btnBackground.width
            height: btnBackground.height
            radius: btnBackground.height/2
            clip: true
            border.width:0
        }
        gradient: Gradient {
            GradientStop { position: 0.0; color: gradientStartColor }
            GradientStop { position: 1.0; color: gradientEndColor }
        }
    }
}

