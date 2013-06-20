# assumes jquery, modernizr and bbq are available

map = null
layer = null
markers = {}
seenPosition = {}
resultLimit = 200
refreshRate = 30 * 1000
defaultZoom = 16
language = 'en'

jQuery ->
  $ = jQuery

  # update the map if the language is changed
  $('select[name="language"]').change ->
    language = $(this).val()
    for name, marker of markers
      console.log marker
      map.removeLayer(marker)
    display()

  if $.bbq.getState('lat') and $.bbq.getState('lon')
    display()
  else
    locate()

#
# get geolocation from the browser
#

locate = =>
  if Modernizr.geolocation
    navigator.geolocation.getCurrentPosition(
      (pos) ->
        lat = parseInt(pos.coords.latitude * 10000) / 10000
        lon = parseInt(pos.coords.longitude * 10000) / 10000
        $.bbq.pushState(lat: lat, lon: lon, zoom: defaultZoom, lang: language)
        display()
      (error) ->
        lat = lat=38.8951
        lon = -77.0363
        zoom = defaultZoom
        $.bbq.pushState(lat: lat, lon: lon, zoom: defaultZoom, lang: language)
        $("#byline").replaceWith("HTML Geo features are not available in your browser ... so here's Washington DC")
        display()
      timeout: 10000
    )

#
# display the map 
#

display = =>
  lat = $.bbq.getState('lat')
  lon = $.bbq.getState('lon')
  zoom = $.bbq.getState('zoom') or defaultZoom
  drawMap(lat, lon, zoom)

  radius = mapRadius()
  if radius > 10000
    radius = 10000

  # don't look up same lat/lon more than once
  if seenPosition["#{lat}:#{lon}:#{radius}:#{language}"]
    return
  seenPosition["#{lat}:#{lon}:#{radius}"] = true

  layer.fire('data:loading')
  geojson(
    [lon, lat],
    language: language,
    limit: resultLimit
    radius: radius
    images: true
    summaries: true
    templates: true
    displayResults
  )

#
# render the map 
#

drawMap = (lat, lon, zoom) =>
  if not map
    map = L.map 'map',
      center: [lat, lon]
      zoom: zoom
      maxZoom: 17
      minZoom: 13
    layer = L.tileLayer 'http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', maxZoom:22
    layer.addTo(map)

    map.on 'dragend', (e) ->
      center = map.getCenter()
      $.bbq.pushState(lat: center.lat, lon: center.lng)
      display()

    map.on 'zoomend', (e) ->
      $.bbq.pushState(zoom: map.getZoom())
      display()
      
#
# display wikipedia search results on the map
#

displayResults = (results) =>
  for article in results.features
    if markers[article.properties.name]
      continue

    # can't add it to the map if the API won't tell us the coordinates :(
    if not article.geometry or not article.geometry.coordinates
      console.log "article #{article.properties.name} missing geo from api"
      continue

    marker = getMarker(article)
    marker.addTo(map)
    markers[article.properties.name] = marker
  layer.fire('data:loaded')

#
# create the appropriate map marker for a given article
#

getMarker = (article) =>
  pos = [article.geometry.coordinates[1],article.geometry.coordinates[0]]
  url = article.id
  icon = "book"
  color = "blue"
  help = ''

  needsWorkTemplates = [
    "Copy edit",
    "Cleanup-copyedit",
    "Cleanup-english",
    "Copy-edit",
    "Copyediting",
    "Gcheck",
    "Grammar",
    "Copy edit-section",
    "Copy edit-inline",
    "messages/Cleanup",
    "Tone",
  ]

  for template in article.properties.templates
    if template in needsWorkTemplates
      icon = "icon-edit"
      color = "orange"
      help = "This article is in need of copy-editing."
    if template in ["Citation needed", "Citation"]
      icon = "icon-external-link"
      color = "orange"
      help = "This article needs one or more citations."
  if not article.properties.image
    icon = "icon-camera-retro"
    color = "red"
    help = "This article needs an image."

  marker = L.marker pos, {title: article.properties.name, icon: L.AwesomeMarkers.icon({icon: icon, color: color})}
  summary = article.properties.summary
  if summary and summary.length > 500
    summary = summary[0..500] + " ... "
  marker.bindPopup("<div class='summary'><a target='_new' href='#{url}'>#{article.properties.name}</a> - #{summary} <div class='help'>#{help}</div></div>")

  return marker

mapRadius = ->
  ne = map.getBounds().getNorthEast()
  radius = ne.distanceTo(map.getCenter())
  console.log("radius=#{radius}")
  return radius
