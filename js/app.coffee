# assumes jquery, modernizr and bbq are available

map = null
markers = {}
seenPosition = {}
pageSize = 100
refreshRate = 60 * 1000

jQuery ->
  $ = jQuery
  if $.bbq.getState('lat') and $.bbq.getState('lon')
    display()
  else
    locate()

locate = =>
  if Modernizr.geolocation
    navigator.geolocation.getCurrentPosition (pos) ->
      lat = parseInt(pos.coords.latitude * 10000) / 10000
      lon = parseInt(pos.coords.longitude * 10000) / 10000
      $.bbq.pushState(lat: lat, lon: lon)
      display()
      navigator.geolocation.getCurrentPosition = (cb) ->
        lat -= .01
        cb({coords: {latitude: lat, longitude: lon}})

display = =>
  lat = $.bbq.getState('lat')
  lon = $.bbq.getState('lon')
  # don't look up same lat/lon more than once
  if seenPosition["#{lat}:#{lon}"]
    return
  seenPosition["#{lat}:#{lon}"] = true
  url = "http://api.geonames.org/findNearbyWikipediaJSON?lat=#{lat}&lng=#{lon}&radius=30&username=wikimedia&maxRows=" + pageSize
  console.log url
  $.ajax url: url, dataType: "jsonp", success: articles
  drawMap(lat, lon)

articles = (geo) =>
  for article in geo.geonames
    url = "http://" + article.wikipediaUrl

    if markers[article.title]
      continue

    marker = L.marker [article.lat, article.lng], {title: article.title, icon: L.AwesomeMarkers.icon({icon: 'book', color: 'blue'}) }
    marker.addTo(map)
    marker.bindPopup("<div class='summary'><a target='_new' href='#{url}'>#{article.title}</a> - #{article.summary}</div>")
    markers[article.title] = marker

  checkImages()

checkImages = =>
  for title, marker of markers
    if marker.checked == true
      continue
    marker.checked = true
    getImages title, (title, images) =>
      if images.length == 0
        console.log title, images
        marker = markers[title]
        red = L.AwesomeMarkers.icon(icon: 'icon-camera-retro', color: 'red')
        marker.setIcon(red)
        marker.update()

getImages = (title, callback) =>
  url = "http://en.wikipedia.org/w/api.php?action=query&prop=images&format=json&titles=#{title}&callback=?&imlimit=500"
  $.getJSON url, (data) ->
    images = []
    for pageId, page of data.query.pages
      if page.images?
        images = page.images
      break
    callback(title, images)

drawMap = (lat, lon) =>
  if not map
    map = L.map('map').setView([lat, lon], 14)
    layer = L.tileLayer 'http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', maxZoom:22 
    layer.addTo(map)

    map.on 'dragend', (e) ->
      center = map.getCenter()
      console.log center
      $.bbq.pushState(lat: center.lat, lon: center.lng)
      display()
  else
    console.log("moving to #{lat} #{lon}")
    map.setView([lat, lon], 14)
    display()

