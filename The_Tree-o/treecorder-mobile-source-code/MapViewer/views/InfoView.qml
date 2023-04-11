import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1

import "../controls" as Controls

Flickable {
    id: infoView

    property string titleText
    property string ownerText
    property string modifiedDateText

    property string snippetText
    property string descriptionText
    property string customDesc
    property real minContentHeight: 0
    property string welcomeText: ""
    property string appDescriptionText:"Find nearby points of interest.</br><ul><li>by tapping on the map, </li><li>by using an address or place search, </li><li>or using your current location.</li>"//strings.appdescriptionText

    clip: true
    contentHeight: content.height + 16 * scaleFactor

    ColumnLayout {
        id: content

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: app.defaultMargin
        }
        spacing: app.baseUnit

        Controls.BaseText {
            id: itemTitle

            text: titleText
            visible: titleText > ""
            Layout.alignment: Qt.AlignTop
            horizontalAlignment: Qt.AlignLeft
            Layout.fillHeight: false
            Layout.preferredHeight: itemTitle.contentHeight
            Layout.fillWidth: true
            font.bold:true
            color:"black"
            font.weight:Font.Black
        }

        Controls.BaseText {
            id: itemOwner
            visible: ownerText > ""
            text: "Owner: "+ ownerText
            Layout.alignment: Qt.AlignTop
            horizontalAlignment: Qt.AlignLeft
            Layout.fillHeight: false
            Layout.preferredHeight: itemOwner.contentHeight
            Layout.fillWidth: true
            font.weight: Font.Bold
        }

        Controls.BaseText {
            id: itemModifiedDate
            visible:modifiedDateText > ""

            text: "Modified Date: "+ modifiedDateText
            Layout.alignment: Qt.AlignTop
            horizontalAlignment: Qt.AlignLeft
            Layout.fillHeight: false
            Layout.preferredHeight: itemModifiedDate.contentHeight
            Layout.fillWidth: true
            font.weight: Font.Bold
        }

        Controls.BaseText {
            id: itemWelcomeText

            visible: welcomeText > ""
            text: infoView.welcomeText
            Layout.alignment: Qt.AlignTop
            horizontalAlignment: Qt.AlignLeft
            Layout.fillHeight: false
            Layout.preferredHeight: itemWelcomeText.contentHeight
            Layout.fillWidth: true
            font.bold:true
            color:"black"
            font.weight:Font.Black
            onLinkActivated: {
                mapViewerCore.openUrlInternally(link)
            }
        }

        Rectangle{
            id: item
            Layout.preferredHeight:text1.height
            visible:customDesc > ""
            Layout.preferredWidth: parent.width

            Text {
                id: text1
                text: customDesc !== undefined ? customDesc : ""
                anchors.left: parent.left
                anchors.right: parent.right
                leftPadding: app.units(8)
                horizontalAlignment: app.isRightToLeft ? Qt.AlignRight : Qt.AlignLeft
                wrapMode: Text.WordWrap
                textFormat: Text.RichText
                visible:customDesc > ""
                onLinkActivated: mapViewerCore.openUrlInternally(link)
            }
        }

        Text {
            id: appDescription
            text: appDescriptionText
            Layout.alignment: Qt.AlignTop
            horizontalAlignment: Qt.AlignLeft
            Layout.fillHeight: false
            Layout.preferredHeight: appDescription.contentHeight
            Layout.fillWidth: true
            color:"black"
            font.weight:Font.Black
            textFormat: Text.RichText
        }
    }
}
