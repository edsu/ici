# assumes jQuery and Modernizr are available

pageSize = 25

jQuery ->
  $ = jQuery
  init()

init = ->
  $(window).bind('hashchange', display)
  lat = $.bbq.getState('lat')
  lon = $.bbq.getState('lon')
  if lat and lon
    display()
  else if Modernizr.geolocation
    navigator.geolocation.getCurrentPosition (pos) ->
      $.bbq.pushState(lat: pos.coords.latitude, lon: pos.coords.longitude)
      display(lat, lon)
  else
    console.log "no geo :-("

display = ->
  lat = $.bbq.getState('lat')
  lon = $.bbq.getState('lon')
  console.log "display #{lat} #{lon}"
  url = "http://api.geonames.org/findNearbyWikipediaJSON?lat=#{lat}&lng=#{lon}&radius=10&username=wikimedia&maxRows=" + pageSize
  console.log url
  $.ajax url: url, dataType: "jsonp", jsonpCallback: 'articles'

this.articles = (geo) ->
  ul = $("#results")
  for article in geo.geonames
    ul.append($("<li><a class='title' href='http://#{ article.wikipediaUrl }'>#{ article.title }</a><span class='summary hidden-phone'>: #{ article.summary }</span></li>"))
  checkImages()

checkImages = ->
  $("#results li").each (i, li) ->
    title = $(this).find("a").text()
    getImages title, (images) ->
      if images.length == 0
        $(li).addClass("needImage")
      else
        $(li).addClass("hasImage")

getImages = (title, callback) ->
  url = "http://en.wikipedia.org/w/api.php?action=query&prop=images&format=json&titles=#{title}&callback=?&imlimit=500"
  $.getJSON url, (data) ->
    images = []
    for pageId, page of data.query.pages
      if page.images?
        images = page.images
      break
    callback(images)
