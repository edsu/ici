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
        console.log "#{title} needs image"
        $(li).addClass("needImage")

getImages = (title, callback) ->
  url = "http://en.wikipedia.org/w/api.php?action=query&prop=images&format=json&titles=#{title}&callback=?&imlimit=500"
  $.getJSON url, (data) ->
    images = []
    for pageId, page of data.query.pages
      if page.images?
        images = page.images
      break
    callback(images)
