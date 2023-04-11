import QtQuick 2.7
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.3
import QtGraphicalEffects 1.0
import QtQuick.Controls.Material 2.1

import Esri.ArcGISRuntime 100.14

import "../../MapViewer/controls" as Controls
import "../../MapViewer/widgets" as Widgets
import "../../assets"

Page {
    id: filtersView
    width: parent.width
    height: parent.height

    property ListModel filterListModel
    property var userConfiguredDefinitionExpr:({})
    property var filterDic
    property string rightButtonImage: "../../MapViewer/images/arrowDown.png"
    property var configuredFilters:[]
    property string fontNameFallbacks: "Helvetica,Avenir"


    property int radiusMax: 100
    property int radiusMin: 0
    property real currentRadius: 50
    property real defaultRadius: 50
    property string measureString: strings.km

    signal bufferDistanceChanged(var newDistance,var filterDic)
    signal filterConfigChanged(var filterDic,var hidePanelPage)
    signal reset()
    signal apply()


    function getFiltersCount(currentId){
        let _noOfFiltersApplied = 1
        for (var key in filterDic){
            for (var i =0 ; i < filterDic[key].count; i++){
                let exprId = filterDic[key].get(i).id

                if(configuredFilters.includes(exprId) && exprId !== currentId){

                    _noOfFiltersApplied += 1
                } else if(exprId in userConfiguredDefinitionExpr){
                    let userDefinitionExpr = userConfiguredDefinitionExpr[exprId]
                    if(userDefinitionExpr && exprId !== currentId){

                        _noOfFiltersApplied += 1
                    }
                }
            }
        }
        return _noOfFiltersApplied
    }

    ListView {
        id: filterConfigListView
        anchors.fill: parent
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: true
        contentHeight:filtersView.height
        spacing: 0
        clip: true
        model: filterListModel

        Component {
            id: textFieldIntValidatorComponent
            IntValidator {
                locale: Qt.locale().name
            }
        }

        Component {
            id: textFieldDoubleValidatorComponent
            DoubleValidator{
                locale: Qt.locale().name
            }
        }

        header: Item{
            width: parent.width
            height:isBufferSearchEnabled ? columnLayout.height:0

            ColumnLayout {
                id: columnLayout
                width: parent.width
                visible:isBufferSearchEnabled
                spacing: 0

                Item {
                    Layout.preferredHeight: 24 * app.scaleFactor
                    Layout.fillWidth: true
                }

                Item {
                    id:filterConfig
                    Layout.preferredHeight: 32 * app.scaleFactor
                    Layout.fillWidth: true
                    property var radiusValue:currentRadius

                    RowLayout {
                        anchors.fill: parent
                        spacing: 0

                        Label {
                            id: searchWithin

                            elide: Text.ElideRight
                            Layout.fillHeight: true
                            Layout.alignment: Qt.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                            text: "%1 (%2)".arg(strings.search_within).arg(measureString)
                            font.pixelSize: 18 * app.scaleFactor
                            font.bold: true
                            font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                            color: colors.blk_200
                            wrapMode: Text.WrapAnywhere
                            leftPadding: app.defaultMargin
                            rightPadding: app.defaultMargin
                        }

                        Item {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                        }

                        TextField {
                            id: radiusTextField

                            Layout.fillHeight: true
                            Layout.preferredWidth: 72 * app.scaleFactor
                            topPadding: 0
                            bottomPadding: 0
                            font.pixelSize: 14 * app.scaleFactor
                            font.bold: true
                            font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                            color: "black"
                            Material.accent: app.primaryColor
                            clip: true
                            selectByMouse: true
                            horizontalAlignment: TextField.AlignHCenter
                            verticalAlignment: TextField.AlignVCenter
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                            background: Rectangle {
                                anchors.fill: parent
                                color: "#EAEAEA"
                            }

                            Component.onCompleted: {
                                // Set default value of the selected buffer radius to the textfield when opened
                                if ( currentRadius < radiusMin ){
                                    radiusTextField.text = Number(radiusMin).toLocaleString(Qt.locale(), "f", mapView.bufferRadiusPrecision)
                                } else if ( currentRadius > radiusMax ){
                                    radiusTextField.text = Number(radiusMax).toLocaleString(Qt.locale(), "f", mapView.bufferRadiusPrecision)
                                } else {
                                    radiusTextField.text = Number(currentRadius).toLocaleString(Qt.locale(), "f", mapView.bufferRadiusPrecision)
                                }

                                if (visible) {
                                    if (focus) {
                                        forceActiveFocus();
                                        cursorPosition = text.length;
                                    }
                                }


                                // Add the corresponding validator to the radius text-field
                                if ( mapView.bufferRadiusPrecision > 0 ){
                                    radiusTextField.validator = textFieldDoubleValidatorComponent.createObject(parent, { bottom: radiusMin, decimals: mapView.bufferRadiusPrecision })
                                } else {
                                    radiusTextField.validator = textFieldIntValidatorComponent.createObject(parent, { bottom: radiusMin })
                                }
                            }

                            /* Signal is triggered when text-field is accepted (after validation), or loses focus -
                            *  Sets the valid value for currentRadius to be used as mapView.bufferDistance
                            *  IMPORTANT: This signal is emitted only when if the validator emits an acceptable state and input is non-empty
                            */
                            onEditingFinished: {
                                let currentInputRadius = parseFloat(Number.fromLocaleString(Qt.locale(),text))

                                if ( currentInputRadius > radiusMax ){
                                    radiusTextField.text = Number(radiusMax).toLocaleString(Qt.locale(), "f", mapView.bufferRadiusPrecision)
                                } else if ( currentInputRadius < radiusMin ){
                                    radiusTextField.text = Number(radiusMin).toLocaleString(Qt.locale(), "f", mapView.bufferRadiusPrecision)
                                }

                                currentRadius = parseFloat(radiusTextField.text).toFixed(mapView.bufferRadiusPrecision)
                            }

                            onTextChanged: {
                                let _txt = Number.fromLocaleString(Qt.locale(),text)

                                // If the change to buffer radius is made from textfield - reflect this change in slider -- This way it breaks the binding loop (1)
                                if ( radiusTextField.focus ){
                                    slider.value = parseFloat(_txt).toFixed(mapView.bufferRadiusPrecision);
                                }
                            }

                            onFocusChanged: {
                                if ( radiusTextField.text === "" ){
                                    slider.value = defaultRadius.toFixed(mapView.bufferRadiusPrecision);
                                    currentRadius = defaultRadius
                                    radiusTextField.text = Number(currentRadius).toLocaleString(Qt.locale(), "f", mapView.bufferRadiusPrecision)
                                }
                            }

                            Rectangle {
                                id: bottomBorder

                                width: parent.width
                                height: app.scaleFactor
                                color: app.primaryColor

                                anchors.bottom: parent.bottom
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                            Layout.preferredWidth: 16 * app.scaleFactor
                        }
                    }
                }


                Item {
                    Layout.preferredHeight:  24 * app.scaleFactor
                    Layout.fillWidth: true
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 16 * app.scaleFactor

                    Slider {
                        id: slider
                        anchors.fill: parent

                        LayoutMirroring.enabled: app.isRightToLeft
                        LayoutMirroring.childrenInherit: app.isRightToLeft

                        anchors.leftMargin: 16 * app.scaleFactor
                        anchors.rightMargin: 16 * app.scaleFactor

                        from: radiusMin
                        to: radiusMax

                        snapMode: Slider.NoSnap

                        background: Rectangle {
                            x: slider.leftPadding
                            y: slider.availableHeight / 2 - height / 2
                            implicitWidth: 200
                            implicitHeight: 4
                            width: slider.availableWidth
                            height: implicitHeight
                            radius: 2
                            color: app.isRightToLeft ? app.primaryColor : "#AAAAAA"

                            Rectangle {
                                width: slider.visualPosition * parent.width
                                height: parent.height
                                color: app.isRightToLeft ? "#AAAAAA" : app.primaryColor
                                radius: 2
                            }
                        }

                        handle: Rectangle {
                            id:sliderHandle

                            x: slider.visualPosition * (slider.availableWidth)
                            y: slider.availableHeight / 2 - height / 2
                            implicitWidth: 16 * app.scaleFactor
                            implicitHeight: 16 * app.scaleFactor
                            radius: 16 * app.scaleFactor
                            color: app.primaryColor
                            border.color: slider.pressed ? "#bdbebf": "white"
                            border.width: 2 * app.scaleFactor

                            Behavior on border.color {
                                ColorAnimation {duration: 400}
                            }
                        }

                        onMoved: {
                            // If the change to buffer radius is made from Slider - reflect this change in Radius text field -- This way it breaks the binding loop (2)
                            if ( slider.focus ){
                                radiusTextField.text = Number(valueAt(position)).toLocaleString(Qt.locale(), "f", mapView.bufferRadiusPrecision)
                            }

                            // set current radius to reflect the change in the slider
                            currentRadius = parseFloat(valueAt(position)).toFixed(1);
                        }

                        // Set default value of the selected buffer radius to the slider when opened
                        Component.onCompleted: {
                            slider.value = currentRadius;
                        }
                    }
                }

                // To reset the buffer distance text field and slider values to default radius
                Connections{
                    target: filtersView

                    function onApply(){
                        if ( radiusTextField.text === "" ){
                            radiusTextField.text = Number(defaultRadius).toLocaleString(Qt.locale(), "f", mapView.bufferRadiusPrecision)
                            mapView.bufferDistance = defaultRadius
                        }
                    }

                    function onReset(){
                        radiusTextField.text = Number(defaultRadius).toLocaleString(Qt.locale(), "f", mapView.bufferRadiusPrecision)
                        slider.value = defaultRadius
                    }
                }

                Item {
                    Layout.preferredHeight:  4 * app.scaleFactor
                    Layout.fillWidth: true
                }


                Item {
                    Layout.preferredHeight:  16 * app.scaleFactor
                    Layout.fillWidth: true

                    RowLayout {
                        anchors.fill: parent
                        spacing: 0

                        Item {
                            Layout.fillHeight: true
                            Layout.preferredWidth:  16 * app.scaleFactor
                        }

                        Label {
                            Layout.fillHeight: true
                            Layout.alignment: Qt.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                            text: qsTr("%L1").arg(radiusMin)
                            font.pixelSize: 14 * app.scaleFactor
                            font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                            color: colors.blk_200
                        }

                        Item {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                        }

                        Label {
                            Layout.fillHeight: true
                            Layout.alignment: Qt.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                            text: qsTr("%L1").arg(radiusMax)
                            font.pixelSize: 14 * app.scaleFactor
                            font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                            color: colors.blk_200
                        }

                        Item {
                            Layout.fillHeight: true
                            Layout.preferredWidth:  16 * app.scaleFactor
                        }
                    }
                }


                Item {
                    Layout.preferredHeight:  16 * app.scaleFactor
                    Layout.fillWidth: true
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: app.scaleFactor
                    visible: filterListModel ? filterListModel.count > 0 : false

                    Rectangle {
                        anchors.fill: parent
                        color: colors.blk_020
                    }
                }
            }
        }

        delegate: Item {
            id:filterItem
            width: filterConfigListView.width
            height: layerExpressionsColumn.height
            property var isCollapsed:collapsedState

            ColumnLayout {
                id: layerExpressionsColumn
                width: parent.width
                spacing: 0

                Rectangle{
                    Layout.preferredWidth: parent.width
                    Layout.preferredHeight:layerHeader1.height

                    MouseArea {
                        width: parent.width
                        height:layerHeader.height
                        onClicked: {
                            collapsedState = !collapsedState
                        }

                        RowLayout{
                            id:layerHeader1
                            width: parent.width
                            height:layerHeader.height
                            spacing:0

                            ColumnLayout{
                                id:layerHeader
                                Layout.preferredWidth: parent.width - 50 * scaleFactor

                                Rectangle{
                                    Layout.fillWidth:true
                                    Layout.preferredHeight:16  * app.scaleFactor
                                }

                                Item{
                                    Layout.preferredWidth:parent.width - 24 * app.scaleFactor
                                    Layout.preferredHeight: layerNameText.height

                                    Label {
                                        id: layerNameText
                                        elide: Text.ElideRight
                                        width:parent.width
                                        horizontalAlignment: Text.AlignLeft
                                        verticalAlignment: Text.AlignVCenter
                                        text: layerTitle
                                        font.pixelSize: 18 * app.scaleFactor
                                        font.bold: true
                                        font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                                        color: colors.blk_200
                                        wrapMode: Text.WrapAnywhere
                                        leftPadding: app.defaultMargin
                                        rightPadding: app.defaultMargin
                                    }
                                }

                                Item{
                                    Layout.fillWidth:true
                                    Layout.preferredHeight:2  * app.scaleFactor
                                }

                                Item{
                                    Layout.preferredWidth: parent.width - 24 * app.scaleFactor
                                    Layout.preferredHeight:operatorText.height

                                    Label {
                                        id: operatorText
                                        width:parent.width
                                        horizontalAlignment: Text.AlignLeft
                                        verticalAlignment: Text.AlignVCenter
                                        text: operator === " AND "? strings.alloperator : strings.anyoperator
                                        font.pixelSize: 12 * app.scaleFactor
                                        font.bold: false
                                        font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                                        color: colors.blk_011
                                        wrapMode: Text.WordWrap
                                        leftPadding: app.defaultMargin
                                        rightPadding: app.defaultMargin
                                        maximumLineCount: 2
                                    }
                                }

                                Rectangle{
                                    Layout.fillWidth:true
                                    Layout.preferredHeight:16 * scaleFactor
                                }
                            }

                            Item{
                                Layout.preferredWidth: 32 * scaleFactor
                                Layout.preferredHeight: 32 * scaleFactor
                                Layout.alignment: Qt.AlignVCenter

                                Controls.Icon {
                                    id: rightButton
                                    objectName: "rightButton"
                                    maskColor: "#8D8D8D"
                                    imageSource: rightButtonImage
                                    rotation: collapsedState ? 0:180
                                    anchors.centerIn: parent
                                    onClicked: {
                                        collapsedState = !collapsedState
                                    }
                                }
                            }

                            Item{
                                Layout.preferredWidth: 8 * scaleFactor
                                Layout.preferredHeight: 8 * scaleFactor
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight:  app.scaleFactor
                    color: colors.blk_020
                }

                Repeater {
                    id: expressionRepeater
                    model: filterDic[layerId]
                    delegate: Item {
                        id: singleExpression
                        Layout.preferredWidth: filtersView.width
                        Layout.preferredHeight: filterItem.isCollapsed ? 0 : expressColumn.height
                        visible:filterItem.isCollapsed ? false : true

                        function getDateExpr(){
                            let _expr = ""
                            let fromDate = calendarcntrl.fromDatevalue + " 00:00 AM"
                            let toDate = calendarcntrl2.toDatevalue  + " 00:00 AM"
                            if(calendarcntrl._fromDate.text > ""){

                                var fd = new Date(fromDate)
                                var fromdt = mapViewerCore.formatDate(fd)
                            }

                            if(calendarcntrl2._toDate.text > ""){
                                var td = new Date(toDate)
                                var todate = mapViewerCore.formatDate(td)
                            }

                            if(calendarcntrl._fromDate.text > "" && calendarcntrl2._toDate.text > "")
                                _expr =  field + " BETWEEN timestamp '"+ fromdt + " 00:00:00' AND timestamp '" + todate + " 23:59:59'"
                            else if(calendarcntrl._fromDate.text > "")
                                _expr =  field + " > timestamp '"+ fromdt  + " 00:00:00'"

                            else if(calendarcntrl2._toDate.text > "")
                                _expr =  field + " < timestamp '"+ todate  + " 23:59:59'"

                            return _expr
                        }

                        ColumnLayout {
                            id: expressColumn
                            width: parent.width
                            anchors.centerIn: parent
                            spacing: 0

                            Item {
                                Layout.preferredHeight: Math.max(fieldCntrl.height, 56 * app.scaleFactor)
                                Layout.fillWidth: true

                                ColumnLayout{
                                    id:fieldCntrl
                                    width:parent.width
                                    spacing:0

                                    Rectangle {
                                        Layout.preferredHeight: 16
                                        Layout.fillWidth: true
                                    }

                                    Item{
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 30

                                        RowLayout{
                                            anchors.fill:parent
                                            spacing:0

                                            Rectangle{
                                                Layout.preferredHeight:parent.height
                                                Layout.preferredWidth: parent.width - 40

                                                Label {
                                                    id: featureNameText
                                                    elide: Text.ElideRight
                                                    width:parent.width
                                                    height:parent.height
                                                    horizontalAlignment: Text.AlignLeft
                                                    verticalAlignment: Text.AlignVCenter
                                                    text: name.trim()
                                                    font.pixelSize: 14 * app.scaleFactor
                                                    font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                                                    color: colors.blk_200
                                                    wrapMode: Text.Wrap
                                                    leftPadding: app.defaultMargin
                                                    rightPadding: app.defaultMargin
                                                    maximumLineCount: 2
                                                }
                                            }


                                            Rectangle {
                                                Layout.fillHeight: true
                                                Layout.preferredWidth: 24 * app.scaleFactor

                                                CheckBox {
                                                    id:_checkbox
                                                    width: parent.width
                                                    height: parent.height
                                                    anchors.centerIn: parent
                                                    Material.accent: app.primaryColor
                                                    Material.theme: Material.Light
                                                    checked: isChecked
                                                    enabled: (definitionExpression !== "undefined" &&  definitionExpression > "") || comboBox.currentIndex > 0 || (type === "number" && !isDomainField && isJsonQueryFieldsPopulated)

                                                    Connections{
                                                        target:filterConfigListView
                                                        function onMovementEnded(){

                                                            if(configuredFilters.includes(id) || (userConfiguredDefinitionExpr[id] !== undefined && userConfiguredDefinitionExpr[id] !== null))
                                                                _checkbox.checked = true
                                                        }
                                                    }

                                                    Connections{
                                                        target:filtersView
                                                        function onFilterConfigChanged(){
                                                            let item = filterDic[layerId].get(index)
                                                            _checkbox.checked = item.isChecked
                                                        }
                                                    }

                                                    onCheckedChanged: {
                                                        if(checked)

                                                            noOfFiltersApplied =   filtersView.getFiltersCount(id)
                                                        else
                                                            noOfFiltersApplied -=1

                                                        if(checked){
                                                            if(typeof definitionExpression !== "undefined" &&  definitionExpression > ""){
                                                                if(!configuredFilters.includes(id))
                                                                    configuredFilters.push(id)
                                                            } else{
                                                                var _expr =""

                                                                //create the definition expressiion
                                                                if(isDomainField && field){
                                                                    if(comboBox.currentIndex > 0){
                                                                        var domainname = comboBox.displayText
                                                                        var domainValue = mapViewerCore.getDomainCode(layerId,field,domainname)

                                                                        //update the filterDic with definition expr. To test with the field type as int and string
                                                                        if(type === "number")
                                                                            _expr = `${field} = ${domainValue}`
                                                                        else
                                                                            _expr = `${field} = '${domainValue}'`
                                                                        userConfiguredDefinitionExpr[id] = _expr
                                                                    } else {
                                                                        userConfiguredDefinitionExpr[id] = null
                                                                        checked = false

                                                                    }
                                                                } else if (type === "string"){
                                                                    if(comboBox.currentIndex > 0){
                                                                        var fldval = comboBox.displayText

                                                                        _expr = `${field} = '${fldval}'`
                                                                        userConfiguredDefinitionExpr[id] = _expr

                                                                    } else{
                                                                        userConfiguredDefinitionExpr[id] = null
                                                                        checked = false
                                                                    }
                                                                } else if(type === "number") {
                                                                    var from = sliderCntrl._slidercntrl.first.value
                                                                    var to = sliderCntrl._slidercntrl.second.value
                                                                    _expr = `${field} BETWEEN ${from} AND ${to}`
                                                                    userConfiguredDefinitionExpr[id] = _expr
                                                                } else if(type === "date"){
                                                                    _expr = singleExpression.getDateExpr()

                                                                    if(_expr > "")
                                                                        userConfiguredDefinitionExpr[id] = _expr
                                                                    else{
                                                                        userConfiguredDefinitionExpr[id] = null
                                                                        checked = false
                                                                    }
                                                                }
                                                            }
                                                        } else {
                                                            if(configuredFilters.includes(id)){
                                                                let filteredArray = configuredFilters.filter(exprid => exprid !==  id)
                                                                configuredFilters = filteredArray
                                                            }
                                                            userConfiguredDefinitionExpr[id] = null
                                                        }
                                                    }
                                                }
                                            }

                                            Item{
                                                Layout.preferredWidth: 16 * app.scaleFactor
                                                Layout.fillHeight: true
                                            }
                                        }
                                    }

                                    Item{
                                        id:sliderCntrl
                                        Layout.preferredHeight: typeof type !== "undefined" && type > "" && type === "number" && !isDomainField && isJsonQueryFieldsPopulated ? 32 * app.scaleFactor : 0
                                        Layout.preferredWidth: parent.width - 36 * app.scaleFactor
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.leftMargin: 4 * app.scaleFactor
                                        visible: typeof type !== "undefined" && type > "" && type === "number" && !isDomainField && isJsonQueryFieldsPopulated

                                        property alias _slidercntrl : rangeslider
                                        property var isIntegerSlider: true

                                        function getSliderType(){
                                            let decimalPartFrom = sliderCntrl._slidercntrl.from - Math.floor(sliderCntrl._slidercntrl.from)
                                            let decimalPartTo = sliderCntrl._slidercntrl.to - Math.floor(sliderCntrl._slidercntrl.to)
                                            if(decimalPartFrom > 0 || decimalPartTo > 0)
                                                isIntegerSlider = false
                                            else
                                                isIntegerSlider = true
                                        }

                                        RangeSlider {
                                            id:rangeslider
                                            visible: typeof type !== "undefined" && type > "" && type === "number" && !isDomainField && isJsonQueryFieldsPopulated
                                            from: typeof type !== "undefined" && type > "" && type === "number"  && !isDomainField && fieldValues["values"] ? fieldValues["values"][0] : 0
                                            to: typeof type !== "undefined" && type > "" && type === "number" && !isDomainField && fieldValues["values"] ? fieldValues["values"][1] : 0
                                            first.value: from
                                            second.value: to
                                            topPadding: 16
                                            stepSize:typeof step !== "undefined" ? step :1

                                            background: Rectangle {
                                                x:0
                                                y: rangeslider.topPadding + rangeslider.availableHeight / 2 - height / 2
                                                implicitWidth: sliderCntrl.width
                                                implicitHeight: 4
                                                width: sliderCntrl.width
                                                height: implicitHeight
                                                radius: 2
                                                color: "#AAAAAA"

                                                Rectangle {
                                                    x: app.isRightToLeft ? rangeslider.second.visualPosition * parent.width :rangeslider.first.visualPosition * parent.width
                                                    width: app.isRightToLeft?rangeslider.first.visualPosition * parent.width - x :rangeslider.second.visualPosition * parent.width - x
                                                    height: parent.height
                                                    color: app.primaryColor
                                                    radius: 2
                                                }
                                            }

                                            first.handle: Rectangle {
                                                x: rangeslider.first.visualPosition * (rangeslider.availableWidth - rangeslider.leftPadding) - rangeslider.leftPadding
                                                y: rangeslider.topPadding + rangeslider.availableHeight / 2 - height / 2
                                                implicitWidth: 24 * scaleFactor
                                                implicitHeight: 24 * scaleFactor
                                                radius: 12 * scaleFactor
                                                color: app.primaryColor
                                                border.color: rangeslider.pressed ? "#bdbebf": "white"
                                                border.width: 4 * scaleFactor

                                                Behavior on border.color {
                                                    ColorAnimation {duration: 400}
                                                }
                                            }

                                            second.handle: Rectangle {
                                                id:secondsliderHandle
                                                x: rangeslider.second.visualPosition * (rangeslider.availableWidth - rangeslider.leftPadding) - rangeslider.leftPadding
                                                y: rangeslider.topPadding + rangeslider.availableHeight / 2 - height / 2
                                                implicitWidth: 24 * scaleFactor
                                                implicitHeight: 24 * scaleFactor
                                                radius: 12 * scaleFactor
                                                color: app.primaryColor
                                                border.color: rangeslider.pressed ? "#bdbebf": "white"
                                                border.width: 4 * scaleFactor

                                                Behavior on border.color {
                                                    ColorAnimation {duration: 400}
                                                }
                                            }

                                            first.onMoved: {
                                                _checkbox.checked = true
                                                sliderCntrl.updateSliderControlTextField(true, false)

                                                if(isChecked || _checkbox.checked){
                                                    var from = sliderCntrl._slidercntrl.first.value
                                                    var to = sliderCntrl._slidercntrl.second.value
                                                    let _expr = `${field} BETWEEN ${from} AND ${to}`
                                                    userConfiguredDefinitionExpr[id] = _expr

                                                    for (var i =0 ; i < filterDic[layerId].count; i++){
                                                        let exprId = filterDic[layerId].get(i).id
                                                        if(exprId === id){
                                                            filterDic[layerId].get(i).definitionExpression = _expr
                                                        }
                                                    }
                                                }
                                            }

                                            second.onMoved: {
                                                _checkbox.checked = true
                                                sliderCntrl.updateSliderControlTextField(false, true)

                                                if(isChecked || _checkbox.checked){
                                                    var from = sliderCntrl._slidercntrl.first.value
                                                    var to = sliderCntrl._slidercntrl.second.value
                                                    let _expr = `${field} BETWEEN ${from} AND ${to}`
                                                    userConfiguredDefinitionExpr[id] = _expr
                                                    for (var i =0 ; i < filterDic[layerId].count; i++){
                                                        let exprId = filterDic[layerId].get(i).id
                                                        if(exprId === id){
                                                            filterDic[layerId].get(i).definitionExpression = _expr
                                                        }
                                                    }
                                                }
                                            }

                                            Connections{
                                                target:filtersView
                                                function onReset(){
                                                    if( typeof type !== "undefined" && type > "" && type === "number" && !isDomainField ){
                                                        if(fieldValues["values"]){
                                                            sliderCntrl._slidercntrl.first.value =  fieldValues["values"][0]
                                                            sliderCntrl._slidercntrl.second.value = fieldValues["values"][1]
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        Component.onCompleted:{
                                            if( !isDomainField ){
                                                if( typeof definitionExpression !== "undefined" && definitionExpression > "" ){
                                                    let expr = definitionExpression
                                                    if(expr && typeof type !== "undefined" && type > "" && type === "number"){
                                                        //first split by operator and
                                                        var values = expr.split('BETWEEN')[1]
                                                        var fromval = values.split('AND')[0]
                                                        var toval = values.split('AND')[1]
                                                        var firstval = fromval.trim()
                                                        var secondval = toval.trim()
                                                        _slidercntrl.first.value = firstval
                                                        _slidercntrl.second.value = secondval
                                                    }
                                                } else if ( typeof type !== "undefined" && type > "" && type === "number" ){
                                                    if(fieldValues["values"]){
                                                        sliderCntrl._slidercntrl.first.value =  fieldValues["values"][0]
                                                        sliderCntrl._slidercntrl.second.value = fieldValues["values"][1]
                                                    }
                                                }

                                                sliderCntrl.updateSliderControlTextField(true, true)
                                            }
                                        }

                                        /* Function that updates slider position, value and the corresponding sliderControl Textfields
                                        *  _slidercntrFirst & _slidercntrSecond. This function gets called whenever the slider position is moved
                                        *  or during when the filters page is opened.
                                        */
                                        function updateSliderControlTextField(updateMinField, updateMaxField){
                                            sliderCntrl.getSliderType()

                                            if ( updateMinField ){
                                                if( sliderCntrl.isIntegerSlider ){
                                                    let val = sliderCntrl._slidercntrl.first.value.toFixed(0)
                                                    _slidercntrFirst.text = Number(val).toLocaleString(Qt.locale(),"f",0)
                                                } else {
                                                    let val1 = sliderCntrl._slidercntrl.first.value.toFixed(1)
                                                    _slidercntrFirst.text = Number(val1).toLocaleString(Qt.locale(),"f",1)
                                                }
                                            }

                                            if ( updateMaxField ){
                                                if ( sliderCntrl.isIntegerSlider ) {
                                                    let val = sliderCntrl._slidercntrl.second.value.toFixed(0)
                                                    _slidercntrSecond.text = Number(val).toLocaleString(Qt.locale(),"f", 0)
                                                } else {
                                                    let val1 = sliderCntrl._slidercntrl.second.value.toFixed(1)
                                                    _slidercntrSecond.text = Number(val1).toLocaleString(Qt.locale(),"f", 1)
                                                }
                                            }
                                        }
                                    }

                                    Item{
                                        Layout.preferredHeight: typeof type !== "undefined" && type > "" && type === "number" && !isDomainField ? 32 * app.scaleFactor : 0
                                        Layout.fillWidth: true
                                    }

                                    Item{
                                        Layout.preferredWidth: typeof type !== "undefined" && type > "" && type === "number" && !isDomainField && isJsonQueryFieldsPopulated ? parent.width - 32 * app.scaleFactor : 0
                                        Layout.preferredHeight: 48 * app.scaleFactor
                                        Layout.alignment: Qt.AlignHCenter
                                        visible: typeof type !== "undefined" && type > "" && type === "number" && !isDomainField && isJsonQueryFieldsPopulated

                                        Item{
                                            id:slidercntrlfrom
                                            width:parent.width/2 - 8
                                            height: visible?48 : 0
                                            anchors.left:parent.left
                                            visible: typeof type !== "undefined" && type > "" && type === "number" && !isDomainField && isJsonQueryFieldsPopulated

                                            RowLayout{
                                                anchors.fill:parent

                                                Label{
                                                    text: app.isRightToLeft?qsTr(":Min"): qsTr("Min:")
                                                    leftPadding:app.isRightToLeft ?  0 :16
                                                    rightPadding: app.isRightToLeft ?  16 :0
                                                    topPadding: 0
                                                    visible: typeof type !== "undefined" && type > "" && type === "number" && !isDomainField ? true:false
                                                    Layout.preferredHeight: typeof type !== "undefined" && type > "" && type === "number" && !isDomainField ? parent.height : 0
                                                    verticalAlignment: Text.AlignVCenter
                                                    color:app.primaryColor
                                                    font.pixelSize: 14 * app.scaleFactor
                                                    font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                                                    background: Rectangle{
                                                        height:48
                                                        width:slidercntrlfrom.width
                                                        color:"#212121"
                                                        opacity: 0.08
                                                        anchors.left:parent.left
                                                    }
                                                }

                                                TextField{
                                                    id:_slidercntrFirst
                                                    Layout.fillWidth: true
                                                    topPadding: 0
                                                    bottomPadding: 0
                                                    visible: typeof type !== "undefined" && type > "" && type === "number" && !isDomainField ? true:false
                                                    Layout.preferredHeight: typeof type !== "undefined" && type > "" && type === "number" && !isDomainField ? parent.height : 0
                                                    Material.accent: app.primaryColor
                                                    clip:true
                                                    verticalAlignment: Text.AlignVCenter
                                                    horizontalAlignment: Text.AlignLeft
                                                    placeholderText: typeof type !== "undefined" && type > "" && type === "number" && !isDomainField && fieldValues["values"]
                                                    ? Number(fieldValues["values"][0]).toLocaleString(Qt.locale(), "f", 1)
                                                    : 0
                                                    placeholderTextColor: "white"
                                                    color:"#2b2b2b"
                                                    font.pixelSize: 14 * app.scaleFactor
                                                    font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                                                    inputMethodHints: Qt.ImhFormattedNumbersOnly

                                                    Component.onCompleted: {
                                                        sliderCntrl.getSliderType()
                                                        if ( sliderCntrl.isIntegerSlider ){
                                                            _slidercntrFirst.validator = textFieldIntValidatorComponent.createObject(parent)
                                                        } else {
                                                            _slidercntrFirst.validator = textFieldDoubleValidatorComponent.createObject(parent, { decimals: 1 })
                                                        }
                                                    }

                                                    // Reset values to min and max values of RangeSlider if the values are invalid - upon focus change and when input is accepted
                                                    onEditingFinished: {
                                                        let _txt = Number.fromLocaleString(Qt.locale(),text)
                                                        sliderCntrl.getSliderType()

                                                        if ( _txt < rangeslider.from ){
                                                            if ( sliderCntrl.isIntegerSlider ){
                                                                _slidercntrFirst.text = Number(rangeslider.from).toLocaleString(Qt.locale(), "f", 0)
                                                            } else {
                                                                _slidercntrFirst.text = Number(rangeslider.from).toLocaleString(Qt.locale(), "f", 1)
                                                            }
                                                        }

                                                        if ( _txt  > rangeslider.second.value ){
                                                            if ( sliderCntrl.isIntegerSlider ){
                                                                _slidercntrFirst.text = Number(rangeslider.second.value).toLocaleString(Qt.locale(), "f", 0)
                                                            } else {
                                                                _slidercntrFirst.text = Number(rangeslider.second.value).toLocaleString(Qt.locale(), "f", 1)
                                                            }
                                                        }
                                                    }

                                                    onAccepted: {
                                                        if ( isChecked || _checkbox.checked ){
                                                            let from = sliderCntrl._slidercntrl.first.value
                                                            let to = sliderCntrl._slidercntrl.second.value
                                                            let _expr = `${field} BETWEEN ${from} AND ${to}`
                                                            userConfiguredDefinitionExpr[id] = _expr
                                                            for (let i =0 ; i < filterDic[layerId].count; i++){
                                                                let exprId = filterDic[layerId].get(i).id
                                                                if(exprId === id){
                                                                    filterDic[layerId].get(i).definitionExpression = _expr
                                                                }
                                                            }
                                                        }
                                                        _checkbox.checked = true
                                                    }

                                                    // Reflect changes in the RangeSlider as the text changes in the textfield
                                                    onTextChanged: {
                                                        let _txt = Number.fromLocaleString(Qt.locale(),text)

                                                        // Update the RangeSlider values only if changes are made to the TextField - to break binding loop
                                                        if ( _slidercntrFirst.focus ){
                                                            sliderCntrl._slidercntrl.first.value = _txt
                                                        }
                                                    }

                                                    onFocusChanged: {
                                                        if ( _slidercntrFirst.text === "" ){
                                                            if ( sliderCntrl.isIntegerSlider ){
                                                                _slidercntrFirst.text = Number(fieldValues["values"][0]).toLocaleString(Qt.locale(), "f", 0)
                                                            } else {
                                                                _slidercntrFirst.text = Number(fieldValues["values"][0]).toLocaleString(Qt.locale(), "f", 1)
                                                            }
                                                            sliderCntrl._slidercntrl.first.value = fieldValues["values"][0]
                                                        }
                                                    }
                                                }
                                            }

                                            Rectangle{
                                                anchors.bottom:parent.bottom
                                                width:parent.width
                                                height:1
                                                color:app.primaryColor
                                            }
                                        }

                                        Item{
                                            id:slidercntrl2
                                            width:parent.width/2 - 8
                                            height: visible?48 : 0
                                            anchors.right:parent.right
                                            visible: typeof type !== "undefined" && type > "" && type === "number" && !isDomainField && isJsonQueryFieldsPopulated

                                            RowLayout{
                                                anchors.fill:parent

                                                Label{
                                                    text:app.isRightToLeft?qsTr(":Max") : qsTr("Max:")
                                                    leftPadding:app.isRightToLeft ?  0 :16
                                                    rightPadding: app.isRightToLeft ?  16 :0
                                                    topPadding: 0
                                                    visible: typeof type !== "undefined" && type > "" && type === "number" && !isDomainField ? true:false
                                                    Layout.preferredHeight: typeof type !== "undefined" && type > "" && type === "number" && !isDomainField ? parent.height : 0
                                                    verticalAlignment:Text.AlignVCenter
                                                    color:app.primaryColor
                                                    font.pixelSize: 14 * app.scaleFactor
                                                    font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                                                    opacity:1
                                                    background: Rectangle{
                                                        height:48
                                                        width:slidercntrl2.width
                                                        color:"#212121"
                                                        opacity: 0.08
                                                        anchors.left:parent.left
                                                    }
                                                }

                                                TextField{
                                                    id:_slidercntrSecond
                                                    visible: typeof type !== "undefined" && type > "" && type === "number" && !isDomainField ? true:false
                                                    Layout.preferredHeight: typeof type !== "undefined" && type > "" && type === "number" && !isDomainField ? parent.height : 0
                                                    Layout.fillWidth: true
                                                    topPadding: 0
                                                    bottomPadding: 0
                                                    placeholderText: (typeof type !== "undefined" && type > "" && type === "number" && !isDomainField && fieldValues["values"])
                                                                     ? Number(fieldValues["values"][1]).toLocaleString(Qt.locale(), "f", 1)
                                                                     : 0
                                                    placeholderTextColor: "white"
                                                    verticalAlignment:Text.AlignVCenter
                                                    horizontalAlignment: Text.AlignLeft
                                                    color:"#2b2b2b"
                                                    font.pixelSize: 14 * app.scaleFactor
                                                    font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                                                    opacity:1
                                                    Material.accent: app.primaryColor
                                                    clip:true
                                                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                                                    validator: IntValidator{}

                                                    Component.onCompleted: {
                                                        sliderCntrl.getSliderType()
                                                        if ( sliderCntrl.isIntegerSlider ){
                                                            _slidercntrSecond.validator = textFieldIntValidatorComponent.createObject(parent)
                                                        } else {
                                                            _slidercntrSecond.validator = textFieldDoubleValidatorComponent.createObject(parent, { decimals: 1 })
                                                        }
                                                    }

                                                    // Reset values to min and max values of RangeSlider if the values are invalid - upon focus change
                                                    onEditingFinished: {
                                                        let _txt = Number.fromLocaleString(Qt.locale(),text)
                                                        sliderCntrl.getSliderType()

                                                        if ( _txt > rangeslider.to ){
                                                            if ( sliderCntrl.isIntegerSlider ){
                                                                _slidercntrSecond.text = Number(rangeslider.to).toLocaleString(Qt.locale(), "f", 0)
                                                            } else {
                                                                _slidercntrSecond.text = Number(rangeslider.to).toLocaleString(Qt.locale(), "f", 1)
                                                            }
                                                        }

                                                        if ( _txt < rangeslider.first.value ){
                                                            if ( sliderCntrl.isIntegerSlider ){
                                                                _slidercntrSecond.text = Number(rangeslider.first.value).toLocaleString(Qt.locale(), "f", 0)
                                                            } else {
                                                                _slidercntrSecond.text = Number(rangeslider.first.value).toLocaleString(Qt.locale(), "f", 1)
                                                            }
                                                        }
                                                    }

                                                    onAccepted: {
                                                        if ( isChecked || _checkbox.checked ){
                                                            let from = sliderCntrl._slidercntrl.first.value
                                                            let to = sliderCntrl._slidercntrl.second.value
                                                            let _expr = `${field} BETWEEN ${from} AND ${to}`
                                                            userConfiguredDefinitionExpr[id] = _expr
                                                            for (let i =0 ; i < filterDic[layerId].count; i++){
                                                                let exprId = filterDic[layerId].get(i).id
                                                                if(exprId === id){
                                                                    filterDic[layerId].get(i).definitionExpression = _expr
                                                                }
                                                            }
                                                        }
                                                        _checkbox.checked = true
                                                    }

                                                    // Reflect changes in the RangeSlider as the text changes in the textfield
                                                    onTextChanged: {
                                                        let _txt = Number.fromLocaleString(Qt.locale(),text)

                                                        // Update the RangeSlider values only if changes are made to the TextField - to break binding loop
                                                        if ( _slidercntrSecond.focus ){
                                                            sliderCntrl._slidercntrl.second.value = _txt
                                                        }
                                                    }

                                                    onFocusChanged: {
                                                        if ( _slidercntrSecond.text === "" ){
                                                            if ( sliderCntrl.isIntegerSlider ){
                                                                _slidercntrSecond.text = Number(fieldValues["values"][1]).toLocaleString(Qt.locale(), "f", 0)
                                                            } else {
                                                                _slidercntrSecond.text = Number(fieldValues["values"][1]).toLocaleString(Qt.locale(), "f", 1)
                                                            }
                                                            sliderCntrl._slidercntrl.second.value = fieldValues["values"][1]
                                                        }
                                                    }
                                                }
                                            }

                                            Rectangle{
                                                anchors.bottom:parent.bottom
                                                width:parent.width
                                                height:1
                                                color:app.primaryColor
                                            }
                                        }

                                        /* Reset values to min and max values of RangeSlider if the values are invalid - upon Accepting filters
                                        * This will change from and to textfield values only if neither the focus was changed nor the text-field was accepted
                                        */
                                        Connections{
                                            target: filtersView

                                            function onApply(){
                                                if ( _slidercntrFirst.text === "" && typeof fieldValues["values"][0] === "number"){
                                                    _slidercntrFirst.text = fieldValues["values"][0]
                                                    sliderCntrl._slidercntrl.first.value = fieldValues["values"][0]
                                                }

                                                if ( _slidercntrSecond.text === "" && typeof fieldValues["values"][1] === "number"){
                                                    _slidercntrSecond.text = fieldValues["values"][1]
                                                    sliderCntrl._slidercntrl.second.value = fieldValues["values"][1]
                                                }
                                            }

                                            function onReset(){
                                                sliderCntrl.getSliderType()
                                                if ( sliderCntrl.isIntegerSlider ){
                                                    _slidercntrFirst.text = Number(rangeslider.from).toLocaleString(Qt.locale(), "f", 0)
                                                    _slidercntrSecond.text = Number(rangeslider.to).toLocaleString(Qt.locale(), "f", 0)
                                                } else {
                                                    _slidercntrFirst.text = Number(rangeslider.from).toLocaleString(Qt.locale(), "f", 1)
                                                    _slidercntrSecond.text = Number(rangeslider.to).toLocaleString(Qt.locale(), "f", 1)
                                                }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.preferredHeight: typeof type !== "undefined" && type > "" && ( (type === "string" ) || isDomainField ) ? 16 * app.scaleFactor : 0
                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        Layout.preferredHeight: typeof type !== "undefined" && type > "" && ( (type === "string" ) || isDomainField ) ? 48 * app.scaleFactor : 0
                                        Layout.fillWidth: true
                                        visible: typeof type !== "undefined" && type > "" && ( (type === "string" ) || isDomainField )
                                        Layout.leftMargin: 16 * app.scaleFactor
                                        Layout.rightMargin: 16 * app.scaleFactor

                                        ComboBox {
                                            id: comboBox
                                            model: typeof type !== "undefined" && type > "" && ( type === "string" || isDomainField ) ? fieldValues["values"] : []
                                            anchors.fill:parent
                                            height: 48 * scaleFactor
                                            width: parent.width //* 0.6
                                            Material.accent:app.primaryColor
                                            enabled: typeof type !== "undefined" && type > "" && ( (type === "string")|| isDomainField )
                                            contentItem:Text {
                                                text:comboBox.displayText
                                                verticalAlignment: Text.AlignVCenter
                                                horizontalAlignment: Text.AlignLeft
                                                padding: 16 * scaleFactor
                                                font.pixelSize: 14 * app.scaleFactor
                                                font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                                                color: "#2b2b2b"
                                            }

                                            indicator: Canvas {
                                                id: canvas
                                                x: app.isRightToLeft? comboBox.leftPadding :comboBox.width - width - comboBox.rightPadding
                                                y: comboBox.topPadding + (comboBox.availableHeight - height) / 2
                                                width: 12
                                                height: 8
                                                contextType: "2d"

                                                Connections {
                                                    target: comboBox
                                                    function onPressedChanged(){
                                                        canvas.requestPaint()
                                                    }
                                                }

                                                onPaint: {
                                                    context.reset();
                                                    context.moveTo(0, 0);
                                                    context.lineTo(width, 0);
                                                    context.lineTo(width / 2, height);
                                                    context.closePath();
                                                    context.fillStyle = app.black_87;
                                                    context.fill();
                                                }
                                            }

                                            delegate: MenuItem {
                                                width: comboBox.popup.width
                                                text: modelData
                                                Material.foreground: "black"
                                                highlighted: false
                                                hoverEnabled: true
                                            }
                                            background: Rectangle {
                                                id: rectdomain
                                                width: comboBox.width
                                                border.width: app.isDarkMode? 0:1
                                                anchors.top:comboBox.top
                                                anchors.bottom:comboBox.bottom
                                                border.color: comboBox.focus? app.primaryColor:"lightgray"
                                            }

                                            font {
                                                pointSize: app.baseFontSize
                                                family: "%1,%2".arg(baseFontFamily).arg(fontNameFallbacks)
                                            }

                                            onActivated: {
                                                _checkbox.checked = true

                                                let _expr = ""
                                                if(isDomainField){
                                                    var domainname = comboBox.displayText
                                                    var domainValue = mapViewerCore.getDomainCode(layerId,field,domainname)

                                                    if(index > 0){
                                                        if(typeof type !== "undefined" && type > "" && type === "number")
                                                            _expr = `${field} = ${domainValue}`
                                                        else
                                                            _expr = `${field} = '${domainValue}'`
                                                    }
                                                    else
                                                        _checkbox.checked = false
                                                }

                                                else if (typeof type !== "undefined" && type > "" && type === "string"){
                                                    var fldval = comboBox.displayText
                                                    if(index > 0)

                                                        _expr = `${field} = '${fldval}'`
                                                    else
                                                        _checkbox.checked = false
                                                }

                                                userConfiguredDefinitionExpr[id] = _expr
                                                for (var i =0 ; i < filterDic[layerId].count; i++){
                                                    let exprId = filterDic[layerId].get(i).id
                                                    if(exprId === id){
                                                        filterDic[layerId].get(i).definitionExpression = _expr
                                                    }
                                                }
                                            }

                                            Component.onCompleted:{
                                                if ( typeof definitionExpression !== "undefined" && definitionExpression > "" ){
                                                    let expr = definitionExpression

                                                    if ( expr && ( typeof type !== "undefined" && type > "" && ( type === "string" || isDomainField)) ){
                                                        let val = expr.split('=')[1].trim()
                                                        let value_mod = val

                                                        if ( typeof type !== "undefined" && type > "" && (type === "string" || type === "coded-value"))
                                                        {

                                                            if(val.charAt(0) === "'")
                                                            value_mod = val.substr(1,val.length -2)
                                                        }

                                                        if ( isDomainField ){
                                                            val = mapViewerCore.getDomainNameFromCode(layerId,field,value_mod)
                                                        } else
                                                            val = value_mod

                                                        for (let i=0; i<model.length;i++){
                                                            let name = model[i];
                                                            let name_mod = `'${name}'`

                                                            if(val === name){
                                                                comboBox.currentIndex = i;
                                                                break
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            Connections{
                                                target:filtersView
                                                function onReset(){
                                                    comboBox.currentIndex = 0
                                                }
                                            }
                                        }
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: typeof type !== "undefined" && type > "" && type === "date" ? 16 * app.scaleFactor : 0
                                    }

                                    Item{
                                        Layout.preferredWidth:parent.width - 32
                                        Layout.preferredHeight: typeof type !== "undefined" && type > "" && type === "date" ? 48 * app.scaleFactor : 0
                                        Layout.alignment: Qt.AlignHCenter
                                        visible: typeof type !== "undefined" && type > "" && type === "date"

                                        Item{
                                            id:calendarcntrl
                                            width:parent.width/2 - 8
                                            height: visible?48 : 0
                                            anchors.left:parent.left
                                            visible: typeof type !== "undefined" && type > "" && type === "date"
                                            property var calendarPicker : null
                                            property alias _fromDate:fromDate
                                            property var maximumDate
                                            property var fromDatevalue

                                            Rectangle{
                                                anchors.bottom:parent.bottom
                                                width:parent.width
                                                height:1
                                                color:app.primaryColor
                                            }

                                            Label{
                                                width:parent.width - 32
                                                text:strings.start_date
                                                anchors.left:parent.left
                                                anchors.top: parent.top
                                                leftPadding: app.isRightToLeft ? 0:16
                                                rightPadding:app.isRightToLeft ? 16:0
                                                topPadding: 8
                                                verticalAlignment: Text.AlignTop
                                                horizontalAlignment: Text.AlignLeft
                                                color:app.primaryColor
                                                font.pixelSize: 12 * app.scaleFactor
                                                font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")

                                                background: Rectangle{
                                                    height:48
                                                    width:calendarcntrl.width
                                                    color:"#212121"
                                                    opacity: 0.08
                                                    anchors.left:parent.left
                                                }
                                            }

                                            TextField{
                                                id:fromDate
                                                width:parent.width - 32
                                                anchors.left:parent.left
                                                anchors.bottom:parent.bottom
                                                leftPadding: app.isRightToLeft ? 0:16
                                                rightPadding:app.isRightToLeft ? 16:0
                                                bottomPadding:7
                                                placeholderText:Qt.locale().dateFormat(Qt.DefaultLocaleShortDate)
                                                readOnly: true
                                                hoverEnabled: false
                                                verticalAlignment: Text.AlignBottom
                                                horizontalAlignment: Text.AlignLeft
                                                placeholderTextColor: "grey"
                                                color:"#2b2b2b"
                                                font.pixelSize: 14 * app.scaleFactor
                                                font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")

                                                Connections{
                                                    target:filtersView
                                                    function onReset(){
                                                        fromDate.text = ""
                                                    }
                                                }
                                            }

                                            Controls.Icon {
                                                id: calendarIcon
                                                visible:true
                                                anchors.right:parent.right
                                                anchors.verticalCenter: parent.verticalCenter
                                                imageHeight: app.units(20)
                                                imageWidth: app.units(20)
                                                maskColor: app.primaryColor
                                                imageSource: "../../MapViewer/images/ic_calendar_edit_black_24dp.png"

                                                onClicked: {
                                                    calendarcntrl.calendarPicker = calendarDialogComponent.createObject(app);
                                                    calendarcntrl.calendarPicker.swipeViewIndex = 0;
                                                    var defaultDate = new Date()
                                                    if(fromDate.text > ""){

                                                        var dt = `${fromDate.text} 00:00 AM`
                                                        defaultDate = new Date(dt)
                                                    }

                                                    calendarcntrl.calendarPicker.selectedDateAndTime = defaultDate
                                                    calendarcntrl.calendarPicker.updateDateAndTime();
                                                    calendarcntrl.calendarPicker.visible = true;
                                                    if(toDate.text > ""){
                                                        let _dt = `${toDate.text} 00:00 AM`
                                                        let  _defaultDate = new Date(_dt)
                                                        calendarcntrl.calendarPicker.setMaximumDate(_defaultDate)
                                                    }
                                                }
                                            }

                                            Connections {
                                                target: calendarcntrl.calendarPicker

                                                function onAccepted() {
                                                    calendarcntrl.fromDatevalue = calendarcntrl.calendarPicker.selectedDateAndTime.toLocaleString(Qt.locale(),"MM/dd/yyyy");
                                                    fromDate.text = calendarcntrl.calendarPicker.selectedDateAndTime.toLocaleString(Qt.locale(), Qt.DefaultLocaleShortDate).split(" ")[0];
                                                    _checkbox.checked = true
                                                    let _expr =  singleExpression.getDateExpr()
                                                    userConfiguredDefinitionExpr[id] = _expr

                                                    for (var i =0 ; i < filterDic[layerId].count; i++){
                                                        let exprId = filterDic[layerId].get(i).id
                                                        if(exprId === id){
                                                            filterDic[layerId].get(i).definitionExpression = _expr
                                                        }
                                                    }
                                                }
                                            }

                                            Component.onCompleted:{
                                                if(typeof definitionExpression !== "undefined" && definitionExpression > ""){
                                                    let expr = definitionExpression
                                                    if(expr && typeof type !== "undefined" && type > "" && type === "date"){
                                                        var betweenIndx = expr.indexOf('BETWEEN')
                                                        if(betweenIndx > -1){
                                                            let values = expr.split('BETWEEN')[1]
                                                            let fromval = values.split('AND')[0]

                                                            let fromval_mod1 = fromval.split('timestamp')[1]
                                                            let fromval_mod2 = fromval_mod1.substr(2,fromval_mod1.length - 3)
                                                            let value_mod = new Date(fromval_mod2).toLocaleString(Qt.locale(),"MM/dd/yyyy")
                                                            fromDatevalue = value_mod
                                                            _fromDate.text = new Date(fromval_mod2).toLocaleString(Qt.locale(),Qt.DefaultLocaleShortDate).split(" ")[0]//value_mod

                                                        } else{
                                                            let _fromval = expr.split('>')[1]
                                                            if(_fromval){
                                                                let _fromval_mod1 = _fromval.split('timestamp')[1]
                                                                let _fromval_mod2 = _fromval_mod1.substr(2,_fromval_mod1.length - 3)
                                                                let _value_mod = new Date(_fromval_mod2).toLocaleString(Qt.locale(),"MM/dd/yyyy")
                                                                fromDatevalue =_value_mod
                                                                _fromDate.text = new Date(_fromval_mod2).toLocaleString(Qt.locale(),Qt.DefaultLocaleShortDate).split(" ")[0]//_value_mod
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            MouseArea{
                                                anchors.fill:parent
                                                onClicked: {
                                                    calendarcntrl.calendarPicker = calendarDialogComponent.createObject(app);
                                                    calendarcntrl.calendarPicker.swipeViewIndex = 0;

                                                    var defaultDate = new Date()
                                                    if(fromDate.text > ""){
                                                        var dt = `${calendarcntrl.fromDatevalue} 00:00 AM`
                                                        defaultDate = new Date(dt)
                                                    }
                                                    calendarcntrl.calendarPicker.selectedDateAndTime = defaultDate
                                                    calendarcntrl.calendarPicker.updateDateAndTime();
                                                    calendarcntrl.calendarPicker.visible = true;
                                                    if(toDate.text > ""){
                                                        let _dt = `${calendarcntrl2.toDatevalue} 00:00 AM`
                                                        let  _defaultDate = new Date(_dt)
                                                        calendarcntrl.calendarPicker.setMaximumDate(_defaultDate)
                                                    }
                                                }
                                            }
                                        }

                                        Item{
                                            id:calendarcntrl2
                                            width:parent.width/2 - 8
                                            height: visible?48 : 0
                                            anchors.right:parent.right
                                            visible: typeof type !== "undefined" && type > "" && type === "date"

                                            property var calendarPicker : null
                                            property alias _toDate:toDate
                                            property var toDatevalue:""
                                            property var minimumDate

                                            Rectangle{
                                                anchors.bottom:parent.bottom
                                                width:parent.width
                                                height:1
                                                color:app.primaryColor
                                            }

                                            Label{
                                                width:parent.width - 32
                                                text:strings.end_date
                                                anchors.left:parent.left
                                                anchors.top: parent.top
                                                leftPadding: app.isRightToLeft ? 0:16
                                                rightPadding:app.isRightToLeft ? 16:0
                                                topPadding: 8
                                                verticalAlignment: Text.AlignTop
                                                horizontalAlignment: Text.AlignLeft
                                                color:app.primaryColor
                                                font.pixelSize: 12 * app.scaleFactor
                                                font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                                                background: Rectangle{
                                                    height:48
                                                    width:calendarcntrl2.width
                                                    color:"#212121"
                                                    opacity: 0.08
                                                    anchors.left:parent.left
                                                }
                                            }

                                            TextField{
                                                id:toDate
                                                width:parent.width - 32
                                                anchors.left:parent.left
                                                anchors.bottom:parent.bottom
                                                leftPadding: app.isRightToLeft ? 0:16
                                                rightPadding:app.isRightToLeft ? 16:0
                                                bottomPadding:7
                                                placeholderText: Qt.locale().dateFormat(Qt.DefaultLocaleShortDate)//qsTr("mm/dd/yy")
                                                readOnly: true
                                                verticalAlignment: Text.AlignBottom
                                                horizontalAlignment: Text.AlignLeft
                                                placeholderTextColor: "grey"
                                                hoverEnabled: false
                                                color:"#2b2b2b"
                                                font.pixelSize: 14 * app.scaleFactor
                                                font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                                                Connections{
                                                    target:filtersView
                                                    function onReset(){
                                                        toDate.text = ""
                                                    }
                                                }
                                            }

                                            Controls.Icon {
                                                id: calendarIcon2
                                                visible:true
                                                anchors.right:parent.right
                                                anchors.verticalCenter: parent.verticalCenter
                                                imageHeight: app.units(20)
                                                imageWidth: app.units(20)
                                                maskColor: app.primaryColor
                                                imageSource: "../../MapViewer/images/ic_calendar_edit_black_24dp.png"

                                                onClicked: {
                                                    calendarcntrl2.calendarPicker = calendarDialogComponent.createObject(app);
                                                    calendarcntrl2.calendarPicker.swipeViewIndex = 0;
                                                    var defaultDate = new Date()

                                                    if(toDate.text > ""){
                                                        var dt = `${toDatevalue} 00:00 AM`
                                                        defaultDate = new Date(dt)
                                                    }
                                                    calendarcntrl2.calendarPicker.selectedDateAndTime = defaultDate
                                                    calendarcntrl2.calendarPicker.updateDateAndTime();
                                                    calendarcntrl2.calendarPicker.visible = true;

                                                    if(fromDate.text > ""){
                                                        let _dt = `${fromDatevalue} 00:00 AM`
                                                        let  _defaultDate = new Date(_dt)
                                                        calendarcntrl2.calendarPicker.setMinimumDate(_defaultDate)
                                                    }
                                                }
                                            }

                                            Connections {
                                                target: calendarcntrl2.calendarPicker
                                                function onAccepted() {
                                                    calendarcntrl2.toDatevalue = calendarcntrl2.calendarPicker.selectedDateAndTime.toLocaleString(Qt.locale(),"MM/dd/yyyy");
                                                    toDate.text = calendarcntrl2.calendarPicker.selectedDateAndTime.toLocaleString(Qt.locale(),Qt.DefaultLocaleShortDate).split(" ")[0];;
                                                    _checkbox.checked = true
                                                    let _expr =  singleExpression.getDateExpr()
                                                    userConfiguredDefinitionExpr[id] = _expr

                                                    for (var i =0 ; i < filterDic[layerId].count; i++){
                                                        let exprId = filterDic[layerId].get(i).id
                                                        if(exprId === id){
                                                            filterDic[layerId].get(i).definitionExpression = _expr
                                                        }
                                                    }
                                                }
                                            }

                                            MouseArea{
                                                anchors.fill: parent

                                                onClicked: {
                                                    calendarcntrl2.calendarPicker = calendarDialogComponent.createObject(app);
                                                    calendarcntrl2.calendarPicker.swipeViewIndex = 0;
                                                    var defaultDate = new Date()
                                                    if(toDate.text > ""){


                                                        var dt = `${calendarcntrl2.toDatevalue} 00:00 AM`

                                                        defaultDate = new Date(dt)
                                                    }
                                                    calendarcntrl2.calendarPicker.selectedDateAndTime = defaultDate
                                                    calendarcntrl2.calendarPicker.updateDateAndTime();
                                                    calendarcntrl2.calendarPicker.visible = true;

                                                    if(fromDate.text > ""){
                                                        let _dt = `${calendarcntrl.fromDatevalue} 00:00 AM`

                                                        let  _defaultDate = new Date(_dt)
                                                        calendarcntrl2.calendarPicker.setMinimumDate(_defaultDate)
                                                    }
                                                }
                                            }

                                            Component.onCompleted:{
                                                if(typeof definitionExpression !== "undefined" && definitionExpression > ""){
                                                    let expr = definitionExpression
                                                    if(expr && typeof type !== "undefined" && type > "" && type === "date"){
                                                        //first split by operator and
                                                        var betweenIndx = expr.indexOf('BETWEEN')
                                                        if(betweenIndx > -1){
                                                            let values = expr.split('BETWEEN')[1]
                                                            let toval = values.split('AND')[1]

                                                            let toval_mod1 = toval.split('timestamp')[1]
                                                            let toval_mod2 = toval_mod1.substr(2,toval_mod1.length - 3)

                                                            let value_mod = new Date(toval_mod2).toLocaleString(Qt.locale(),"MM/dd/yyyy")
                                                            toDatevalue = value_mod

                                                            _toDate.text = new Date(toval_mod2).toLocaleString(Qt.locale(),Qt.DefaultLocaleShortDate).split(" ")[0]
                                                        } else{
                                                            let _toval = expr.split('<')[1]
                                                            if(_toval){
                                                                let _toval_mod1 = _toval.split('timestamp')[1]
                                                                let _toval_mod2 = _toval_mod1.substr(2,_toval_mod1.length - 3)
                                                                let _value_mod = new Date(_toval_mod2).toLocaleString(Qt.locale(),"MM/dd/yyyy")
                                                                toDatevalue = _value_mod
                                                                _toDate.text = new Date(_toval_mod2).toLocaleString(Qt.locale(),Qt.DefaultLocaleShortDate).split(" ")[0]
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.preferredHeight: 16 * app.scaleFactor
                                        Layout.fillWidth: true
                                    }
                                }
                            }

                            Item {
                                Layout.preferredHeight: app.scaleFactor
                                Layout.fillWidth: true

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.leftMargin: (index === expressionRepeater.model.count - 1) ? 0 : app.defaultMargin
                                    color: colors.blk_020
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    footer: Rectangle {
        height: 72 * app.scaleFactor
        width: parent.width
        color: "white"

        RowLayout {
            id: btnRow

            width: parent.width
            height: parent.height
            spacing: 0

            Item {
                Layout.fillHeight: true
                Layout.preferredWidth: 16 * app.scaleFactor
            }

            Button {
                id: resetButton

                Layout.preferredHeight: 48 * app.scaleFactor
                Layout.preferredWidth: (btnRow.width - 48 * app.scaleFactor)/2
                Layout.alignment: Qt.AlignVCenter
                Material.foreground: app.primaryColor
                Material.background: "white"
                Material.elevation: 0

                text: strings.reset

                contentItem: Text {
                    text: resetButton.text
                    font.family: "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                    font.pixelSize: 2 * app.baseUnit
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: app.primaryColor
                }

                onClicked: {
                    currentRadius = defaultRadius

                    // to reset search buffer distance
                    mapView.bufferDistance = currentRadius

                    for (var key in filterDic){
                        for (var i =0 ; i < filterDic[key].count; i++){
                            filterDic[key].get(i).isChecked = false
                            if(filterDic[key].get(i).field !== undefined){
                                filterDic[key].get(i).definitionExpression = ""
                            }
                        }
                    }

                    noOfFiltersApplied = 0
                    configuredFilters = []
                    if(Object.keys(userConfiguredDefinitionExpr).length > 0)
                        userConfiguredDefinitionExpr = {}
                    reset()
                    filterConfigChanged(filterDic,false)
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.preferredWidth: 16 * app.scaleFactor
            }

            Button {
                id: applyButton

                Layout.preferredHeight: 56 * app.scaleFactor
                Layout.preferredWidth: (btnRow.width - 48 * app.scaleFactor)/2
                Layout.alignment: Qt.AlignVCenter
                Material.foreground: "white"
                Material.background: app.primaryColor
                Material.elevation: 0

                text: noOfFiltersApplied > 0 ?`${strings.apply} ` + "(%L1)".arg(noOfFiltersApplied):strings.apply

                contentItem: Text {
                    text: applyButton.text
                    font.family: "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                    font.pixelSize: 2 * app.baseUnit
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: "white"
                }

                onClicked: {
                    if(!isBufferSearchEnabled)
                        notificationToolTipOnStart.contentText = ""

                    noOfFiltersApplied = 0
                    mapView.bufferDistance = currentRadius

                    for (var key in filterDic){
                        for (var i =0 ; i < filterDic[key].count; i++){
                            let exprId = filterDic[key].get(i).id
                            if(configuredFilters.includes(exprId)){
                                filterDic[key].get(i).isChecked = true
                                noOfFiltersApplied += 1
                            } else if(exprId in userConfiguredDefinitionExpr){
                                let userDefinitionExpr = userConfiguredDefinitionExpr[exprId]
                                if(userDefinitionExpr){
                                    filterDic[key].get(i).definitionExpression = userDefinitionExpr
                                    filterDic[key].get(i).isChecked = true
                                    noOfFiltersApplied += 1
                                }
                                else
                                    filterDic[key].get(i).isChecked = false
                            } else{
                                filterDic[key].get(i).isChecked = false
                            }
                        }
                    }

                    apply()

                    //now add the user configured expression to filterDic
                    if ( pageView.state === "anchorright" ){
                        filterConfigChanged(filterDic,false)
                    } else {
                        filterConfigChanged(filterDic,true)
                    }
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.preferredWidth: 16 * app.scaleFactor
            }
        }

        Rectangle {
            width: parent.width
            height: app.scaleFactor
            color: colors.blk_020
            anchors.top:parent.top
        }
    }

    Component {
        id: calendarDialogComponent
        Controls.CalendarDialog{
            property var attributesId
            primaryColor:app.primaryColor
            theme:Material.Light
            width: Math.min(filtersView.width - 2 * app.defaultMargin,300)
            height: pageView.state === "anchorbottom"?width * 1.5:width * 1.7
            x:app.isRightToLeft ? app.width -  filtersView.width + (filtersView.width - width)/2:(filtersView.width - width)/2
            y:pageView.state === "anchorbottom"?(app.height - height)/2 :(pageView.state === "anchortop"?(app.headerHeight + filtersView.height  - height)/2 : app.headerHeight + (filtersView.height  - height)/2)
            visible: false
            padding: 0
            topPadding: 0
            bottomPadding: 0
        }
    }
}
