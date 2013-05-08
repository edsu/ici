# assumes jquery, modernizr and bbq are available

map = null
layer = null
markers = {}
seenPosition = {}
pageSize = 100
refreshRate = 30 * 1000
defaultZoom = 16

jQuery ->
  $ = jQuery
  if $.bbq.getState('lat') and $.bbq.getState('lon') and $.bbq.getState('zoom')
    display()
  else
    locate()

#
# get geolocation from the browser
#

locate = =>
  if Modernizr.geolocation
    navigator.geolocation.getCurrentPosition (pos) ->
      lat = parseInt(pos.coords.latitude * 10000) / 10000
      lon = parseInt(pos.coords.longitude * 10000) / 10000
      $.bbq.pushState(lat: lat, lon: lon, zoom: defaultZoom)
      display()

#
# display the map 
#

display = =>
  lat = $.bbq.getState('lat')
  lon = $.bbq.getState('lon')
  zoom = $.bbq.getState('zoom')
  drawMap(lat, lon, zoom)

  # don't look up same lat/lon more than once
  if seenPosition["#{lat}:#{lon}"]
    return

  seenPosition["#{lat}:#{lon}"] = true

  layer.fire('data:loading')
  searchWikipedia(lat, lon, displayResults)

#
# search Wikipedia by lat/lon, this is called recursively until 
# all data for the search is retrieved, afterwhich the collected
# results are sent to the supplied callback
#

searchWikipedia = (lat, lon, callback, results, queryContinue) =>
  url = "http://en.wikipedia.org/w/api.php"
  q =
    action: "query"
    prop: "info|extracts|coordinates|pageprops|templates"
    tllimit: 500
    exlimit: "max"
    exintro: 1
    explaintext: 1
    generator: "geosearch"
    ggsradius: 5000
    ggscoord: "#{lat}|#{lon}"
    ggslimit: 200
    format: "json"

  # add continue parameters if they have been provided
  
  continueParams =
    extracts: "excontinue"
    coordinates: "cocontinue"
    templates: "tlcontinue"

  if queryContinue
    for name, param of continueParams
      if queryContinue[name]
        q[param] = queryContinue[name][param]

  $.ajax url: url, data: q, dataType: "jsonp", success: (response) =>
    if not results
      results = response

    for articleId, article of response.query.pages
      resultsArticle = results.query.pages[articleId]

      # this parameter is singular in article data...
      for prop of continueParams
        if prop == 'extracts'
          prop = 'extract'

        # continue if there are no new values to merge 
        newValues = article[prop]
        if not newValues
          continue

        # merge arrays by concatenating with old values
        if Array.isArray(newValues)
          if not resultsArticle[prop]
            resultsArticle[prop] = []
          resultsArticle[prop] = resultsArticle[prop].concat(newValues)

        # otherwise just assign
        else
          resultsArticle[prop] = article[prop]

    if response['query-continue']
      if not queryContinue
        queryContinue = response['query-continue']
      else
        for name, param of continueParams
          if response['query-continue'][name]
            queryContinue[name] = response['query-continue'][name]
     
      searchWikipedia(lat, lon, callback, results, queryContinue)
    else

      # whew we're all done now
      layer.fire('data:loaded')
      callback(results)

#
# render the map with an OpenStreetMap layer
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

#
# display wikipedia search results on the map
#

displayResults = (results) =>
  for articleId, article of results.query.pages
    if markers[article.title]
      continue

    # can't add it to the map if the API won't tell us the coordinates :(
    if not article.coordinates
      console.log "article #{article.title} missing geo from api"
      continue

    marker = getMarker(article)
    marker.addTo(map)
    markers[article.title] = marker

#
# create the appropriate map marker for a given article
#

getMarker = (article) =>
  pos = article.coordinates[0]
  url = "http://en.wikipedia.org/wiki/" + article.title.replace(' ', '_')
  icon = "book"
  color = "blue"

  needsWorkTemplates = [
    "Template:Copy edit",
    "Template:Cleanup-copyedit",
    "Template:Cleanup-english",
    "Template:Copy-edit",
    "Template:Copyediting",
    "Template:Gcheck",
    "Template:Grammar",
    "Template:Copy edit-section",
    "Template:Copy edit-inline",
    "Template messages/Cleanup",
    "Template:Tone",
  ]

  for template in article.templates
    if template.title in needsWorkTemplates
      icon = "icon-edit"
      color = "orange"
      help = "This article is in need of copy-editing." 
    if template.title in ["Template:Citation needed"]
      icon = "icon-external-link"
      color = "orange"
      help = "This article needs one or more citations."
  if not article.pageprops.page_image
    icon = "icon-camera-retro"
    color = "red"
    help = "This article needs an image."

  marker = L.marker [pos.lat, pos.lon], {title: article.title, icon: L.AwesomeMarkers.icon({icon: icon, color: color})}
  marker.bindPopup("<div class='summary'><a target='_new' href='#{url}'>#{article.title}</a> - #{article.extract} <div class='help'>#{help}</div></div>")

  return marker
