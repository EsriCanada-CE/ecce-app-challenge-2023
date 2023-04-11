import QtQuick 2.9

import Esri.ArcGISRuntime 100.14
import ArcGIS.AppFramework 1.0

Item {
    property MapView mapView:null
    property var mapAreasModel:ListModel{}
    property var mapAreasCount:0
    property var mapAreaGraphicsArray:[]
    property var existingmapareas:null
    property var mapAreaslst:[]
    property var portalItem
    property var mapProperties: Object
    property Geodatabase offlineGdb:null
    property var  offlineSyncTask:null

    signal mapSyncCompleted(string title)
    
    function drawMapAreas()
    {
        mapView.polygonGraphicsOverlay.graphics.clear()
        mapAreaGraphicsArray.forEach((graphic)=>{

                                                 mapView.polygonGraphicsOverlay.graphics.append(graphic)

                                             }
                                             )

        mapView.setViewpointGeometryAndPadding(mapView.polygonGraphicsOverlay.extent,100)

    }

    function highlightMapArea(index){
        var graphic = mapAreaGraphicsArray[index]

        mapView.setViewpointCenterAndScale(graphic.geometry.extent.center,mapView.scale)
        var graphicList = []

        graphicList.push(graphic)

        mapView.polygonGraphicsOverlay.clearSelection()
        mapView.polygonGraphicsOverlay.selectGraphics(graphicList)
    }

    function displayLayersFromGeodatabase()
    {
        var gdbfilepath = ""
        if(Qt.platform.os === "windows")
            gdbfilepath = "file:///" + mapProperties.fileUrl + mapProperties.gdbpath
        else
            gdbfilepath = "file://" + mapProperties.fileUrl + mapProperties.gdbpath

        var dbfilePath = gdbfilepath
        offlineGdb = ArcGISRuntimeEnvironment.createObject("Geodatabase",{path:dbfilePath})
        offlineGdb.loadStatusChanged.connect(function(){
            if(offlineGdb.loadStatus === Enums.LoadStatusLoaded)
            {
                for(var i = 0; i<offlineGdb.geodatabaseFeatureTables.length;i++)
                {
                    var featureTable = offlineGdb.geodatabaseFeatureTables[i]
                    var featureLayer = ArcGISRuntimeEnvironment.createObject("FeatureLayer")
                    featureLayer.featureTable = featureTable
                    mapView.map.operationalLayers.append(featureLayer)

                }
                if(mapProperties.extent)
                    mapView.setViewpointGeometryAndPadding(mapProperties.extent,0)

                mapView.updateLayers()

            }

        }
        )
        offlineGdb.load()
    }

    function updateMapAreaInfo () {
        var fileName = "mapareasinfos.json"
        var mapAreafileName = "mobile_map.marea"
        var fileContent = {"results": []}
        var mapAreaFileContent = ""
        var storageBasePath = offlineMapAreaCache.fileFolder.path + "/"
        //first read the mapareasInfos.json file

        //var mapareacontainerpath = [storageBasePath,mapPortalItemId].join("/")
        let fileInfoMapAreaContainer = AppFramework.fileInfo(storageBasePath)
        let mapAreaContainerFolder = fileInfoMapAreaContainer.folder
        if (mapAreaContainerFolder.fileExists(fileName)) {
            fileContent = mapAreaContainerFolder.readJsonFile(fileName)
        }
        //filter the downloaded maparea from contents
        fileContent.results.map(item => item.id )
        const newArray = fileContent.results.map(item => {
                                                     if(item.id === portalItem.id)
                                                     {
                                                         //var ts = Math.round((new Date()).getTime() / 1000)
                                                         var today = new Date();
                                                         var date = (today.getMonth()+1) + '/'+ today.getDate()+'/'+ today.getFullYear();
                                                         item.modifiedDate = date
                                                     }

                                                 }
                                                 );


        //update the jsonfile
        mapAreaContainerFolder.writeJsonFile(fileName, fileContent)
        portalSearch.populateLocalMapPackages()

    }

    function checkForUpdates()
    {
        offlineSyncTask = ArcGISRuntimeEnvironment.createObject("OfflineMapSyncTask",{map:mapView.map})
        offlineSyncTask.loadStatusChanged(getError)
        var mapUpdatesInfoTaskId =  offlineSyncTask.checkForUpdates()

        offlineSyncTask.checkForUpdatesStatusChanged.connect(function()
        {
            getUpdates(offlineSyncTask)
        }
        )

    }
    function updateMyMapArea(portalItem)
    {

        //create the map
        var newMap = ArcGISRuntimeEnvironment.createObject("Map",{ item: portalItem });

        syncGeodatabase(portalItem.title,newMap)
        //if updates available then download maparea
    }

    function syncGeodatabase(title,myMap)
    {
        var offlineSyncTask = ArcGISRuntimeEnvironment.createObject("OfflineMapSyncTask",{map:myMap})

        //check for updates
        offlineSyncTask.loadStatusChanged(getError)

        offlineSyncTask.loadErrorChanged(getError)
        //need to test below after updates
        var mapUpdatesInfoTaskId =  offlineSyncTask.checkForUpdates()

        offlineSyncTask.checkForUpdatesStatusChanged.connect(function()
        {
            getUpdates(offlineSyncTask,title)
        }
        )


    }

    function getUpdates(offlineSyncTask,title)
    {
        var updatesInfo = offlineSyncTask.checkForUpdatesResult
        if(offlineSyncTask.checkForUpdatesStatus === Enums.TaskStatusCompleted)
        {
            var isDownloadAvailable = updatesInfo.downloadAvailability
            var isUploadAvailable = updatesInfo.uploadAvailability
            if(isUploadAvailable !== Enums.OfflineUpdateAvailabilityNone || isDownloadAvailable !== Enums.OfflineUpdateAvailabilityNone)
            {
                applyUpdates(offlineSyncTask)
            }
            else
            {
                toastMessage.show(qsTr("There are no updates available at this time."))
                //mapareasbusyIndicator.visible = false
                mapSyncCompleted(title,false)
            }
        }
    }

    function applyUpdates(offlineSyncTask)
    {
        var mapsyncTaskId  = offlineSyncTask.createDefaultOfflineMapSyncParameters()
        offlineSyncTask.createDefaultOfflineMapSyncParametersStatusChanged.connect(function(){
            getParameters(offlineSyncTask)
        }
        )
    }

    function getParameters(offlineSyncTask)
    {
        if(offlineSyncTask.createDefaultOfflineMapSyncParametersStatus === Enums.TaskStatusCompleted)
        {
            var defaultMapSyncParams = offlineSyncTask.createDefaultOfflineMapSyncParametersResult
            defaultMapSyncParams.preplannedScheduledUpdatesOption = Enums.PreplannedScheduledUpdatesOptionDownloadAllUpdates

            var offlinemapSyncJob = offlineSyncTask.syncOfflineMap(defaultMapSyncParams)
            offlinemapSyncJob.start()

            offlinemapSyncJob.statusChanged.connect(function(){
                updateMap(offlinemapSyncJob)
            }
            )

        }
    }
    function showDownloadCompletedMessage(message,body)
    {
        toastMessage.isBodySet = true
       toastMessage.display(message,body)
    }

    function showDownloadFailedMessage(message,body)
    {
        if(message > "")
            messageDialog.show(qsTr("Download Failed"),body +": " + message)
    }

    function updateMap(offlinemapSyncJob)
    {
        var status = offlinemapSyncJob.jobStatus
        if(offlinemapSyncJob.jobStatus === Enums.JobStatusSucceeded)
        {
            var syncJobResult =  offlinemapSyncJob.result
            if(!syncJobResult.hasErrors)
            {
                toastMessage.show(qsTr("Offline map area syncing completed."))
                //mapareasbusyIndicator.visible = false
                mapSyncCompleted(title,false)
                updateMapAreaInfo()

            }
            else
            {
                var errorMsg = syncJobResult.layerResults[0].syncLayerResult.error.additionalMessage
            }
        }
    }
    function checkExistingAreas()
    {
        var fileName = "mapareasinfos.json"
        var fileContent = null

        if (offlineMapAreaCache.fileFolder.fileExists(fileName)) {
            fileContent = offlineMapAreaCache.fileFolder.readJsonFile(fileName)

            var results = fileContent.results
            existingmapareas = results.filter(item => item.mapid === portalItem.id)
        }
        return existingmapareas

    }
}
