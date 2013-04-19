# assumes jQuery and Modernizr are available

pageSize = 25 

jQuery ->
  $ = jQuery
  init()

init = ->
  if Modernizr.geolocation
    navigator.geolocation.getCurrentPosition(location)
  else
    console.log "no geo :-("

location = (position) ->
  lat = parseFloat(position.coords.latitude)
  lon = parseFloat(position.coords.longitude)
  url = "http://api.geonames.org/findNearbyWikipediaJSON?lat=#{lat}&lng=#{lon}&radius=10&username=wikimedia&maxRows=" + pageSize
  $.ajax url: url, dataType: "jsonp", jsonpCallback: 'lookup'

this.lookup = (geo) ->
  titles = (encodeURIComponent(article.title) for article in geo.geonames).join("|")
  url = "http://en.wikipedia.org/w/api.php?action=query&prop=images&format=json&titles=#{titles}&callback=?&imlimit=500" + pageSize 
  console.log url
  $.getJSON url, (wiki) ->
    results = interleave(geo, wiki)
    drawMap(results)

interleave = (geo, wiki) ->
  images = {}
  for pageId, page of wiki.query.pages
    if page.images != undefined
      images[page.title] = page.images
    else
      images[page.title] = []

  for page in geo.geonames
    page.images = images[page.title]

  return geo.geonames

drawMap = (results) ->
  dl = $("#results")
  for article in results
    dt = $("<dt><a href='http://#{ article.wikipediaUrl }'>#{ article.title }</a></dt>")
    if article.images.length == 0
      dt.addClass("needImage")
    dl.append(dt)
    dl.append($("<dd>#{ article.summary }</dd>"))
