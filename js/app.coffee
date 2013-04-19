# assumes jQuery and Modernizr are available

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
  url = "http://api.geonames.org/findNearbyWikipediaJSON?lat=#{lat}&lng=#{lon}&radius=10&username=wikimedia&maxRows=20"
  $.ajax url: url, dataType: "jsonp", jsonpCallback: 'articles'

this.articles = (results) ->
  console.log results
  titles = (article.title for article in results.geonames).join("|")
  url = "http://en.wikipedia.org/w/api.php?action=query&prop=images&format=json&titles=#{titles}"
  $.ajax url: url, dataType: "jsonp", jsonpCallback: 'images'

this.images = (results) ->
  console.log results
  dl = $("#results")
  for pageId, page of results.query.pages
    dt = $("<dt>#{ page.title }</dt>")
    if not page.images
      dt.addClass("needImage")
    dl.append(dt)

