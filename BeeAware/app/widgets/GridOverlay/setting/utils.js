// All material copyright ESRI, All Rights Reserved, unless otherwise specified.
// See http://js.arcgis.com/3.15/esri/copyright.txt and http://www.arcgis.com/apps/webappbuilder/copyright.txt for details.

require({cache:{"url:widgets/GridOverlay/setting/esri_tileinfo.json":'{\r\n  "rows": 256,\r\n  "cols": 256,\r\n  "dpi": 96,\r\n  "compressionQuality": 75,\r\n  "origin": {\r\n   "x": -2.0037508342787E7,\r\n   "y": 2.0037508342787E7\r\n  },\r\n  "spatialReference": {\r\n   "wkid": 102100,\r\n   "latestWkid": 3857\r\n  },\r\n  "lods": [\r\n   {\r\n    "level": 0,\r\n    "resolution": 156543.03392800014,\r\n    "scale": 5.91657527591555E8\r\n   },\r\n   {\r\n    "level": 1,\r\n    "resolution": 78271.51696399994,\r\n    "scale": 2.95828763795777E8\r\n   },\r\n   {\r\n    "level": 2,\r\n    "resolution": 39135.75848200009,\r\n    "scale": 1.47914381897889E8\r\n   },\r\n   {\r\n    "level": 3,\r\n    "resolution": 19567.87924099992,\r\n    "scale": 7.3957190948944E7\r\n   },\r\n   {\r\n    "level": 4,\r\n    "resolution": 9783.93962049996,\r\n    "scale": 3.6978595474472E7\r\n   },\r\n   {\r\n    "level": 5,\r\n    "resolution": 4891.96981024998,\r\n    "scale": 1.8489297737236E7\r\n   },\r\n   {\r\n    "level": 6,\r\n    "resolution": 2445.98490512499,\r\n    "scale": 9244648.868618\r\n   },\r\n   {\r\n    "level": 7,\r\n    "resolution": 1222.992452562495,\r\n    "scale": 4622324.434309\r\n   },\r\n   {\r\n    "level": 8,\r\n    "resolution": 611.4962262813797,\r\n    "scale": 2311162.217155\r\n   },\r\n   {\r\n    "level": 9,\r\n    "resolution": 305.74811314055756,\r\n    "scale": 1155581.108577\r\n   },\r\n   {\r\n    "level": 10,\r\n    "resolution": 152.87405657041106,\r\n    "scale": 577790.554289\r\n   },\r\n   {\r\n    "level": 11,\r\n    "resolution": 76.43702828507324,\r\n    "scale": 288895.277144\r\n   },\r\n   {\r\n    "level": 12,\r\n    "resolution": 38.21851414253662,\r\n    "scale": 144447.638572\r\n   },\r\n   {\r\n    "level": 13,\r\n    "resolution": 19.10925707126831,\r\n    "scale": 72223.819286\r\n   },\r\n   {\r\n    "level": 14,\r\n    "resolution": 9.554628535634155,\r\n    "scale": 36111.909643\r\n   },\r\n   {\r\n    "level": 15,\r\n    "resolution": 4.77731426794937,\r\n    "scale": 18055.954822\r\n   },\r\n   {\r\n    "level": 16,\r\n    "resolution": 2.388657133974685,\r\n    "scale": 9027.977411\r\n   },\r\n   {\r\n    "level": 17,\r\n    "resolution": 1.1943285668550503,\r\n    "scale": 4513.988705\r\n   },\r\n   {\r\n    "level": 18,\r\n    "resolution": 0.5971642835598172,\r\n    "scale": 2256.994353\r\n   },\r\n   {\r\n    "level": 19,\r\n    "resolution": 0.29858214164761665,\r\n    "scale": 1128.497176\r\n   },\r\n   {\r\n    "level": 20,\r\n    "resolution": 0.14929107082380833,\r\n    "scale": 564.248588\r\n   },\r\n   {\r\n    "level": 21,\r\n    "resolution": 0.07464553541190416,\r\n    "scale": 282.124294\r\n   },\r\n   {\r\n    "level": 22,\r\n    "resolution": 0.03732276770595208,\r\n    "scale": 141.062147\r\n   },\r\n   {\r\n    "level": 23,\r\n    "resolution": 0.01866138385297604,\r\n    "scale": 70.5310735\r\n   }\r\n  ]\r\n }'}});
define("dojo/_base/lang dojo/Deferred dojo/json dojo/_base/array dojo/promise/all esri/SpatialReference jimu/portalUtils jimu/shared/basePortalUrlUtils esri/request dojo/text!./esri_tileinfo.json".split(" "),function(l,n,y,r,z,t,p,A,B,C){function u(a){if(!a)return null;var b=a.indexOf("?");return 0===a.search(/http|\/\//)&&-1!==b?a.slice(0,b).replace(/\/*$/g,""):a}function k(a){return a?A.removeProtocol(u(a)):""}function D(a){var b=new n;p.getPortalSelfInfo(a).then(l.hitch(this,function(c){var d=
c.basemapGalleryGroupQuery;!0===c.useVectorBasemaps&&c.vectorBasemapGalleryGroupQuery&&(d=c.vectorBasemapGalleryGroupQuery);g.getBasemapGalleryGroup(a,d).then(l.hitch(this,function(f){f.queryItems({start:1,num:100,f:"json",q:p.webMapQueryStr}).then(l.hitch(this,function(e){b.resolve(e)}),l.hitch(this,function(){b.reject()}))}),l.hitch(this,function(){b.reject()}))}));return b}function v(a){return B({url:a,content:{f:"json"},handleAs:"json",callbackParamName:"callback"}).then(function(b){return b},
function(){return null})}var g={},E=y.parse(C);g._loadPortalBaseMaps=function(a,b){var c=new n,d=[];D(a).then(function(f){r.forEach(f.results,function(e){var h=new n,q=k(e.thumbnailUrl);d.push(h);e.getItemData().then(function(m){g._getBasemapSpatialReference(e,m).then(l.hitch(this,function(w){var x=m.baseMap.baseMapLayers;g.isBasemapCompatibleWithMap(w,x,b).then(l.hitch(this,function(F){F?h.resolve({layers:x,title:e.title||m.baseMap.title,thumbnailUrl:q,spatialReference:w}):h.resolve({})}))}))})});
z(d).then(function(e){e=r.filter(e,function(h){return h&&h.title?!0:!1},this);c.resolve(e)})},function(f){c.reject(f)});return c};g.isBasemapCompatibleWithMap=function(a,b,c){var d=new n,f=c.spatialReference,e=c.width>c.height?c.width:c.height;if(!f||!b||0>=b.length||!a||!f.equals(new t(+a.wkid)))return d.resolve(!1),d;0===c.getNumLevels()?"OpenStreetMap"===b[0].layerType||b[0].layerType&&-1<b[0].layerType.indexOf("BingMaps")||"WebTiledLayer"===b[0].layerType||"VectorTileLayer"===b[0].layerType||
"ArcGISImageServiceVectorLayer"===b[0].layerType||"ArcGISTiledImageServiceLayer"===b[0].layerType?d.resolve(!1):d.resolve(!0):b[0].layerType&&0===b[0].layerType.indexOf("ArcGIS")&&b[0].url?v(b[0].url).then(function(h){(b[0].serviceInfoResponse=h)&&h.tileInfo?d.resolve(g.tilingSchemeCompatible(c.__tileInfo,h.tileInfo,e)):h&&h.capabilities&&(0<=h.capabilities.indexOf("Map")||h.capabilities.indexOf("Image"))?d.resolve(!0):d.resolve(!1)}):"WMS"===b[0].layerType?d.resolve(!0):g.isNoUrlLayerMap(b)||"VectorTileLayer"===
b[0].layerType?d.resolve(g.tilingSchemeCompatible(c.__tileInfo,E,e)):d.resolve(g.tilingSchemeCompatible(c.__tileInfo,b[0].tileInfo,e));return d};g.tilingSchemeCompatible=function(a,b,c){if(a&&b){var d=!1,f=!1,e,h;for(e=0;e<a.lods.length;e++){var q=a.lods[e].scale;a.dpi!==b.dpi&&(q=a.lods[e].scale/a.dpi);for(h=0;h<b.lods.length;h++){var m=b.lods[h].scale;a.dpi!==b.dpi&&(m=b.lods[h].scale/b.dpi);if(Math.abs(m-q)/m<1/c)if(d){f=!0;break}else d=!0;if(m<q)break}if(f)break}a=f?!0:!d||1!==a.lods.length&&
1!==b.lods.length?!1:!0;return a}return!0};g.isSameBasemapLayer=function(a,b){if(a.layerType&&b.layerType){if(a.layerType!==b.layerType)return!1;if("ArcGISImageServiceVectorLayer"===a.layerType||"ArcGISTiledImageServiceLayer"===a.layerType||"ArcGISTiledMapServiceLayer"===a.layerType||"ArcGISMapServiceLayer"===a.layerType||"ArcGISImageServiceLayer"===a.layerType)return a=k(a.url||""),b=k(b.url||""),a.toLowerCase()===b.toLowerCase();if("BingMapsAerial"===a.layerType||"BingMapsRoad"===a.layerType||"BingMapsHybrid"===
a.layerType||"OpenStreetMap"===a.layerType)return!0;if("VectorTileLayer"===a.layerType)return a=k(a.styleUrl||""),b=k(b.styleUrl||""),a.toLowerCase()===b.toLowerCase();if("WMS"===a.layerType)return a=k(a.mapUrl||""),b=k(b.mapUrl||""),a.toLowerCase()===b.toLowerCase();if("WebTiledLayer"===a.layerType){if(a.templateUrl&&b.templateUrl)return a=k(a.templateUrl||""),b=k(b.templateUrl||""),a.toLowerCase()===b.toLowerCase();if(a.wmtsInfo&&b.wmtsInfo)return a=k(a.wmtsInfo.url||""),b=k(b.wmtsInfo.url||""),
a.toLowerCase()===b.toLowerCase()}}else return a=k(a.url||""),b=k(b.url||""),a.toLowerCase()===b.toLowerCase();return!1};g.compareSameBasemapByOrder=function(a,b){a=a.layers;b=b.layers;if(a.length!==b.length)return!1;for(var c=0;c<a.length;c++)if(!g.isSameBasemapLayer(a[c],b[c]))return!1;return!0};g.isBingMap=function(a){if(!a||!a.layers)return!1;for(var b=0;b<a.layers.length;b++)if("BingMapsAerial"===a.layers[b].type||"BingMapsRoad"===a.layers[b].type||"BingMapsHybrid"===a.layers[b].type)return!0;
return!1};g.isNoUrlLayerMap=function(a){for(var b=0;b<a.length;b++)if("BingMapsAerial"===a[b].type||"BingMapsRoad"===a[b].type||"BingMapsHybrid"===a[b].type||"OpenStreetMap"===a[b].type)return!0;return!1};g.getToken=function(a){a=p.getPortal(a);a.updateCredential();return a.credential?"?token\x3d"+a.credential.token:""};g.removeUrlQuery=function(a){return u(a)};g.getStanderdUrl=function(a){return k(a)};g.getUniqueTitle=function(a,b){if(!b||0===b.length)return a;b=r.filter(b,function(c){return c===
a?!0:0===c.indexOf(a)?(c=c.substr(a.length+1),!isNaN(+c)):!1});if(0===b.length)return a;b=r.map(b,function(c){return c===a?0:+c.substr(a.length+1)});b=b.sort();return a+" "+(b[b.length-1]+1)};g.getBasemapInfo=function(a,b){var c,d;return p.getPortal(a).getItemById(b).then(function(f){c=f;return f.getItemData()}).then(function(f){d=f;return g._getBasemapSpatialReference(c,f)}).then(function(f){return{thumbnailUrl:c.thumbnailUrl,title:c.title||d.baseMap.title,layers:d.baseMap.baseMapLayers,spatialReference:new t(f)}})};
g.getBasemapGalleryGroup=function(a,b){var c=new n;a=p.getPortal(a);var d=b.indexOf("esri_");if(0<=d){d=b.slice(d,d+7);var f="esri_"+dojoConfig.locale.slice(0,2);b=b.replace(d,f)}a.queryGroups({f:"json",q:b}).then(l.hitch(this,function(e){0<e.results.length?c.resolve(e.results[0]):c.reject()}),l.hitch(this,function(){c.reject()}));return c};g._getBasemapSpatialReference=function(a,b){var c=null,d=!1,f=new n;if(a.owner&&0===a.owner.indexOf("esri_")||g.isNoUrlLayerMap(b.baseMap.baseMapLayers))c={wkid:"102100"};
else if(b.spatialReference||a.spatialReference)c=b.spatialReference||a.spatialReference;else if(b.baseMap.baseMapLayers&&b.baseMap.baseMapLayers[0])if(a=b.baseMap.baseMapLayers[0],a.url&&0<a.url.indexOf("rest/services"))d=!0,v(b.baseMap.baseMapLayers[0].url).then(l.hitch(this,function(e){e&&e.spatialReference&&(c=e.spatialReference);f.resolve(c)}),function(e){console.error(e);f.resolve(null)});else if("VectorTileLayer"===a.layerType)c={wkid:"102100"};else if(b=a.fullExtent||a.initialExtent)c=b.spatialReference;
d||f.resolve(c);return f};return g});