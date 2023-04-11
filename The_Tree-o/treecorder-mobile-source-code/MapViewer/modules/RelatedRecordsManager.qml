import QtQuick 2.9

import Esri.ArcGISRuntime 100.14
import ArcGIS.AppFramework 1.0

Item {
     property MapView mapView:null

    /*
    function populateRelatedRecords(features)
    {

        if(features.length > 0)
        {

            var feature = features.pop()
            var promiseToFindRelatedRecord = fetchRelatedRecords(feature)
            promiseToFindRelatedRecord.then(isFetched => {
                                                populateRelatedRecords(features)
                                            })

        }
        else
        {
            identifyInProgress = false

            identifyProperties.computeCounts()
            showIdentifyPanel()
            if (mapView.identifyProperties.features.length) mapView.identifyProperties.highlightFeature(0, true)

        }


    }
    */
    //promise
    function fetchRelatedFeature(feat)
    {
        return new Promise((resolve, reject) => {

                               if (feat.loadStatus === Enums.LoadStatusLoaded)
                               {
                                   processRelatedFeature(feat,resolve)
                               }
                               else
                               {
                                   feat.loadStatusChanged.connect(function(){
                                       if (feat.loadStatus === Enums.LoadStatusLoaded) {
                                           processRelatedFeature(feat,resolve)

                                       }

                                   })

                                   feat.load();
                               }

                           })
    }


    function processRelatedFeature(feat,resolve)
    {
        var fields = feat.featureTable.fields
        var serviceLayerName =  feat.featureTable.layerInfo.serviceLayerName
        var displayFieldName = feat.featureTable.layerInfo.displayFieldName ? feat.featureTable.layerInfo.displayFieldName : "OBJECTID"

        var featureElement = {}
        featureElement["serviceLayerName"] = serviceLayerName
        featureElement["fields"] = []
        featureElement["displayFieldName"] = ""
        featureElement["geometry"] = feat.geometry
        var j = feat.attributes.attributesJson;
        for (var key in j) {
            if (j.hasOwnProperty(key)) {
                var fieldobj = {}
                var label = app.getFieldAlias(fields,key)
                fieldobj["FieldName"] = label
                var fieldVal = String(j[key])
                if(fieldVal)
                {
                    var codedFieldValue = app.getCodedValue(fields,key,fieldVal)
                    //format the value
                    var _fieldVal = app.getFormattedFieldValue(codedFieldValue)


                    fieldobj["FieldValue"] = _fieldVal.toString()//fieldVal.toString()

                }
                else
                    fieldobj["FieldValue"] = "null"

                if(key.toUpperCase() === displayFieldName.toUpperCase())
                {
                    if(fieldVal)
                        featureElement["displayFieldName"] = fieldVal.toString()
                    else
                    {
                        fieldVal = feat.attributes.attributeValue("OBJECTID")

                        featureElement["displayFieldName"] = fieldVal.toString()
                    }

                }

                if(app.isFieldVisible(fields,key))
                    featureElement["fields"].push(fieldobj)
            }
        }

        resolve(featureElement)

    }

    function processRelatedFeaturesRecords(relfeatures,relatedFeaturesList,resolve)
    {
        var received = true
        if(relfeatures.length > 0)
        {

            var feature = relfeatures.pop()
            var promiseToloadRelatedFeature = fetchRelatedFeature(feature)
            promiseToloadRelatedFeature.then(featureElement => {
                                                 relatedFeaturesList.push(featureElement)
                                                 processRelatedFeaturesRecords(relfeatures,relatedFeaturesList,resolve)
                                             })

        }
        else
        {

            if(received)
            {
                mapView.identifyProperties.relatedFeatures.push(relatedFeaturesList)
                received = false
                resolve(true)
            }
        }
    }

    //promise
    function fetchRelatedRecords(feature)
    {
        var fetched = false
        return new Promise((resolve, reject) => {

                               var _relatedRecs = {}
                               var selectedTable = feature.featureTable

                               if(selectedTable.queryRelatedFeaturesStatusChanged)
                               {
                                   selectedTable.queryRelatedFeaturesStatusChanged.connect(function(){
                                       if (selectedTable.queryRelatedFeaturesStatus === Enums.TaskStatusCompleted)
                                       {
                                           if(!fetched)
                                           {
                                               var featuresToProcess = []
                                               var relatedFeatureQueryResultList = selectedTable.queryRelatedFeaturesResults
                                               var relatedFeaturesList = []
                                               var noOfRelatedFeatureQueryResultToprocess = relatedFeatureQueryResultList.length
                                               for (var i=0;i < relatedFeatureQueryResultList.length; i++)
                                               {
                                                   var iter = relatedFeatureQueryResultList[i].iterator

                                                   for(var k = 0; k < iter.features.length;k++)
                                                   {
                                                       var feat = iter.features[k]
                                                       featuresToProcess.push(feat)

                                                   }

                                               }

                                               processRelatedFeaturesRecords(featuresToProcess,relatedFeaturesList,resolve)
                                               fetched = true
                                           }

                                       }
                                       else if(selectedTable.queryRelatedFeaturesStatus === Enums.TaskStatusErrored) {
                                           resolve(true)
                                           if(error)
                                               console.error("error:", error.message, error.additionalMessage);

                                       }
                                   }
                                   )
                                   //selectedTable.queryRelatedFeaturesWithFieldOptions(feature,{},Enums.QueryFeatureFieldsLoadAll)
                                   selectedTable.queryRelatedFeatures(feature)


                               }

                           })

    }



}
