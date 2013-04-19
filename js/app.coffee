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
  url = "http://en.wikipedia.org/w/api.php?action=query&prop=images&format=json&titles=#{titles}&callback=?&imlimit=500"
  console.log url
  $.getJSON url, (wiki) ->
    results = interleave(geo, wiki)
    output(results)

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

output = (results) ->
  ul = $("#results")
  for article in results
    li = $("<li><a class='title' href='http://#{ article.wikipediaUrl }'>#{ article.title }</a><span class='summary hidden-phone'>: #{ article.summary }</span></li>")
    if article.images.length == 0
      li.addClass("needImage")
    ul.append(li)
