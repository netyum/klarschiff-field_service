KS.projection = ->
  if typeof proj4 is 'function'
    proj4.defs 'EPSG:25833', '+proj=utm +zone=33 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs'
    proj4.defs 'urn:ogc:def:crs:EPSG::25833', proj4.defs('EPSG:25833')
    projection_25833 = ol.proj.get 'EPSG:25833'
    projection_25833.setExtent [304094, 5993070, 323567, 6014340]
    return projection_25833
  else
    console.log 'Proj4J ist nicht geladen!'

KS.maxZoom = 10
KS.projectionWGS84 = ol.proj.get 'EPSG:4326'
KS.zoomEvent = false

class KS.Map
  constructor: (@projection = KS.projection()) ->
    @olMap = new ol.Map
      target: 'ol-map'
      view: new ol.View
        projection: @projection
        center: [313356.88711652, 6002555.7959791]
        zoom: 2
        maxZoom: KS.maxZoom

    KS.layers = new KS.Layers(@olMap)
    addControls(@olMap)
    KS.geolocation = new KS.Geolocation(@olMap)
    KS.newFeatureOverlay = new ol.FeatureOverlay(
      map: @olMap
    )
    return @olMap

  addControls = (map) ->
    map.addControl new ol.control.MousePosition
      coordinateFormat: ol.coordinate.createStringXY(4)
      projection: @projection
      undefinedHTML: '?,?'

    map.addControl new ol.control.MousePosition
      className: 'll-mouse-position'
      target: document.getElementById('ol-overlaycontainer-stopevent')
      coordinateFormat: ol.coordinate.createStringXY(6)
      projection: KS.projectionWGS84
      undefinedHTML: '?,?'

    map.addControl new ol.control.ScaleLine

    map.on 'click', (e) ->
      map.forEachFeatureAtPixel e.pixel, (feature, layer) ->
        if layer and (layer.get('id') == 'features' or layer.get('id') == 'jobs')
          features = feature.get('features')
          if features.length == 1
            # Single feature -> show
            $.ajax(url: "/requests/" + features[0].get("id"), dataType: 'script')
          else if map.getView().getZoom() == KS.maxZoom
            ids = Array()
            $(features).each (ix, feature) ->
              ids.push feature.get('id')
            $.ajax(url: "/requests", dataType: 'script', data: { ids: ids })
          else
            # Zoom in
            map.getView().setCenter e.coordinate
            current_zoom = map.getView().getZoom()
            if current_zoom == undefined
              current_zoom = zoom
            map.getView().setZoom parseInt(current_zoom + 1)

    map.on 'moveend', (e) ->
      if !KS.zoomEvent && KS.layers.findById("features").getSource().getFeatures().length > 0
        extent = KS.olMap.getView().calculateExtent(KS.olMap.getSize())
        new KS.FeatureData("/requests", extent, KS.layers.findById("features").getSource().getSource())
        new KS.FeatureData("/jobs", extent, KS.layers.findById("jobs").getSource().getSource())

      KS.zoomEvent = false if KS.zoomEvent

    map.getView().on 'change:resolution', (e) ->
      KS.zoomEvent = true


