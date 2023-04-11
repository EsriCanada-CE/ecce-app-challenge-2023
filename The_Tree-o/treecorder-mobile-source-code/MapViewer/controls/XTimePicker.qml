/*
* This file contains the UI and controller for the time-picker component which is used to select/ modify time.
* This UI component is mainly used in modifying time in Attribute Editing (If available)
*/
import QtQuick 2.7
import QtQuick.Controls 2.2

import QtQuick.Controls.Private 1.0
import QtQuick.Layouts 1.3
import QtQuick.Extras 1.4
import QtQuick.Controls 2.1 as NewControls
import QtQuick.Controls.Material 2.1 as MaterialStyle

import ArcGIS.AppFramework 1.0


Item {
    property var selectedTime: { return new Date() }
    property var apString: selectedTime ?
                               ( is24HoursFormat ?
                                    strings.hrs :
                                    ( selectedTime.getHours() < 12 ? Qt.locale().amText : Qt.locale().pmText )) : ""

    property var minString: selectedTime ? selectedTime.getMinutes() < 10 ? ("0" + selectedTime.getMinutes()) : selectedTime.getMinutes() : ""
    property var hourString: selectedTime ?
                                 selectedTime.getHours() === 0 ? 12 :
                                                                 ( !is24HoursFormat && selectedTime.getHours() > 12 ? (selectedTime.getHours() - 12) : selectedTime.getHours()) : ""
    property bool initial: true
    property bool updating: false

    property color primaryColor: "#009688"

    signal timeChanged(var selectedTime)

    /*
    * @desc => Update the selectedTime and time strings (displayed at the top) to reflect user selection on the time-picker dialog
    */
    function updateTime(){
        apString = apColumn.model[apColumn.currentIndex];
        let formattedSelectedTime = selectedTime ?
                is24HoursFormat ?
                    selectedTime.toLocaleTimeString(Qt.locale(), "h:mm")  :
                    selectedTime.toLocaleTimeString(Qt.locale(), "h:mm ap") : "";
        minString = formattedSelectedTime.split(":")[1].split(" ")[0]
        hourString = formattedSelectedTime.split(":")[0]
        timeChanged(selectedTime);
    }

    RowLayout{
        anchors.fill: parent
        anchors.margins: 8 * AppFramework.displayScaleFactor
        spacing: 0
        LayoutMirroring.enabled: app.isRightToLeft
        LayoutMirroring.childrenInherit: app.isRightToLeft

        NewControls.Tumbler{
            id: hoursColumn
            Layout.preferredWidth: parent.width / 3
            Layout.fillHeight: true
            wrap: true
            model: is24HoursFormat ?
                       new Array(24).join().split(',').map((item, index) => { return Number(index).toLocaleString(Qt.locale(),"f",0) }) :
                       [12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11].map((item, index) => { return Number(item).toLocaleString(Qt.locale(), "f", 0) })
            delegate: tumblerDelegateComponent
            spacing: 0
            MaterialStyle.Material.accent: primaryColor
            currentIndex: is24HoursFormat ? selectedTime.getHours() : selectedTime.getHours() % 12
            onCurrentIndexChanged: {
                let selectedHours = hoursColumn.currentIndex;
                if(!is24HoursFormat && apColumn.currentIndex === 1) selectedHours += 12;
                selectedTime.setHours(selectedHours);
                updateTime();
            }
        }

        NewControls.Tumbler{
            id: minutesColumn
            Layout.preferredWidth: parent.width / 3
            Layout.fillHeight: true
            wrap: true
            visibleItemCount: 10
            model: new Array(60).join().split(',').map((item, index) => {
                return Number(index).toLocaleString(Qt.locale(),"f",0)
            })
            delegate: tumblerDelegateComponent
            spacing: 0
            MaterialStyle.Material.accent: primaryColor
            currentIndex: selectedTime ? selectedTime.getMinutes() : 0
            onCurrentIndexChanged: {
                if ( selectedTime ){
                    selectedTime.setMinutes(currentIndex);
                    updateTime();
                }
            }
        }

         NewControls.Tumbler{
            id: apColumn
            Layout.preferredWidth: parent.width / 3
            Layout.fillHeight: true
            wrap: false
            model: is24HoursFormat ? [strings.hrs] : [Qt.locale().amText, Qt.locale().pmText]
            delegate: tumblerDelegateComponent
            spacing: 0
            MaterialStyle.Material.accent: primaryColor
            currentIndex: selectedTime ?
                              ( !is24HoursFormat && selectedTime.getHours() >= 12 ? 1 : 0 ) :  0
            onCurrentIndexChanged: {
                if ( !is24HoursFormat ){
                    if(currentIndex === 0){
                        if( selectedTime && selectedTime.getHours() >= 12) selectedTime.setHours(selectedTime.getHours() - 12);
                    } else {
                        if( selectedTime && selectedTime.getHours() < 12) selectedTime.setHours(selectedTime.getHours() + 12);
                    }
                }
                updateTime();
            }
        }
    }

    Component {
        id: tumblerDelegateComponent

        Text {
            text: modelData
            color: MaterialStyle.Material.theme === MaterialStyle.Material.Dark ? "#ededed":"#000"
            font.bold: true
            font.pixelSize: (modelData === "AM" && Tumbler.tumbler.currentIndex === 0) || (modelData === "PM" && Tumbler.tumbler.currentIndex === 1)
                            || (parseInt(modelData) === Tumbler.tumbler.currentIndex) ? 15 * AppFramework.displayScaleFactor :  (12 * AppFramework.displayScaleFactor) - Math.abs(Tumbler.displacement) / (Tumbler.tumbler.visibleItemCount / 3)
            opacity: 1.0 - Math.abs(Tumbler.displacement) / (Tumbler.tumbler.visibleItemCount / 2)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
