import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15

import ArcGIS.AppFramework 1.0


import QtGraphicalEffects 1.0

ToolButton {
    anchors.centerIn: parent

    property url imageSource: ""

    property bool isMirrored: false

    property real imageWidth: 24 * app.scaleFactor

    property alias imageColor: colorOverlay.color
    property alias imageRotation: buttonImage.rotation

    indicator: Image {
        id: buttonImage

        width: imageWidth
        height: width
        anchors.centerIn: parent
        source: imageSource
        fillMode: Image.PreserveAspectFit
        mirror: isMirrored
        mipmap: true
    }

    ColorOverlay {
        id: colorOverlay

        anchors.fill: buttonImage
        source: buttonImage
        rotation: buttonImage.rotation
    }
}