KS.styles =
  featureAttribution: (feature) ->
    new ol.style.Text
      text: feature.get("attribution")
      font: '15px Glyphicons Halflings'
      offsetX: 28
      offsetY: -22
      rotation: Math.PI / -2
      fill: new ol.style.Fill
        color: '#ffffff'
      stroke: new ol.style.Stroke
        color: '#000000'
        width: 3

  jobStyle: (features) ->
    feature = features.get('features')[0]
    features.setStyle new ol.style.Style
      image: new ol.style.Icon
        anchorXUnits: 'pixels'
        anchorYUnits: 'pixels'
        anchor: [
          16
          50
        ]
        src: 'assets/' + feature.get('icon')
      text: KS.styles.featureAttribution(feature)

  featureStyle: (features) ->
    if (size = features.get('features').length) == 1
      feature = features.get('features')[0]
      features.setStyle new ol.style.Style
        image: new ol.style.Icon
          anchorXUnits: 'pixels'
          anchorYUnits: 'pixels'
          anchor: [
            6
            40
          ]
          src: 'assets/' + feature.get('icon')
        text: KS.styles.featureAttribution(feature)
    else
      features.setStyle new ol.style.Style
        image: new ol.style.Icon
          anchorXUnits: 'pixels'
          anchorYUnits: 'pixels'
          anchor: [
            22
            22
          ]
          src: 'assets/icons/map/cluster/png/cluster.png'
        text: new ol.style.Text
          text: size.toString()
          font: 'bold 20px Verdana'
          fill: new ol.style.Fill
            color: '#000000'

  newFeature: (type) ->
    new ol.style.Style
      image: new ol.style.Icon
        anchorXUnits: 'pixels'
        anchorYUnits: 'pixels'
        anchor: [
          16
          50
        ]
        src: 'assets/icons/map/active/png/' + type + '-gray.png'

  location: ->
    styles = [ new ol.style.Style
      fill: new ol.style.Fill
        color: 'rgba(200,0,255,0.2)'
      stroke: new ol.style.Stroke
        color: '#c800ff'
        width: 1
      image: new ol.style.Circle
        fill: new ol.style.Fill
          color: '#c800ff'
        stroke: new ol.style.Stroke
          color: '#c800ff'
          width: 2
        radius: 6
    ]


class KS.Layers
  constructor: (map) ->
    @active = 0
    @layers = [
      new ol.layer.Tile
        source: new ol.source.TileWMS
          url: "http:\/\/geo.sv.rostock.de\/geodienste\/stadtplan\/ows?"
          params:
            "LAYERS": "stadtplan"
            "FORMAT": "image/png"
          attributions: [
            new ol.Attribution
              html: "Kartenbild © Hansestadt Rostock (<a href=\"http://creativecommons.org/licenses/by/3.0/deed.de\" target=\"_blank\" style=\"color:#006CB7;text-decoration:none;\">CC BY 3.0</a>) | Kartendaten © <a href=\"http://www.openstreetmap.org/\" target=\"_blank\" style=\"color:#006CB7;text-decoration:none;\">OpenStreetMap</a> (<a href=\"http://opendatacommons.org/licenses/odbl/\" target=\"_blank\" style=\"color:#006CB7;text-decoration:none;\">ODbL</a>) und <a href=\"https://geo.sv.rostock.de/uvgb.html\" target=\"_blank\" style=\"color:#006CB7;text-decoration:none;\">uVGB-MV</a>"
          ]
        visible: true,
      new ol.layer.Tile
        source: new ol.source.TileWMS
          url: "http:\/\/geo.sv.rostock.de\/geodienste\/luftbild\/ows?"
          params:
            "LAYERS": "luftbild"
            "FORMAT": "image/png"
          attributions: [
            new ol.Attribution
              html: "© GeoBasis-DE/M-V"
          ]
        visible: false
      new ol.layer.Tile
        maxResolution: 600
        source: new ol.source.TileWMS
          url: "http:\/\/geo.sv.rostock.de\/geodienste\/klarschiff_poi\/ows?"
          params:
            "LAYERS": "abfallbehaelter,ampeln,beleuchtung,brunnen,denkmale,hundetoiletten,recyclingcontainer,sitzgelegenheiten"
            "FORMAT": "image/png"
        visible: true
      new ol.layer.Vector
        id: "features"
        source: new ol.source.Cluster
          distance: 55
          source: new KS.FeatureVector("/requests")
        style: KS.styles.featureStyle
        visible: true
      new ol.layer.Vector
        id: "jobs"
        source: new ol.source.Cluster
          distance: 0
          source: new KS.FeatureVector("/jobs")
        style: KS.styles.jobStyle
        visible: true
    ]
    map.addLayer layer for layer in @layers

  toggle: ->
      @active = (@active + 1) % 2
      layer.setVisible(i > 1 || i == @active) for layer, i in @layers

  findById: (id) ->
    layers = KS.olMap.getLayers()
    i = 0
    while i < layers.getLength()
      tmp = layers.item(i)
      if tmp.get('id') == id
        return tmp
      i++
    null


