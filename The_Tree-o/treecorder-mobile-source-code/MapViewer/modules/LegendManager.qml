import QtQuick 2.9

import Esri.ArcGISRuntime 100.14
import ArcGIS.AppFramework 1.0

Item {
      property MapView mapView:null
    property var uidRequested:[]


    function procLayers (layers, callback) {
        if (!layers) layers = mapView.map.operationalLayers

        var count = layers.count || layers.length
        var rootlyrindx = -1

        for (var i=count; i--;) {
            try {
                var   layer = mapView.map.operationalLayers.get(i)
            } catch (err) {
                layer = layers[i]
            }
            if (!layer)
            {
                continue
            }
            rootlyrindx = i

            addLayerToContentAndFetchLegend(layer,rootlyrindx)

        }
        //sortLegendContent()

    }

    function processSubLayers(layer,subLayers,rootLayerName,rootlyrindx,subLyrIds)
    {
        if(!subLyrIds)
            subLyrIds = []
        if(layer.subLayerContents.length > 0)
        {
            for(var x=layer.subLayerContents.length;x--;){

                var sublyr = layer.subLayerContents[x]
                if(sublyr)
                {

                    if(sublyr !== null)
                    {
                        if(sublyr.subLayerContents && sublyr.subLayerContents.length > 0)
                        {
                            for(var ks = sublyr.subLayerContents.length; ks--;)
                            {

                                processSubLayers(sublyr.subLayerContents[ks],subLayers,rootLayerName,rootlyrindx,subLyrIds)
                            }
                        }
                        else{
                            var lyrname = sublyr.name
                            subLayers.push(lyrname)
                            subLyrIds.push(sublyr.id)
                            fetchLegendInfos(sublyr, x,layer.name,rootLayerName,rootlyrindx)
                        }
                    }

                }

            }
        }
        else
        {
            subLayers.push(layer.name)
            subLyrIds.push(layer.id)
            fetchLegendInfos(layer, layer.sublayerId,rootLayerName,rootlyrindx)


        }
        return {subLayers,subLyrIds}
        //return subLayers
    }

    /*
      if it is a group layer then the rootlyrindx is the index of the group layer
      If it is not a group layer then the rootlayerName is empty and the rootLyrIndex
      is same as the layer index

      */
    function addLayerToContentAndFetchLegend(layer,rootlyrindx)
    {

        var subLayers = []
        var subLyrIds = []


        if(layer.loadStatus === Enums.LoadStatusLoaded)
        {

            if(layer.subLayerContents.length > 0)
            {
                for(var x=layer.subLayerContents.length;x--;){
                    var sublyr = layer.subLayerContents[x]
                    if(sublyr)
                    {
                        if(sublyr.subLayerContents && sublyr.subLayerContents.length > 0)
                        {
                            var obj = processSubLayers(layer,subLayers,layer.name,rootlyrindx,subLyrIds)
                            subLayers = obj.subLayers
                            subLyrIds = obj.subLyrIds

                        }
                        else{
                            var lyrname = sublyr.name
                            subLayers.push(lyrname)
                            subLyrIds.push(sublyr.id)
                            fetchLegendInfos(sublyr, x,layer.name,rootlyrindx)
                        }

                    }

                }


            }
            else
            {
                fetchLegendInfos(layer, rootlyrindx,"",rootlyrindx)
            }
            addToContentList(layer,subLayers,subLyrIds)

        }
        else
        {

            loadLayerAndPopulateLegend(layer,rootlyrindx)
        }
    }

    function loadLayer(layer,lyrindex)
    {
        var subLayers = []
        var subLyrIds = []


        if(layer.loadStatus === Enums.LoadStatusLoaded){
            if(layer.subLayerContents.length > 0)
            {
                for(var indx in layer.subLayerContents){
                    if(layer.subLayerContents[indx] !== null)
                    {
                        if(layer.subLayerContents[indx].subLayerContents && layer.subLayerContents[indx].subLayerContents.length > 0)
                        {
                            for(var ks = layer.subLayerContents[indx].subLayerContents.length; ks--;)
                            {
                                // subLayers = processSubLayers(layer.subLayerContents[indx].subLayerContents[ks],subLayers,layer.name,lyrindex)
                                var obj = processSubLayers(layer.subLayerContents[indx].subLayerContents[ks],subLayers,layer.name,lyrindex,subLyrIds)
                                subLayers = obj.subLayers
                                subLyrIds = obj.subLyrIds
                            }
                        }
                        else
                        {
                            var lyrname = layer.subLayerContents[indx].name
                            var lyrid = layer.subLayerContents[indx].id
                            subLayers.push(lyrname)
                            subLyrIds.push(lyrid)
                            var sublyr = layer.subLayerContents[indx]

                            fetchLegendInfos(sublyr, indx,layer.name,lyrindex)
                        }
                    }

                }
            }
            else
            {
                //mapView.fetchLegendInfos(layer, lyrindex,"",lyrindex)
                legendManager.fetchLegendInfos(layer, lyrindex,"",lyrindex)
            }
            addToContentList(layer,subLayers,subLyrIds)

        }


    }

    /*
      added a timer to resolve the crash issue for some mmpk using 3D symbols

      */
    Timer {
        id: timer
    }

    function loadLayerAndPopulateLegend(layer,lyrindex)
    {

        var subLayers = []
        var subLyrIds = []
        layer.onLoadStatusChanged.connect(function () {

            timer.interval = 100
            timer.repeat = false
            timer.triggered.connect(function () {
                loadLayer(layer,lyrindex)
            })

            timer.start();

        })
    }
    /*
      This is modified in version 4.1 to resolve the bug in earlier version
      where some of the layers were duplicated in the content.

      */

    function addToContentList(layer,sublayers,subLyrIds)
    {

        var sublayersString = sublayers.join(',')
        var sublayersTxt = sublayers.join(',')
        var sublayerIds=""
        if(subLyrIds)
            sublayerIds = subLyrIds.join(',')

        if(!find(mapView.contentListModel,layer.name))
        {
            var isGroupLayer = sublayers.length > 0?true:false

            var isVisibleAtScale = isGroupLayer?sublayers.length > 0?true:false:layer.isVisibleAtScale(mapView.mapScale)
            var lyrname = layer.name
            mapView.contentListModel.append({
                                                "checkBox": layer.visible,
                                                "lyrname":lyrname,
                                                "layerId": layer.layerId,
                                                "sublayers":sublayersString,
                                                "isVisibleAtScale":isVisibleAtScale,
                                                "isGroupLayer":isGroupLayer,
                                                "sublayerIds":sublayerIds,
                                                "sublayersTxt":sublayersTxt
                                            })




            //sort the list when all the layers has been added to the contentlist
            if(mapView.map)
            {
                if(mapView.map.operationalLayers.count === mapView.contentListModel.count)
                    sortLegendContentByLyrIndex()
            }
        }
    }

    function find(model,layername)
    {
        for(var i=0;i<model.count;i++)
        {
            var item = model.get(i)
            if(item.lyrname === layername)
                return true
        }
        return false
    }


    function processSubLayerLegend(layer,subLayers,rootLayer)

    {
        if(layer.subLayerContents.length > 0)
        {
            for(var x=0; x<layer.subLayerContents.length;x++){
                var sublyr = layer.subLayerContents[x]
                if(sublyr)
                {

                    if(sublyr !== null)
                    {
                        if(sublyr.subLayerContents && sublyr.subLayerContents.length > 0)
                        {
                            for(var ks = 0;ks<sublyr.subLayerContents.length; ks++)
                            {
                                processSubLayers(sublyr.subLayerContents[ks],subLayers,rootLayer.name,rootLayer.index)
                            }
                        }
                        else{
                            var lyrname = sublyr.name

                            var issublyrVisible = sublyr.isVisibleAtScale(mapView.mapScale)

                            if(issublyrVisible && layer.visible && layer.showInLegend && rootLayer.visible)
                            {
                                subLayers.push(lyrname)

                                sortAndAddLegendForLayer(sublyr,true,layer.name)
                            }

                        }
                    }

                }

            }
        }
        else
        {
            var issublyrVisible1 = layer.isVisibleAtScale(mapView.mapScale)


            if(issublyrVisible1 && layer.visible && layer.showInLegend && rootLayer.visible)

            {
                subLayers.push(layer.name)

                sortAndAddLegendForLayer(layer,true,rootLayer.name)
            }


        }
        return subLayers
    }

    function sortContent()
    {

    }


    function getItemFromContentsModel(item)
    {
        for(var i=0;i<mapView.contentsModel.count;i++)
        {
            var item2= mapView.contentsModel.get(i)
            if(item.lyrname === item2.name)
            {

                item.checkBox = item2.checkBox
                break;
            }
        }
        return item
    }

    function populateLegend(layer,item)
    {
        if(layer){
            if(layer.subLayerContents.length > 0)
            {
                var newSubLyrs = []

                //isGroupLyr=true
                //the index is reversed in FeatureCollection vs FeatureLayer.
                for(var newindx = layer.subLayerContents.length;newindx--;){
                    var indx
                    var sublyr
                    if(layer.objectType === "FeatureCollectionLayer")
                    {
                        indx = newindx
                    }
                    else
                        indx = layer.subLayerContents.length - (newindx + 1)

                    sublyr = layer.subLayerContents[layer.subLayerContents.length - (indx + 1)]

                    sublyr = layer.subLayerContents[indx]
                    if(sublyr !== null)
                    {
                        if(layer.subLayerContents[indx].subLayerContents && layer.subLayerContents[indx].subLayerContents.length > 0)
                        {
                            for(var ks= 0;ks< sublyr.subLayerContents.length;ks++)
                            {


                                newSubLyrs = processSubLayerLegend(layer.subLayerContents[indx].subLayerContents[ks],newSubLyrs,layer)

                            }
                        }
                        else{

                            var issublyrVisible = sublyr.isVisibleAtScale(mapView.mapScale)
                            var lyrname = layer.subLayerContents[indx].name
                            if(issublyrVisible && layer.visible && layer.showInLegend)
                            {
                                newSubLyrs.push(lyrname)
                                if(sublyr.showInLegend)
                                    sortAndAddLegendForLayer(sublyr,true,layer.name)
                            }
                        }
                    }
                }

                if(newSubLyrs.length > 0)
                {
                    var sublayersString = newSubLyrs.join(',')

                    if(sublayersString.length > 1)
                    {
                        item.sublayers = sublayersString

                        updateContentsModel(item)
                    }

                }
                else
                {
                    item.sublayers = ""
                    updateContentsModel(item)
                }

            }
            else{
                sortAndAddLegendForLayer(layer,false)
                updateContentsModel(item)
            }
            sortLegendInfosByLyrIndex()

        }
    }

    /*
      This is also added new in version 4.1 so that the content
      is also sorted. It resolves the issue in earlier version where the
      layers were  sometimes  not sorted

      */

    function sortLegendContentByLyrIndex()
    {
       mapView.orderedLegendInfos.clear()
        var layers = mapView.map.operationalLayers
        //loop through the operational layers and update the subLayers based on their visibility
        //Some layers  may have scale dependency. So we need to check the visibility
        //of the layers/sublayers based on the mapscale and prepare the legend accordingly

        for (var k=layers.count; k--;)
        {
            var layer = layers.get(k)
            var isGroupLyr = false
            if(layer){
                if(layer.loadStatus === Enums.LoadStatusLoaded)
                {
                    for(var i=0;i<mapView.contentListModel.count;i++)
                    {
                        var item = mapView.contentListModel.get(i)
                        item = getItemFromContentsModel(item)

                        if(item.lyrname === layer.name){

                            var newSubLyrs = []

                            if(layer.subLayerContents.length > 0)
                            {
                                isGroupLyr=true
                                //the index is reversed in FeatureCollection vs FeatureLayer.
                                for(var newindx = layer.subLayerContents.length;newindx--;){
                                    var indx
                                    var sublyr
                                    if(layer.objectType === "FeatureCollectionLayer")
                                    {
                                        indx = newindx
                                    }
                                    else
                                        indx = layer.subLayerContents.length - (newindx + 1)

                                    sublyr = layer.subLayerContents[layer.subLayerContents.length - (indx + 1)]

                                    sublyr = layer.subLayerContents[indx]
                                    if(sublyr !== null)
                                    {
                                        if(layer.subLayerContents[indx].subLayerContents && layer.subLayerContents[indx].subLayerContents.length > 0)
                                        {
                                            for(var ks= 0;ks< sublyr.subLayerContents.length;ks++)
                                            {

                                                newSubLyrs = processSubLayerLegend(layer.subLayerContents[indx].subLayerContents[ks],newSubLyrs,layer)

                                            }
                                        }
                                        else{

                                            var issublyrVisible = sublyr.isVisibleAtScale(mapView.mapScale)
                                            var lyrname = layer.subLayerContents[indx].name
                                            if(issublyrVisible && layer.visible && layer.showInLegend)
                                            {
                                                newSubLyrs.push(lyrname)

                                                sortAndAddLegendForLayer(sublyr,true,layer.name)
                                            }
                                        }
                                    }
                                }

                            }
                            else
                            {

                                if (layer.visible && layer.showInLegend && layer.isVisibleAtScale(mapView.mapScale))
                                    sortAndAddLegendForLayer(layer,false)
                            }


                            if (isGroupLyr)
                            {
                                if(newSubLyrs.length > 0)
                                {
                                    var sublayersString = newSubLyrs.join(',')
                                    item.sublayers = sublayersString
                                    if(sublayersString.length > 1)
                                    {
                                        item.isVisibleAtScale = true
                                        updateContentsModel(item)
                                    }
                                    else
                                    {
                                        if(layer.isVisibleAtScale(mapView.mapScale))
                                            item.isVisibleAtScale = true
                                        else
                                            item.isVisibleAtScale = false
                                        updateContentsModel(item)
                                    }
                                }
                                else
                                {
                                    item.sublayers = ""
                                    if(layer.isVisibleAtScale(mapView.mapScale))
                                        item.isVisibleAtScale = true
                                    else
                                        item.isVisibleAtScale = false

                                    updateContentsModel(item)
                                }
                            }

                            else
                            {
                                // if (layer.visible && layer.showInLegend && layer.isVisibleAtScale(mapView.mapScale))
                                if (layer.isVisibleAtScale(mapView.mapScale))
                                {
                                    item.sublayers = ""
                                    item.isVisibleAtScale = true
                                    updateContentsModel(item)
                                }
                                else
                                {
                                    item.isVisibleAtScale = false
                                    updateContentsModel(item)
                                }

                            }

                            break;
                        }
                    }
                }
            }
        }

    }

    function getExisting(contentsModel,layerName)
    {
        for (var i=0;i<contentsModel.count;i ++)
        {
            var lyr = contentsModel.get(i)
            if(lyr.lyrname === layerName)
                return true
        }
        return false

    }

    function sortLegendContent()
    {

        if(!mapView.map) return
        var oplayers = mapView.map.operationalLayers

        for (var k=oplayers.count; k--;)
        {

            var layer = oplayers.get(k)

            if(layer)
            {
                if(layer.loadStatus === Enums.LoadStatusLoaded)
                {

                    var name = layer.name
                    //get the layer from contents model
                    for(var k1=0;k1<mapView.contentsModel_copy.count;k1++)
                    {
                        var item =  mapView.contentsModel_copy.get(k1)
                        if(item.lyrname === layer.name)
                        {
                            var isPresent = getExisting(mapView.contentsModel,layer.name)
                            if(!isPresent)
                                mapView.contentsModel.append(item)
                            break;
                        }


                    }
                }
            }
        }

    }
    function updateCheckbox(item)
    {
        for(var k=0;k<mapView.contentsModel_copy.count;k++)
        {
            var obj = mapView.contentsModel_copy.get(k)
            if((obj.lyrname === item.lyrname) && obj.checkBox !== item.checkbox)
                mapView.contentsModel_copy.set(k,{"checkBox":item.checkBox})

            //contentsModel_copy.append(mapView.contentsModel.get(k))
        }
    }

    function updateContentsModel(item)
    {

        //contentsModel_copy.clear()
        for(var k=0;k<mapView.contentsModel.count;k++)
        {
            updateCheckbox(mapView.contentsModel.get(k))
            //contentsModel_copy.append(mapView.contentsModel.get(k))
        }
        mapView.contentsModel.clear()

        var updated = false
        var itemindx = -1
        for(var k2=0;k2<mapView.contentsModel_copy.count;k2++)
        {

            var element = mapView.contentsModel_copy.get(k2)
            if(element.lyrname === item.lyrname)
            {
                itemindx = k2
                var sublayers = item.sublayers
                mapView.contentsModel_copy.set(k2,{"sublayers":sublayers})
                mapView.contentsModel_copy.set(k2,{"isVisibleAtScale":item.isVisibleAtScale})
                //contentsModel_copy.set(k2,{"checkBox":item.checkBox})
                updated = true
                break;
            }
        }

        if(!updated)
        {
            mapView.contentsModel_copy.append(item)

        }


        //sortLegendContent()

    }


    function sortLegendInfosByLyrIndex()
    {
        mapView.orderedLegendInfos.clear()
        var oplayers = mapView.map.operationalLayers

        for (var k=oplayers.count; k--;)
        {
            var layer = oplayers.get(k)

            if(layer.loadStatus === Enums.LoadStatusLoaded)
            {
                //for each layer check if it is a group layer
                if(oplayers.get(k).subLayerContents.length > 0)
                {
                    //if it is a grouplayer sort the sublayers first based on layer index

                    for(var indx = oplayers.get(k).subLayerContents.length;indx--;)
                    {
                        //Then for each sublayer sort the legend based on legend index and add to a listmodel
                        var sublayer =  oplayers.get(k).subLayerContents[indx]
                        if(sublayer)
                        {
                            if (layer.visible && layer.showInLegend && sublayer.isVisibleAtScale(mapView.mapScale))
                                sortAndAddLegendForLayer(sublayer,true,layer.name)
                        }
                    }
                }
                else
                {
                    //if it is not a group layer sort the legend based on legend index and add to a listmodel
                    if (layer.visible && layer.showInLegend)
                        sortAndAddLegendForLayer(layer,false)
                }
            }

        }

    }
/*
    This sorting functionality is new in version 4.1. Since the layers can load in any order
    we need to sort the layers based on the order they are added to the map.
    In addition we need to  also sort the legend based on legend index.


    */

  function sortAndAddLegendForLayer(layer1,isSublayer,rootLayerName){
      var legendArray = []
      if(layer1.showInLegend){
          for(var k=0;k<mapView.unOrderedLegendInfos.count;k++)
          {
              var item = mapView.unOrderedLegendInfos.get(k)
              if(isSublayer)
              {
                  if(layer1.sublayerId)
                  {
                      if (item.layerName === layer1.name && item.rootLayerName === rootLayerName && parseInt(item.layerIndex) === parseInt(layer1.sublayerId))
                      {
                          legendArray.push(item)
                      }
                  }
                  else
                  {
                      if ((item.layerName === layer1.name) && (item.rootLayerName === rootLayerName))
                      {
                          legendArray.push(item)
                      }
                  }
              }
              else
              {
                  if (item.layerName === layer1.name)
                  {
                      legendArray.push(item)
                  }
              }
          }
          legendArray.sort((a, b) => (a.legendIndex > b.legendIndex) ? 1 : -1)
          legendArray.forEach(function(element){
              mapView.orderedLegendInfos.append(element)
          })
      }

  }

  function updateLegendInfos () {
      // sortLegendInfosByLyrIndex()

      /*if (mapView.map.legendInfos.count > mapView.legendProcessingCountLimit) return mapView.map.legendInfos
      mapView.orderedLegendInfos.clear()
      for (var i=mapView.map.operationalLayers.count; i--;) {
          var lyr = mapView.map.operationalLayers.get(i)
          if (!lyr.visible || !lyr.showInLegend) continue
          var other = null
          for (var j=0; j<lyr.legendInfos.count; j++) {
              var ol = lyr.legendInfos.get(j)
              var ul = mapView.unOrderedLegendInfos.getItemByAttributes({"name": ol.name, "layerIndex": i})
              if (["Other", "other"].indexOf(ol.name) !== -1) {
                  other = ul
                  continue
              }
              if (ul) mapView.orderedLegendInfos.addIfUnique(ul, "uid")
          }
          if (other) mapView.orderedLegendInfos.addIfUnique(other, "uid")
      }
      return mapView.orderedLegendInfos*/
  }


  /* This function is modified in version 4.1 as sometimes the grouped layers can take some time to load
    This was causing the legend to show sometimes in random order.

    */

  function updateLayers () {
      mapView.contentListModel.clear()
      mapView.layersWithErrorMessages.clear()

      legendManager.mapView = mapView
      legendManager.uidRequested = []
      legendManager.procLayers()

      //mapView.procLayers()
      /*mapView.procLayers(null, function () {
          if (mapView.map.legendInfos.count <= mapView.legendProcessingCountLimit) {
              mapView.fetchAllLegendInfos()
          }
      })*/
  }

 /* function fetchAllLegendInfos () {
      mapView.unOrderedLegendInfos.clear()
      for (var i=mapView.map.operationalLayers.count; i--;) {
          var lyr = mapView.map.operationalLayers.get(i)
          mapView.fetchLegendInfos(lyr, i)
      }
  }*/

  function fetchLegendInfos (lyr,layerIndex,rootLayerName,rootLayerIndex) {

      lyr.legendInfos.fetchLegendInfosStatusChanged.connect(function () {
          switch (lyr.legendInfos.fetchLegendInfosStatus) {
          case Enums.TaskStatusCompleted:
              fetchLayerLegends(lyr, layerIndex,rootLayerName,rootLayerIndex)
          }
      })
      lyr.legendInfos.fetchLegendInfos(true)
  }

  function fetchLayerLegends (lyr, layerIndex,rootLayerName,rootLayerIndex) {
      for (var i=0; i<lyr.legendInfos.count; i++) {
          if(lyr.sublayerId)
              layerIndex = lyr.sublayerId
          mapView.noSwatchRequested ++
          createSwatchImage(lyr.legendInfos.get(i), lyr.name, i, layerIndex,rootLayerName,rootLayerIndex)
      }
  }

  /*
    This function is modified in  version 4.1 to sort the legend after we get the image.

    */
  function createSwatchImage(legend, layerName, legendIndex, layerIndex,rootLayerName,rootLayerIndex) {
      var responseRecvd = false
      var sym = legend.symbol
      var uid = ""
      if(layerName !== rootLayerName)
          uid = rootLayerName + "_" + layerName + "_" + layerIndex + "_" + legendIndex
      else
          uid = layerName + "_" + legendIndex

      if(!uidRequested.includes(uid))
      {
          uidRequested.push(uid)

          if(sym.swatchImage && sym.json.url){

              populateUnOrderedLegendInfos(uid,sym.json.url,legend, layerName, legendIndex, layerIndex,rootLayerName,rootLayerIndex)

          }

          sym.swatchImageChanged.connect(function () {

              if (sym.swatchImage) {
                  populateUnOrderedLegendInfos(uid,sym.swatchImage.toString(),legend, layerName, legendIndex, layerIndex,rootLayerName,rootLayerIndex)
              }

          })


          sym.createSwatch()
      }

  }

  function populateUnOrderedLegendInfos(uid,url,legend, layerName, legendIndex, layerIndex,rootLayerName,rootLayerIndex){

      mapView.unOrderedLegendInfos.replaceOrAppendUnique(
                  {
                      "uid": uid,
                      "legendIndex": legendIndex,
                      "layerIndex": parseInt(layerIndex),
                      "layerName": layerName,
                      "name": legend.name,
                      "symbolUrl": url,
                      "rootLayerName":rootLayerName,
                      "rootLayerIndex":rootLayerIndex,

                      "displayName":rootLayerName?"<b>"+ rootLayerName + "</b>" + "<br/>" +  layerName:layerName

                  }, "uid")
      mapView.noSwatchReceived++
      //                        if(mapView.noSwatchRequested === mapView.noSwatchReceived)
      sortLegendContent()
  }



}
