import QtQuick 2.9
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.1
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0
import Esri.ArcGISRuntime 100.14

import QtPositioning 5.3
import QtSensors 5.3

//import "../Assets"
import "../widgets"
import "../controls"

Item {
    id: routeView

    property bool isInRouteMode: false
    property string distance: ""
    property string name: ""
    property real time: 0
    property var routeParameters: null
    property Point point: null
    property real selectedRouteMode
    property MapView mapView:null
    property Point startPoint: null
    property Point endPoint: null
    property string measureUnitsString:strings.km
    property int currentIndex: -1
    property url routeServiceUrl: "https://route-api.arcgis.com/arcgis/rest/services/World/Route/NAServer/Route_World"
    property var isRouteCredentialValid: true
    property var startIcon:"start.png"

    onIsInRouteModeChanged: {

    }

    ListView {
        id: routeDirectionView

        anchors.fill: parent
        model: directionsModel

        spacing: 0

        header: Label {
            id: totalDistanceText

            width: parent.width
            height: 40 * app.scaleFactor
            clip: true
            elide: Label.ElideRight
            wrapMode: Text.Wrap
            font.pixelSize: 12 * app.scaleFactor
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            leftPadding: 16 * app.scaleFactor
            rightPadding: 16 * app.scaleFactor

            color:  colors.blk_140
            text: distance > "" ? qsTr( "Total Distance: %L1 %2".arg(distance).arg(measureUnitsString) ) : (isRouteCredentialValid ? strings.compute_directions : strings.fail_get_route)

            Rectangle {
                height: app.scaleFactor
                width: parent.width
                anchors.bottom: parent.bottom
                color: "#EEEEEE"
            }
        }

        delegate: Item {

            width: parent ? parent.width: app.width
            height: 56 * app.scaleFactor

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Item {
                    Layout.preferredWidth: 16 * app.scaleFactor
                    Layout.fillHeight: true
                }

                Rectangle {
                    id:iconrect
                    Layout.preferredHeight: 20 * scaleFactor
                    Layout.preferredWidth: 20 * scaleFactor
                    color:directionManeuverType === 1?"cyan":"transparent"
                    radius:directionManeuverType === 1?iconrect.width * 0.5:0

                    Image {
                        id: directionIcon
                        source:getDirectionIcon(directionManeuverType) //directionsIcon
                        width: directionManeuverType === 1?16 * scaleFactor : 25 * scaleFactor
                        height: width
                        anchors.centerIn: parent
                        mipmap: true
                    }

                    ColorOverlay {
                        anchors.fill: directionIcon
                        source: directionIcon
                        color: directionManeuverType === 1 || directionManeuverType === 18 ? "transparent":"#848484"
                        //rotation: getIconRotation(directionManeuverType)
                    }

                }

                Item {
                    Layout.preferredWidth: 16 * app.scaleFactor
                    Layout.fillHeight: true
                }

                Label {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    text: directionText
                    elide: Label.ElideRight
                    wrapMode: Text.Wrap
                    font.pixelSize: 14 * app.scaleFactor
                    font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                    font.bold: index === routeView.currentIndex
                    color: colors.blk_140
                }

                Item {
                    visible: distanceText.visible

                    Layout.fillHeight: true
                    Layout.preferredWidth: 8 * app.scaleFactor
                }

                Label {
                    id: distanceText

                    visible: index !== 0 && index !== (directionsModel.count - 1)
                    Layout.preferredWidth: 56 * app.scaleFactor
                    Layout.fillHeight: true
                    clip: true
                    elide: Label.ElideRight
                    wrapMode: Text.Wrap
                    font.pixelSize: 12 * app.scaleFactor
                    font.bold: index === routeView.currentIndex
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight

                    color:  colors.blk_140
                    text: "%1 %2".arg(length).arg(measureUnitsString)
                }

                Item {
                    Layout.preferredWidth: 16 * app.scaleFactor
                    Layout.fillHeight: true
                }
            }

            Rectangle {
                height: app.scaleFactor
                width: parent.width - 48 * app.scaleFactor
                anchors.bottom: parent.bottom
                color: "#EEEEEE"
                anchors.leftMargin: 48 * app.scaleFactor
                anchors.left: parent.left
                visible: index !== (directionsModel.count - 1)
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    routeView.currentIndex = index;
                    highlightRouteSegment(geometry,directionManeuverType);
                }
            }
        }
    }

    // List model to containing current directions
    ListModel {
        id: directionsModel
    }

    // Route Task
    RouteTask {
        id: routeTask

        url: routeServiceUrl
        apiKey: app.routeApiKey
        credential: app.portal.credential

        // Request default parameters once the task is loaded
        onLoadStatusChanged: {
            if (loadStatus === Enums.LoadStatusLoaded) {
                routeTask.createDefaultParameters();
                isRouteCredentialValid = true;
            } else if(loadStatus === Enums.LoadStatusFailedToLoad){
                isRouteCredentialValid = false;
            }
        }

        // Store the resulting route parameters
        onCreateDefaultParametersStatusChanged: {
            if (createDefaultParametersStatus === Enums.TaskStatusCompleted) {
                routeParameters = createDefaultParametersResult;
                routeGraphicsOverlay.graphics.clear()
                routePartGraphicsOverlay.graphics.clear()
                setToDriveMode();
                getRoute(startPoint,endPoint)
            }
        }

        onSolveRouteStatusChanged: {
            if (solveRouteStatus === Enums.TaskStatusCompleted) {
                // Add the route graphic once the solve completes
                if(solveRouteResult !== null) displayRoute(solveRouteResult.routes[0]);
            }
        }
    }

    Component.onCompleted: {
        routeTask.load();
    }

    // Function to display route on map
    function displayRoute(route) {
//        mapView.removeAllGraphics();
//        var routeGraphic = ArcGISRuntimeEnvironment.createObject("Graphic", {geometry: route.routeGeometry});
//        mapView.routeGraphicsOverlay.graphics.append(routeGraphic);

//        mapView.showPin(route.stops[1].geometry, "", false);
        time = route.totalTime;
        distance = getNewDistance(route.totalLength, measureUnitsString);

        for(var i = 0; i < route.directionManeuvers.count; i++) {
            var dirObj = route.directionManeuvers.get(i)
            var length = 0
            var singleDistance = 0
            if(dirObj.length.toFixed(2) > length)
            {

                singleDistance = getNewDistance(dirObj.length, measureUnitsString);

            }
            else
                singleDistance = ""
            directionsModel.append({"directionText":dirObj.directionText,
                                          "length":singleDistance,
                                          "estimatedArrivalTime":dirObj.estimatedArrivalTime,
                                          "directionManeuverType":dirObj.directionManeuverType,
                                          "geometry":JSON.stringify(dirObj.geometry.json)})
        }
        var routeGraphic = ArcGISRuntimeEnvironment.createObject("Graphic", {geometry: route.routeGeometry});
        routeGraphicsOverlay.graphics.append(routeGraphic);

        var extent = GeometryEngine.combineExtentsOfGeometries([route.stops[0].geometry, route.stops[1].geometry, routeGraphicsOverlay.graphics.get(0).geometry]);
        mapView.setViewpointGeometryAndPadding(extent, 100);
//        toastMessage.reset();
//        directionsDrawer.open();
    }

    function getRoute(point1, point2) {
        /********** ****************************************************************** ***************/
//        if(app.clientId === null || app.clientSecret === null){
//            messageDialog.open();
//            return;
//        }
        /********************************************************************************************/
        if(app.isOnline) {
//            directionsDrawer.close();
//            minimizeDirectionsDrawer();
//            toastMessage.displayToast(strings.gettingRoute, true);
            directionsModel.clear();
//            mapView.removeRoute();
            time = "";
            distance = "";
//            mapView.locationDisplay.start();
//            var currentUserPoint = ArcGISRuntimeEnvironment.createObject("Point", {
//                                                                             x: mapView.lon,
//                                                                             y: mapView.lat,
//                                                                             spatialReference: Factory.SpatialReference.createWgs84()
//                                                                         });

            var start = ArcGISRuntimeEnvironment.createObject("Stop", {geometry: point1, name: "Origin"});
            var end = ArcGISRuntimeEnvironment.createObject("Stop", {geometry: point2, name: name});
//            mapView.showPin(point1);
//            mapView.showPin(point2)
            mapView.showStartAndEndPoint(point1, point2)
            routeParameters.returnDirections = true;
            routeParameters.returnRoutes = true;
            routeParameters.returnStops = true;
            routeParameters.setStops([start, end]);
            routeParameters.directionsDistanceUnits = Enums.UnitSystemMetric;
            // solve the route with the parameters
            routeTask.solveRoute(routeParameters);
        }
    }

    function setToDriveMode() {
        selectedRouteMode = 0;
        routeParameters.travelMode.type = "AUTOMOBILE";
        routeParameters.travelMode.impedanceAttributeName = "TravelTime";
        routeParameters.travelMode.timeAttributeName = "TravelTime";
    }

    function getNewDistance(distance, measureUnitsString){
        var newDistance = "";
        switch(measureUnitsString){
        case strings.m:
            newDistance =  parseFloat(distance.toFixed(2)).toLocaleString(Qt.locale());
            break;
        case strings.km:
            newDistance = parseFloat((distance*0.001).toFixed(2)).toLocaleString(Qt.locale());
            break;
        case strings.f:
            newDistance = parseFloat((distance*3.28083).toFixed(2)).toLocaleString(Qt.locale());
            break;
        case strings.mi:
            newDistance = parseFloat((distance*0.000621371).toFixed(2)).toLocaleString(Qt.locale());
            break;
        default:
            break;
        }
        return newDistance;
    }

    function getIconRotation(directionManeuverType) {

        var Icon_rotation = 0
        //var url directionsIcon1 = "../images/baseline_directions_white_48dp.png"

        switch(directionManeuverType.toString()) {
            //stop
        case "1":
            Icon_rotation = 0
            //directionsIcon_default = "../images/start.png"
            break
            //straight
        case "2":
            Icon_rotation = 0
            //directionsIcon_default = "../images/baseline_arrow_upward_white_48dp.png"
            break
            //bear left
        case "3":
            Icon_rotation = 180
            break
            //bear right
        case "4":
            Icon_rotation = 180
            //directionsIcon_default = "../images/baseline_subdirectory_arrow_right_white_48dp.png"
            break
            //left turn
        case "5":
            Icon_rotation = 180
            //directionsIcon_default = "../images/baseline_subdirectory_arrow_left_white_48dp.png"
            break
            //right turn
        case "6":
            Icon_rotation = 180
            //directionsIcon_default = "../images/baseline_subdirectory_arrow_right_white_48dp.png"
            break
            //sharp left
        case "7":
            Icon_rotation = 180
            //directionsIcon_default = "../images/baseline_subdirectory_arrow_left_white_48dp.png"
            break
            //sharp right
        case "8":
            Icon_rotation = 180
            //directionsIcon_default = "../images/baseline_subdirectory_arrow_right_white_48dp.png"
            break
            //U turn
        case "9":
            break
            //roundabout
        case "11":
            break
            //merge
        case "12":
            break
            //exit
        case "13":
            break
        default:
            break
        }
        return Icon_rotation;
    }

    function getDirectionIcon(directionManeuverType) {
        var directionsIcon_default = "../images/baseline_directions_white_48dp.png"
        //var url directionsIcon1 = "../images/baseline_directions_white_48dp.png"

        switch(directionManeuverType.toString()) {
            //stop
        case "1":
            directionsIcon_default = "../images/start.png"
            break
            //straight
        case "2":
            directionsIcon_default = "../images/straight-24.svg"
            //directionsIcon_default = "../images/baseline_arrow_upward_white_48dp.png"
            break
            //bear left
        case "3":
            directionsIcon_default = "../images/bear-left-24.svg"
            // directionsIcon_default = "../images/baseline_subdirectory_arrow_left_white_48dp.png"
            break
            //bear right
        case "4":
            directionsIcon_default = "../images/bear-right-24.svg"
            //directionsIcon_default = "../images/baseline_subdirectory_arrow_left_white_48dp.png"

            // directionsIcon_default = "../images/baseline_subdirectory_arrow_right_white_48dp.png"
            break
            //left turn
        case "26":
        case "5":
            directionsIcon_default = "../images/left-24.svg"
            //directionsIcon_default = "../images/baseline_subdirectory_arrow_right_white_48dp.png"
            //directionsIcon_default = "../images/baseline_subdirectory_arrow_left_white_48dp.png"
            break
            //right turn
        case "6":
        case "25":
            directionsIcon_default = "../images/right-24.svg"
            //directionsIcon_default = "../images/baseline_subdirectory_arrow_left_white_48dp.png"
            //directionsIcon_default = "../images/baseline_subdirectory_arrow_right_white_48dp.png"
            break
            //sharp left
        case "7":
            directionsIcon_default = "../images/sharp-left-24.svg"
            //directionsIcon_default = "../images/baseline_subdirectory_arrow_right_white_48dp.png"
            //directionsIcon_default = "../images/baseline_subdirectory_arrow_left_white_48dp.png"
            break
            //sharp right
        case "8":
            directionsIcon_default = "../images/sharp-right-24.svg"
            // directionsIcon_default = "../images/baseline_subdirectory_arrow_left_white_48dp.png"

            //directionsIcon_default = "../images/baseline_subdirectory_arrow_right_white_48dp.png"
            break
            //U turn
        case "9":
            directionsIcon_default = "../images/u-turn-24.svg"
            break
            //ferry
        case "10":
            //directionsIcon_default = "../images/u-turn-24.svg"
            break
            //roundabout
        case "11":
            directionsIcon_default = "../images/round-about-24.svg"
            break
            //merge
        case "12":
            directionsIcon_default = "../images/merge-24.svg"
            break
            //exit
        case "13":
            directionsIcon_default = "../images/exit-highway-left-24.svg"
            break
            //change of highway
        case "14":
            directionsIcon_default = "../images/highway-change-24.svg"
            break
            //straight at fork
        case "15":
            directionsIcon_default = "../images/fork-middle-24.svg"
            break
            //left at fork
        case "16":
            directionsIcon_default = "../images/fork-left-24.svg"
            break
            //right at fork
        case "17":
            directionsIcon_default = "../images/fork-right-24.svg"
            break
            //start
        case "18":
            directionsIcon_default =  `../images/${startIcon}` //"../images/pin.png"
            break;
            //bear right on a ramp
        case "21":
            directionsIcon_default = "../images/right_ramp.svg"
            break
            //bear left on a ramp
        case "22":
            directionsIcon_default = "../images/left_ramp.svg"
            break
        default:
            break
        }
        return directionsIcon_default;
    }

    function highlightRouteSegment(routePart,index) {
        routePartGraphicsOverlay.graphics.clear()
        if(routePart) {
            var jsonobj = JSON.parse(routePart);
            var geometry_obj;
            var routeSegmentGraphicsp = ArcGISRuntimeEnvironment.createObject("SpatialReference",{wkid:jsonobj.spatialReference.wkid});
            if(jsonobj.paths) {
                var polylinebuildr = ArcGISRuntimeEnvironment.createObject("PolylineBuilder",{spatialReference:routeSegmentGraphicsp});
                var _paths = jsonobj.paths[0];
                for(var p=0;p<_paths.length;p ++) {
                    polylinebuildr.addPointXY(_paths[p][0],_paths[p][1]);
                }
                geometry_obj = polylinebuildr.geometry
                var routeSegmentGraphic = ArcGISRuntimeEnvironment.createObject("Graphic", {geometry: geometry_obj });

                routePartGraphicsOverlay.graphics.append(routeSegmentGraphic);
                var extent = routePartGraphicsOverlay.extent
                mapView.setViewpointGeometryAndPadding(extent, 80);
            } else {
                if(index === 18) {
                    mapView.setViewpointGeometryAndPadding(startPoint.extent, 100);
                } else {
                    mapView.setViewpointGeometryAndPadding(endPoint.extent, 100);
                }

            }

        }
    }
}