class KS.FeatureVector
  constructor: (controller) ->
    return vector = new ol.source.ServerVector
      format: new ol.format.TopoJSON
      loader: (extent, resolution, projection) ->
        new KS.FeatureData(controller, extent, vector)
      projection: KS.projection()


class KS.FeatureData
  constructor: (controller, extent, vector) ->
    ls = new ol.geom.LineString([ol.extent.getBottomLeft(extent), ol.extent.getTopRight(extent)])
    extent = ol.proj.transformExtent(extent, KS.projection(), KS.projectionWGS84)
    wgs84Sphere = new ol.Sphere(6378137)
    $.ajax(url: controller, dataType: 'json', data: {
      center: ol.extent.getCenter(extent),
      radius: wgs84Sphere.haversineDistance(ol.extent.getBottomLeft(extent), ol.extent.getCenter(extent))
    }).done (response) ->
      features = new Array
      $.each response, (index, elem) ->
        attribution = ""
        attribution = "" if elem.extended_attributes.photo_required

        count = 1
        while count < elem.extended_attributes.trust
          attribution += ""
          count++

        coord = ol.proj.transform([elem.long, elem.lat], KS.projectionWGS84, KS.projection())
        f = new ol.Feature
          id: elem.service_request_id
          geometry: new ol.geom.Point(coord)
          icon: elem.icon_map
          attribution: attribution
        features.push f
      vector.clear true
      vector.addFeatures features


class KS.Geolocation
  constructor: (map) ->
    geolocation = new ol.Geolocation
      tracking: true
      projection: map.getView().getProjection().getCode()

    geolocation.on 'change', ->
      accuracy_feature = new ol.Feature
      accuracy_feature.bindTo 'geometry', geolocation, 'accuracyGeometry'
      accuracy_feature.setStyle KS.styles.location()

      position_feature = new ol.Feature
        geometry: new ol.geom.Point(geolocation.getPosition())
      position_feature.setStyle KS.styles.location()

      featuresOverlay = new ol.FeatureOverlay
        features: [
          accuracy_feature
          position_feature
        ]

      map.removeOverlay overlay for overlay in map.getOverlays().getArray()
      map.addOverlay featuresOverlay

      unless KS.position
        KS.geolocation.center(map) if KS.geolocation?
      KS.position = geolocation.getPosition()

  center: (map) ->
    overlays = map.getOverlays().getArray()
    if(overlays.length > 0)
      map.getView().fitExtent(
        overlays[0].getFeatures().getArray()[0].getGeometry().getExtent(), map.getSize()
      )


KS.map =
  actions: ->
    $('#ol-map > nav.navbar.actions')

KS.createFeature= (type) ->

  KS.newFeatureOverlay.setStyle KS.styles.newFeature(type)
  KS.clearNewFeature()

  position = KS.olMap.getView().getCenter()
  if KS.position && ol.extent.containsCoordinate(KS.olMap.getView().calculateExtent(
          KS.olMap.getSize()), KS.position)
    position = KS.position

  feature = new ol.Feature(
    geometry: new ol.geom.Point(position)
  )

  KS.newFeatureInteraction = new ol.interaction.Modify(
    features: new ol.Collection([feature])
    pixelTolerance: 50
    style: KS.newFeatureOverlay.getStyle()
  )
  KS.olMap.addInteraction KS.newFeatureInteraction
  KS.newFeatureOverlay.addFeature feature

KS.clearNewFeature= () ->
  KS.newFeatureOverlay.removeFeature feature for feature in KS.newFeatureOverlay.getFeatures().getArray()
  if KS.newFeatureInteraction
    KS.olMap.removeInteraction KS.newFeatureInteraction


$ ->
  KS.olMap = new KS.Map

  KS.map.actions().on('click', 'a.describe', (event) ->
    if KS.newFeatureOverlay.getFeatures().getArray().length > 0
      $.ajax
        url: $(@).attr('href')
        data:
          position: KS.newFeatureOverlay.getFeatures().getArray()[0].getGeometry().transform(
            KS.projection(), KS.projectionWGS84).flatCoordinates
        dataType: 'script'
    return false
  ).on('click', 'a.cancel', ->
    KS.clearNewFeature()
    KS.map.actions().addClass 'hidden'
    return false
  )
