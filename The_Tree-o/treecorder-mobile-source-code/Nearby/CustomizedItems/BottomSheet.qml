import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15

import ArcGIS.AppFramework 1.0


Rectangle {
    id: root

    width: app.width
    height: app.height
    x: 0
    y: 0
    color: "#61000000"
    visible: false

    property int interval: 250

    signal clicked()

    MouseArea {
        anchors.fill: parent

        onClicked: {
            root.clicked();
        }
    }

    Timer {
        id: timer

        interval: root.interval

        onTriggered: root.visible = false;
    }

    function open() {
        root.visible = true;
    }

    function close() {
        timer.start();
    }
}
