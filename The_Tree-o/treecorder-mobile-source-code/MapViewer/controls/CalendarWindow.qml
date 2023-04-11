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
import QtQuick.Controls 2.2
import QtQuick.Controls.Private 1.0
import QtQuick.Layouts 1.3
import QtQuick.Extras 1.4

import ArcGIS.AppFramework 1.0

import QtQuick.Controls 2.1 as NewControls
import QtQuick.Controls.Material 2.1 as MaterialStyle
import "../widgets"

NewControls.Dialog {
    id: calendarAndTimeDialog
    width: app.width*0.8
    height: Math.min(app.height * 0.8, 400)
    x: (app.width - width) / 2 - parent.x
    y: (app.height - height) / 2 - parent.y
    visible: false
    padding: 0
    topPadding: 0
    bottomPadding: 0

    property int theme: MaterialStyle.Material.Light

    MaterialStyle.Material.theme: theme
    modal: true
    closePolicy: NewControls.Dialog.NoAutoClose
    MaterialStyle.Material.accent: MaterialStyle.Material.theme === MaterialStyle.Material.Dark? "#E0E0E0" : primaryColor

    property bool isMiniMode: calendarAndTimeDialog.height < 399

    // Initializing with new Date() causes bugs in apString in the XTimePicker module due to the currentIndexChanged getting reset

    property var selectedDateAndTime: getInitialDateAndTime()
    property real dateMilliseconds: selectedTime ? selectedDateAndTime.valueOf() : 0

    property color primaryColor: "#009688"
   // property var minimumDate :null//new Date(2017, 0, 1)
    //property var maximumDate:null //new Date(2020, 0, 1)

    property alias swipeViewIndex: swipeView.currentIndex

    spacing: 0

    header: Rectangle {
        width: parent.width
        height: calendarAndTimeDialog.height / 6
        color: MaterialStyle.Material.theme === MaterialStyle.Material.Dark? Qt.lighter(app.backgroundColor, 1.2) : primaryColor
        clip: true

        RowLayout{
            anchors.fill: parent
            anchors.margins: 8 * AppFramework.displayScaleFactor
            Item{
                Layout.preferredWidth: parent.width / 5 * 3
                Layout.fillHeight: true
                ColumnLayout {
                    anchors.fill: parent
                    opacity: swipeView.currentIndex == 0 ? 1 : 0.7
                    clip: true
                    spacing: 0

                    NewControls.Label {
                        Layout.preferredHeight: parent.height / 2.5
                        Layout.fillWidth: true

                        text: calendar.selectedDate.toLocaleDateString(calendar.__locale, "yyyy")
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                        color: "white"
                        padding: 0
                    }

                    NewControls.Label {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        fontSizeMode: Label.Fit
                        text:calendar.selectedDate.toLocaleDateString(calendar.__locale, "ddd, MMM d")
                        verticalAlignment: Text.AlignVCenter
                        padding: 0
                        font {
                            bold: true
                        }
                        color: "white"
                    }
                }

                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                        if(swipeView.currentIndex === 1) swipeView.decrementCurrentIndex();
                    }
                }
            }

            Item{
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout{
                    anchors.fill: parent
                    opacity: swipeView.currentIndex === 1 ? 1 : 0.7
                    clip: true
                    spacing: 0
                    NewControls.Label {
                        Layout.preferredHeight: parent.height / 2.5
                        Layout.fillWidth: true

                        text: timePicker.apString
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        color: "white"
                        padding: 0
                    }

                    NewControls.Label {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        fontSizeMode: Label.Fit
                        text: timePicker.hourString + ":" + timePicker.minString
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        padding: 0
                        font {
                            bold: true
                        }

                        color: "white"
                    }
                }

                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                        if(swipeView.currentIndex==0) swipeView.incrementCurrentIndex();
                    }
                }
            }
        }

    }

    ColumnLayout {
        anchors.fill: parent
        NewControls.SwipeView{
            id: swipeView

            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: 0
            padding: 0
            clip: true
            spacing: 0

            XCalendar{
                id: calendar
                isMiniMode: calendarAndTimeDialog.isMiniMode
                selectedDate: calendarAndTimeDialog.selectedDateAndTime
                primaryColor: calendarAndTimeDialog.primaryColor
                //minimumDate: calendarAndTimeDialog.minimumDate
                //maximumDate:calendarAndTimeDialog.maximumDate
                onSelectedDateChanged: {
                    calendarAndTimeDialog.selectedDateAndTime.setFullYear(selectedDate.getFullYear());
                    calendarAndTimeDialog.selectedDateAndTime.setDate(selectedDate.getDate());
                    calendarAndTimeDialog.selectedDateAndTime.setMonth(selectedDate.getMonth());
                    dateMilliseconds = selectedDateAndTime.valueOf();
                }
            }

            XTimePicker {
                id: timePicker
                selectedTime: calendarAndTimeDialog.selectedDateAndTime
                primaryColor: calendarAndTimeDialog.primaryColor
                onTimeChanged: {
                    if ( selectedTime ) {
                        calendarAndTimeDialog.selectedDateAndTime.setHours(selectedTime.getHours());
                        calendarAndTimeDialog.selectedDateAndTime.setMinutes(selectedTime.getMinutes());
                        dateMilliseconds = selectedDateAndTime.valueOf();
                    }
                }
            }
        }

        NewControls.PageIndicator {
            id: indicator

            count: swipeView.count
            currentIndex: swipeView.currentIndex
            scale: calendarAndTimeDialog.isMiniMode? 0.5 : 1
            Layout.alignment: Qt.AlignHCenter
        }
    }

    footer: Rectangle {
        id: item
        width: parent.width
        height: parent.height / 8
        color: "transparent"
        clip: true
        anchors.bottom: parent.Bottom
        radius: 5 * AppFramework.displayScaleFactor

        RowLayout {
            id: footerRow
            anchors.fill: parent

            CustomDialogButton {
                id: todayButton
                primaryColor: calendarAndTimeDialog.primaryColor
                parentHeight: parent.height

                Layout.preferredHeight: parent.height
                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: 10 * AppFramework.displayScaleFactor
                visible: swipeView.currentIndex === 0
                customText: strings.today_string
                onClicked: {
                    calendar.selectedDate = new Date();
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
            }

            CustomDialogButton {
                id: cancelButton
                parentHeight: parent.height
                Layout.preferredHeight: parent.height
                primaryColor: calendarAndTimeDialog.primaryColor
                customText: strings.cancel_string
                onClicked: {
                    calendarAndTimeDialog.reject();
                }
            }

            CustomDialogButton {
                id: okayButton
                parentHeight: parent.height
                Layout.preferredHeight: parent.height
                Layout.alignment: Qt.AlignRight
                Layout.rightMargin: 10 * AppFramework.displayScaleFactor
                primaryColor: calendarAndTimeDialog.primaryColor
                customText: strings.ok_String
                onClicked: {
                if(calendar.selectedDate > calendar.minimumDate && calendar.selectedDate  < calendar.maximumDate)
                    calendarAndTimeDialog.accept();
                }
            }
        }
    }

    function setMinimumDate(minDate){
        if(minDate > "")
        {

            calendar.minimumDate = minDate//new Date(2017, 0, 1)//minDate
        }
    }

    function setMaximumDate(maxDate){
        if(maxDate > "")
        {
           calendar.maximumDate = maxDate//new Date(2023, 0, 1)//maxDate
        }
    }


    function updateDateAndTime(){
        calendar.selectedDate = selectedDateAndTime;
        timePicker.selectedTime = selectedDateAndTime;
    }

    function getInitialDateAndTime() {
        let initialDateAndTime = new Date();
        if ( initialDateAndTime.getHours() >= 12 ) {
            initialDateAndTime.setHours(initialDateAndTime.getHours() - 12);
        }
        return initialDateAndTime;
    }
}
