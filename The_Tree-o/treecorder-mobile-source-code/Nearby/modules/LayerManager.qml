import QtQuick 2.9

import Esri.ArcGISRuntime 100.14
import ArcGIS.AppFramework 1.0

Item {

    property MapView mapView:null
    property var layersSupportingAttachment:[]
    property var attachmentsRequested: 0
    property var currentIndex: -1
    property var  displayFieldName:"OBJECTID"
    property var featureLayers
    //<index,name>
    property var displayFieldNameDic:({})
    property var featureTableDic:({})
    // <objectid,index>
    property var featureIndexDic:({})
    property bool fetchingFeatures:false
    property bool fetchedLayers:false
    property bool fetchingLayers:false
    property bool fetchingDataForMedia:false
    property var layerId:""

    signal populateAttachmentCompleted()
    signal fetchFeaturesCompleted(var completed)
    signal fetchLayerNamesCompleted(var layersSupportingAttachment,var layerName,var lyrindx,var error)
    // signal populateIdentifyAttachmentCompleted(var attachmentsModel)

    QueryParameters {
        id: params
        whereClause: "1=1"
        // maxFeatures: 10  // setting this was causing not to return results for some webmaps
    }


    function getLayerNamesWithAttachmentsEnabled(_layerid)
    {
        layerId = _layerid
        if(!fetchingLayers)
        {
            layersSupportingAttachment = []
            featureTableDic = ({})
            featureLayers = mapView.map.operationalLayers
            loadNextLayer(mapView.map.operationalLayers.count - 1)
            fetchingLayers = true
        }
    }

    function loadNextLayer(lyrindx)
    {
        // if(lyrindx < featureLayers.count)
        if(lyrindx >= 0)
            loadLayer(lyrindx)
        else
        {
            fetchingLayers = false
            //var attachmentLyrs =  sortLayersByIndex()
            if(layerId > "")
            {
                getFeatures(layerId)
            }
            else
            {
                //                getFeatures(layersSupportingAttachment[0].layerId)

            }
        }
    }

    function populateLayerDictionaryForGroupLayer(grpLayer)
    {
       for(let k=0;k<grpLayer.subLayerContents.length;k++)
        {
            let sublyr = grpLayer.subLayerContents[k]
            if(sublyr.subLayerContents.length)
                populateLayerDictionaryForGroupLayer(sublyr)
            else
            {
                populateLayerDictionary(sublyr)
            }
        }
    }

    function loadLayer(lyrindx)
    {
        var featLyr = featureLayers.get(lyrindx)
        if(featLyr.loadStatus === Enums.LoadStatusLoaded)
        {
          if(featLyr.objectType === "GroupLayer")
          populateLayerDictionaryForGroupLayer(featLyr)
          else
            populateLayerDictionary(featLyr)
          loadNextLayer(lyrindx - 1)
        }
        else
        {

            featLyr.loadStatusChanged.connect(function(){
                if(featLyr.loadStatus === Enums.LoadStatusLoaded)
                {

                    populateLayerDictionary(featLyr)
                    loadNextLayer(lyrindx - 1)

                }
                else if(featLyr.loadStatus === Enums.LoadStatusFailedToLoad)
                {
                    console.error(featLyr.name," failed to load")
                }
            }
            )

            featLyr.load()
        }


    }

    function populateLayerDictionary(featLyr)
    {
        const featTable = featLyr.featureTable

        if(featTable)
        {
            try{
                featureTableDic[featLyr.name] = featTable
                if(featTable.hasAttachments){
                    let existinglyr = layersSupportingAttachment.filter(lyr => lyr.name === featLyr.name)

                    if(!existinglyr.length > 0)
                        layersSupportingAttachment.push(featLyr)

                }
            }
            catch(ex)
            {
                console.error(ex)
            }
        }
    }

    function getLayerById (id) {
        if(!featureLayers)
            featureLayers = mapView.map.operationalLayers
        let layerList = featureLayers

        for (var i=0; i<layerList.count; i++) {
            let layer = layerList.get(i)
            if(layer && layer.objectType === "GroupLayer")
            {
                let sublyr =   getLyrFromGroupLayer(layer,id)
                return sublyr
            }
            else
            {

                if (!layer) continue
                if (layer.layerId === id) {
                    return layer
                }
            }
        }
    }

    function getLyrFromGroupLayer(layer,id)
    {

        for(let k=0;k<layer.subLayerContents.length;k++)
        {
            let sublyr = layer.subLayerContents[k]
            if(sublyr.subLayerContents.length)
                getLyrFromGroupLayer(sublyr,id)
            else
            {
                if (sublyr.layerId === id) {

                    return sublyr
                }
            }
        }



    }

    function getFeatures(layerId)
    {
        if(!fetchingFeatures)
        {
            fetchingFeatures=true
            let layerfound = false

            for(let k=0;k<featureLayers.count;k++)
            {
                const featLyr = featureLayers.get(k)
                if(featLyr.layerId.toLowerCase() === layerId.toLowerCase())
                {
                    const sortOrder = app.viewerJsonDict[app.currentAppId].order
                    const attachmentLayers = app.viewerJsonDict[app.currentAppId].attachmentLayers
                    const displayFieldName = getDisplayFieldName(attachmentLayers,k)
                    let layername = featLyr.name
                    fetchLayerNamesCompleted(layersSupportingAttachment,featLyr.name,k,false)
                    getFeaturesForLayer(featLyr,layername,0,sortOrder,displayFieldName)
                    layerfound = true
                    break
                }


            }
            if(!layerfound)
            {
                fetchingFeatures=false

                fetchLayerNamesCompleted(layersSupportingAttachment,null,null,true)
            }
        }
    }


    function getDisplayFieldName(attachmentLayers,lyrindx)
    {
        let displayfieldName = "OBJECTID"
        let attachmentlyrsArray = []
        if(attachmentLayers){
            if(attachmentLayers.layers)
                attachmentlyrsArray = attachmentLayers
            else
                attachmentlyrsArray = JSON.parse(attachmentLayers)
        }
        const oplyr = mapView.map.operationalLayers.get(lyrindx)
        for(let k=0;k<attachmentlyrsArray.length;k++)
        {
            const lyr = attachmentlyrsArray[k]
            if(lyr.id === oplyr.layerId)
            {
                if(lyr.fields && lyr.fields.length > 0)
                    displayfieldName = lyr.fields[0]
                break

            }

        }

        return displayfieldName
    }


    function getFeaturesForLayer(featLyr,lyrname,resultOffset,sortOrder,displayFieldName)
    {

        try{
            if(featLyr.loadStatus === Enums.LoadStatusLoaded)
            {

                queryFeatureTable(featLyr,resultOffset,sortOrder,displayFieldName)

            }
            else
            {
                featLyr.loadStatusChanged.connect(function(){
                    if(featLyr.loadStatus === Enums.LoadStatusLoaded)
                    {
                        //displayFieldName = featLyr.featureTable.layerInfo.displayFieldName ? featLyr.featureTable.layerInfo.displayFieldName : "OBJECTID"

                        queryFeatureTable(featLyr,resultOffset,sortOrder,displayFieldName)


                    }
                }
                )
                featLyr.load()
            }
        }
        catch(ex)
        {
            console.error(ex)
        }

    }

    function queryFeatureTable(featLyr,resultOffset,sortOrder,displayFieldName)
    {
        try{
            let definitionExpression = featLyr.definitionExpression
            if(app.definitionExpressionDic[featLyr.name])
            {
                definitionExpression = app.definitionExpressionDic[featLyr.name]
                featLyr.definitionExpression = definitionExpression
            }

            let _sortOrder = Enums.SortOrderAscending
            if(sortOrder === "DESC")
                _sortOrder = Enums.SortOrderDescending


            const orderby = ArcGISRuntimeEnvironment.createObject("OrderBy",{"fieldName":displayFieldName,"sortOrder":_sortOrder})
            params.resultOffset = resultOffset

            params.orderByFields = [orderby]
            if(definitionExpression)
                params.whereClause = definitionExpression
            else
                params.whereClause = "1=1"
            const featureTable = featLyr.featureTable//featureTableDic[index]
            queryServiceTable(featureTable,featLyr.layerId,featLyr.name,"",params,displayFieldName)
        }
        catch(ex)
        {
            console.error(ex)
        }
    }


    function queryServiceTable (serviceTable,layerId, layerName, txt,featureParameters,displayFieldName) {

        //serviceTable.queryFeaturesStatusChanged.connect(processQueryResults)

        serviceTable.queryFeaturesStatusChanged.connect (function () {
            if(fetchingFeatures)
            {
                if(serviceTable)
                {
                    if (serviceTable.queryFeaturesStatus === Enums.TaskStatusCompleted) {

                        if (serviceTable.queryFeaturesResult) {
                            let recCount = 0
                            mapView.featuresModel.clearAll()
                            //var searchFields = searchFieldNames[serviceTable.serviceLayerId]
                            for(let k=0;k<serviceTable.queryFeaturesResult.iterator.features.length;k++){
                                const feature = serviceTable.queryFeaturesResult.iterator.features[k],
                                attributeNames = feature.attributes.attributeNames
                                let search_attr_val = ""

                                mapView.featuresModel.append({
                                                                 "layerName": layerName,
                                                                 "search_attr": search_attr_val,
                                                                 "extent": feature.geometry,
                                                                 "showInView": false,
                                                                 "initialIndex": mapView.featuresModel.features.length,
                                                                 "hasNavigationInfo": false,
                                                                 "numericaldistance":0,
                                                                 "distance":"0",
                                                                 "layerId":layerId,
                                                                 "layerUrl":serviceTable.url.toString()
                                                             })
                                let featObj = {}
                                featObj.feature = feature

                                mapView.featuresModel.features.push(featObj)

                            }
                            let attachmentgrps =  getAttachments(serviceTable,featureParameters.whereClause)
                            attachmentgrps.then(groups => {
                                                    // var onlyDisplayFeaturesWithAttachmentsIsEnabled = app.viewerJsonDict[app.currentMapId].onlyDisplayFeaturesWithAttachmentsIsEnabled
                                                    populateThumbUrlForFeatures1(0,groups)

                                                })

                            if (serviceTable.queryFeaturesResult.iterator.features.length === 0)
                            {
                                fetchingFeatures=false

                                fetchFeaturesCompleted(true)
                            }

                        }
                        else
                        {
                            fetchingFeatures=false

                            fetchFeaturesCompleted(true)
                        }

                    }
                }
            }

        })
        if(serviceTable.definitionExpression === featureParameters.whereClause)
            featureParameters.whereClause="1=1"

        //serviceTable.queryFeatures(featureParameters)
        serviceTable.queryFeaturesWithFieldOptions(featureParameters,Enums.QueryFeatureFieldsLoadAll)
    }




    function getAttachments(serviceTable,definitionExpression)
    {
        return new Promise((resolve, reject) => {

                               var layerUrl = serviceTable.url.toString()
                               var token = portalSearch.token
                               if(!token && app.authChallenge)
                               token = app.authChallenge.proposedCredential.token
                               portalSearch.searchAttachments(definitionExpression,layerUrl,resolve,token)

                           })

    }


    function populateThumbUrlForFeatures1(featureindex,groups)
    {
        featureIndexDic =({})
        loadNextFeature(featureindex,groups)

    }

    function loadNextFeature(featureindex,groups)
    {
        try{
            while(featureindex < mapView.featuresModel.features.length)
            {
                let featObj = mapView.featuresModel.features[featureindex]
                const feature = featObj.feature

                featObj = getAttachmentUrlsFromJson(groups,featObj)
                mapView.featuresModel.features[featureindex] = featObj
                const objectid = feature.attributes.attributeValue("objectid")
                featureIndexDic[objectid] = featureindex
                featureindex = featureindex+1


            }

            fetchingFeatures = false
            fetchFeaturesCompleted(true)

        }
        catch(ex)
        {
            fetchingFeatures = false
            fetchFeaturesCompleted(true)
        }
    }


    function loadFeature(featureindex,groups)
    {

        let featObj = mapView.featuresModel.features[featureindex]
        const feature = featObj.feature

        featObj = getAttachmentUrlsFromJson(groups,featObj)
        mapView.featuresModel.features[featureindex] = featObj
        const objectid = feature.attributes.attributeValue("objectid")
        featureIndexDic[objectid] = featureindex
        //fetchFeaturesCompleted(false)
        loadNextFeature(featureindex+1,groups)

    }

    function getAttachmentUrlsFromJson(groups,featObj)
    {
        if(mapView)
        {
            var layerurl = mapView.featuresModel.get(0).layerUrl
            var objectid = featObj.feature.attributes.attributeValue("objectid")
            var attachmentinfos = getAttachmentFromGrp(groups.attachmentGroups,objectid)
            if(attachmentinfos)
            {
                var attachments = []

                for(var k=0;k<attachmentinfos.length;k++) {
                    const attachment = attachmentinfos[k]
                    const contentType = attachment.contentType.split('/')[0]
                    let attachmentObj = {}
                    attachmentObj.size = attachment.size
                    attachmentObj.name = attachment.name
                    attachmentObj.exifInfo = attachment.exifInfo

                    if(contentType === "image"){
                        const attachmentid = attachment.id
                        let attachmentURL = layerurl + "/"+ objectid + "/attachments/"+ attachmentid
                        if(portalSearch.token)
                            attachmentURL = attachmentURL + "?w=200&token="+ portalSearch.token
                        else
                            attachmentURL = attachmentURL + "?w=200"

                        attachmentObj.attachmentUrl = attachmentURL
                        attachmentObj.contentType = attachment.contentType
                        attachmentObj.pictureid = objectid + "_" + attachmentid
                        if(attachments.length < maxAttachmentCount)
                            attachments.push(attachmentObj)
                        if(!featObj.thumbUrl)
                            featObj.thumbUrl = attachmentURL

                        const name = featObj.feature.attributes.attributeValue("name")
                        featObj.name = name
                        featObj.contentType = attachment.contentType

                    }
                    else
                    {
                        const _attachmentid = attachment.id
                        const _attachmentURL = layerurl + "/"+ objectid + "/attachments/"+ _attachmentid
                        attachmentObj.attachmentUrl = _attachmentURL
                        attachmentObj.contentType = attachment.contentType
                        attachmentObj.pictureid = objectid + "_" + _attachmentid
                        if(attachments.length < maxAttachmentCount)
                            attachments.push(attachmentObj)
                        const name1 = featObj.feature.attributes.attributeValue("name")
                        featObj.name = name1
                        featObj.contentType = attachment.contentType

                    }

                }
                featObj.attachments = attachments
            }
            else
            {
                featObj.thumbUrl=""
                featObj.contentType = ""
                featObj.attachments = []

            }
        }
        return featObj
    }


    function getAttachmentFromGrp(groups,objectid){
        let attachmentgrp = groups.filter(function (grp) {
            return grp.parentObjectId === objectid
        });
        if(attachmentgrp.length > 0)
            return attachmentgrp[0].attachmentInfos
        else
            return null
    }

    function getFilterOperatorFromConfig(layerId){
        for(let k = 0; k < mapView.filterConfigModel.count; k++){
            let config = mapView.filterConfigModel.get(k)

            if(config.layerId === layerId)
                return config.operator
        }
        return "OR"
    }

    function getFieldValuesDic(layerId, fldname){
        let lyr = getLayerById(layerId)
        var layerServiceTable = lyr.featureTable
        if(layerServiceTable)
        mapViewerCore.getFieldValues(lyr,layerServiceTable,layerServiceTable.fields,fldname)
    }
}
