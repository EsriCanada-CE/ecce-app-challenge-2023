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

import ArcGIS.AppFramework 1.0

import Esri.ArcGISRuntime 100.14

//TODO: creating a portal item isn't the best option. Continue with json

Item {
    id: root

    property string portalUrl: "http://www.arcgis.com" //NB: This is reset in the method findItems()
    property Portal portal:app.portal
    property var findItemsResults: []
    property var findAttachmentViewerResults:[]
    property bool isBusy: false
    property bool isOnline: Networking.isOnline
    property string token: ""
    property string referer: ""
    property string subFolder: "MapViewer"
    property string onlineFolder: "onlinecache"
    property string offlineFolder: "offlinecache"
    property string offlineMapAreaFolder: "mapareas"
    property string screenShotsCacheFolder:"screenshotsCache"

    property var norequests: -1
    property alias offlineCacheManager:offlineCacheManager
    property var appsForWhichJsonRequested:[]

    signal updateModel

    //    signal requestSuccess(var results, int errorCode, string errorMsg)
    signal requestError(int errorCode, string errorMsg)

    onRequestError: {
        root.isBusy = false
    }

    MmpkManager {
        id: mmpkManager

        rootUrl: "%1/sharing/rest/content/items/".arg(portalUrl)
        subFolder: offlineCacheManager.subFolder
    }

    NetworkCacheManager {
        id: onlineCacheManager

        referer: root.referer
        subFolder: [root.subFolder, onlineFolder].join("/")
    }

    NetworkCacheManager {
        id: offlineCacheManager

        referer: root.referer
        subFolder: [root.subFolder, offlineFolder].join("/")
    }

    function clearResults()
    {
        findItemsResults = []
    }

    function findItems (portal, queryParameters) {
        if(!portal) return;

        root.isBusy = true;


        root.portalUrl = portal.url;

        if (isOnline) {
            onlineCacheManager.clearAllCache()//Cache(url)
        }

        portal.findItems(queryParameters);

    }

    function searchAttachments(definitionExpression,layerUrl,resolve,token)
    {
        if(token)
            root.token = token
        var url = layerUrl + "/queryAttachments"
        //https://services.arcgis.com/Sv9ZXFjH5h1fYAaI/arcgis/rest/services/Missing_Children_Cases_View_Ontario/FeatureServer/0/queryAttachments?f=json&returnMetadata=true&definitionExpression=1%3D1

        var obj = {}
        obj = {
            "f":"json",
            "returnMetadata":true,
            "definitionExpression":definitionExpression,
            "token":root.token
            //"size":"1000,2000000"

        }
        makeNetworkConnection(url,obj,function(response){
            if(response)
            {
                resolve(response)
            }
        })



    }

    //first it will fetch the attachmentviewers configured, then it will fetch the one configured
    //in applink.
    function searchAttachmentViewers(resolve){
        norequests = 0
        if(!appLink)
            webmapsDic = ({})
        if (portal.findItemsStatus !== Enums.TaskStatusCompleted)
            return;

        if(findAttachmentViewerResults.length > 0) {
            for(var element of findAttachmentViewerResults){
                var url = element.url
                if(!appsForWhichJsonRequested.includes(element.id)) {
                    appsForWhichJsonRequested.push(element.id)
                    var obj = {}
                    let _token = element.token ? element.token :portalSearch.token
                    if(_token){
                        obj = {
                            "f":"json",
                            "token":_token
                        }
                    }
                    else {
                        obj = {
                            "f":"json"
                        }
                    }
                    makeNetworkConnection(url,obj,function(response,params){
                        if(response) {
                            norequests +=1
                            //process the webmap ids

                            if(response.values && response.values.webmap) {
                                var webmapid = response.values.webmap
                                app.attachmentViewers.push(webmapid)
                                viewerJsonDict[params.element.id] = response.values
                                let isUpdate = true
                                saveCurrentViewerJson(params.element.id,isUpdate)
                                var appProps = {}
                                appProps.thumbnailUrl = params.element.thumbnailUrl
                                appProps.webmapId = webmapid
                                appProps.title = params.element.title
                                appProps.snippet = params.element.snippet
                                appProps.modified = params.element.modified
                                appProps.owner = params.element.owner
                                appProps.created = params.element.created
                                appProps.avgRating = params.element.avgRating
                                appProps.numRatings = params.element.numRatings
                                appProps.numComments = params.element.numComments
                                appProps.numViews = params.element.numViews


                                appDict[params.element.id] = appProps
                                if(!(webmapid in webmapsDic)) {
                                    webmapsDic[webmapid] = [params.element.id]
                                }
                                else {
                                    var apps = webmapsDic[webmapid]
                                    apps.push(params.element.id)
                                    webmapsDic[webmapid] = apps
                                }

                                if(norequests >= findAttachmentViewerResults.length) {
                                    //query for fetching webmaps
                                    app.searchQueryUpdated = true
                                    updateSearchQuery()
                                    if(appLink && applinkProcessed) {
                                        webmapQueryStarted = true
                                        queryForWebmap(portal)
                                        //queryForWebmap(publicPortal)
                                    }
                                    else
                                        resolve()
                                }
                            }
                        }
                    },{element})
                }
                else {
                    norequests +=1

                    if(norequests >= findAttachmentViewerResults.length){
                        //query for fetching webmaps
                        app.searchQueryUpdated = true

                        updateSearchQuery()

                        if(appLink && applinkProcessed && !webmapQueryStarted){
                            webmapQueryStarted = true
                            queryForWebmap(portal)
                            //queryForWebmap(publicPortal)
                        }
                        else
                            resolve()
                    }
                }
            }
        }
        else {
            app.mapSearchText = strings.no_nearbys_available;
            resolve()
        }
    }

    function updateSearchQuery()
    {
        var attachmentid
        var newquery = ""//app.searchQuery.replace('(', '')

        for (attachmentid  of app.attachmentViewers)
        {
            if(newquery.length === 0)
                newquery = "id:" + attachmentid
            else
                newquery = newquery + " OR id:"+ attachmentid


        }
        app.searchQuery = "(" + newquery + ")"
    }

    function makeNetworkConnection(url, obj, callback, params) {
        var component = networkRequestComponent;
        var networkRequest = component.createObject(parent);
        networkRequest.url = url;
        networkRequest.callback = callback;
        networkRequest.params = params;
        networkRequest.send(obj);
    }

    Component {
        id: networkRequestComponent

        NetworkRequest {
            property var callback
            property var params

            followRedirects: true
            ignoreSslErrors: true
            responseType: "json"
            method: "GET"

            onReadyStateChanged: {
                if (readyState == NetworkRequest.DONE){
                    if (errorCode === 0) {
                        callback(response, params, errorCode);
                    } else {
                        callback(response, params, errorCode);
                    }
                }
            }

            onError: {
                callback({}, params, -1);
            }
        }
    }


    function searchEventHandler(){
        if (portal.findItemsStatus !== Enums.TaskStatusCompleted)
            return;
        var isModelUpdated = false

        var resultsArray = []
        var _findItemResult = portal.findItemsResult;
        if(_findItemResult) {
            _findItemResult.itemResults.forEach(function(element) {
                var portalItem = element.json;
                if(element.portal.credential)
                    if(element.portal.credential.token) root.token = element.portal.credential.token;

                if (!portalItem.url) portalItem.url = "%1/sharing/rest/content/items/%2".arg(portal.url).arg(portalItem.id)
                portalItem.thumbnailUrl = onlineCacheManager.cache(root.getThumbnailUrl(portalUrl, portalItem, root.token), "", {"token": token}, null)
                if (isOnline && portalItem.type === "Web Map") {
                    //get all the apps that are pointed to this webmap
                    var attachmentViewers =  webmapsDic[portalItem.id]
                    attachmentViewers.forEach(function(viewerapp) {
                        var _portalitem = Object.assign({},portalItem)

                        var appProps = appDict[viewerapp]
                        var thumbnailUrl = appProps.thumbnailUrl
                        _portalitem.title = appProps.title
                        _portalitem.thumbnailUrl = thumbnailUrl
                        _portalitem.viewerId = viewerapp
                        _portalitem.modified = appProps.modified
                        _portalitem.owner = appProps.owner
                        _portalitem.created = appProps.created
                        _portalitem.avgRating = appProps.avgRating
                        _portalitem.numRatings = appProps.numRatings
                        _portalitem.numComments =appProps.numComments
                        _portalitem.numViews =  appProps.numViews
                        resultsArray.push(_portalitem)
                    });

                } else if (portalItem.type === "Mobile Map Package") {
                    mmpkManager.itemId = portalItem.id
                    if (mmpkManager.hasOfflineMap()) {
                        resultsArray.push(portalItem)
                    }
                }
                else if(isOnline && portalItem.type === "Web Mapping Application") {
                    var url = portalItem.url.toLowerCase()
                    if(url.includes("nearby"))
                    {
                        portalItem.url = "%1/sharing/rest/content/items/%2/data".arg(portal.url).arg(portalItem.id)
                        if(element.portal.credential)
                            portalItem.token = element.portal.credential.token
                        let existingViewer = findAttachmentViewerResults.filter(viewer => viewer.id === portalItem.id)

                        if(!existingViewer.length > 0)
                        {
                            findAttachmentViewerResults.push(portalItem)
                        }
                    }
                }
            })
        }

        resultsArray.forEach(function(element) {

            var obj = findItemsResults.filter(item => item.viewerId === element.viewerId)
            if(obj.length === 0){
                findItemsResults.push(element);
                isModelUpdated = true
            }

        });

        root.isBusy = false
        if(isModelUpdated)
            updateModel()
    }

    Connections{
        target:portal

        function onFindItemsStatusChanged() {
            searchEventHandler();
        }
    }


    //-------------------------------------------------------------------------------
    property string url
    property var obj

    //-------------------------------------------------------------------------------

    function constructUrlSuffix (obj) {
        var urlSuffix = ""
        for (var key in obj) {
            if (obj.hasOwnProperty(key)) {
                if (obj[key]) {
                    urlSuffix += "%1=%2&".arg(key).arg(obj[key])
                }
            }
        }
        return urlSuffix.slice(0, -1)
    }

    function constructQuery (searchString, itemTypes) {

        var query = '-type:"Tile Package" -type:"Web Mapping Application" ' +
                '-type:"Map Service" -type:"Map Template" -type:"Type Map Package"' +
                ' type:Maps AND type:'

        for (var i=0; i<itemTypes.length; i++) {
            if (i !== 0) query += ' OR type:'
            switch (itemTypes[i]) {
            case Enums.PortalItemTypeMobileMapPackage:
                query += '"Mobile Map Package"'
                break
            case Enums.PortalItemTypeWebMap:
                query += '"Web Map"'
                break
            }
        }

        if (searchString) query += " %1".arg(searchString)

        return query
    }

    function getThumbnailUrl (portalUrl, portalItem, token) {
        try {
            if (portalItem.thumbnailUrl) return portalItem.thumbnailUrl
        } catch (err) {}

        var imgName = portalItem.thumbnail
        if (!imgName) {
            return ""
        }
        var urlFormat = "%1/sharing/rest/content/items/%2/info/%3%4",
        prefix = ""
        if (token) {
            //prefix = "?token=%1".arg(token) // Ignoring the token. Letting NetworkCacheManager handle it
        }
        return urlFormat.arg(portalUrl).arg(portalItem.id).arg(imgName).arg(prefix)
    }
}
