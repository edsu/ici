# assumes jquery, modernizr and bbq are available

seen = {}
pageSize = 25
refreshRate = 30 * 1000

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

display = =>
  lat = $.bbq.getState('lat')
  lon = $.bbq.getState('lon')
  # don't look up same lat/lon more than once
  if seen["#{lat}:#{lon}"]
    return
  seen["#{lat}:#{lon}"] = true
  url = "http://api.geonames.org/findNearbyWikipediaJSON?lat=#{lat}&lng=#{lon}&radius=10&username=wikimedia&maxRows=" + pageSize
  console.log url
  $.ajax url: url, dataType: "jsonp", success: articles
  setTimeout locate, refreshRate

articles = (geo) =>
  ul = $("#results")
  for article in geo.geonames
    url = "http://" + article.wikipediaUrl
    # do not repeatedly add the same article
    if $("a[href='#{ url }']").length == 1
      continue
    ul.prepend($("<li><a target='_new' class='title' href='#{ url }'>#{ article.title }</a><span class='summary hidden-phone'>: #{ article.summary }</span></li>").hide())
  checkImages()

checkImages = =>
  $("#results li").each (i, li) ->
    # no need to check the same article twice for images
    if $(li).data('checked')
      return

    title = $(this).find("a").text()
    getImages title, (images) ->
      if images.length == 0
        $(li).addClass("needImage")
      $(li)
        .data("checked", true)
        .slideDown()

getImages = (title, callback) =>
  url = "http://en.wikipedia.org/w/api.php?action=query&prop=images&format=json&titles=#{title}&callback=?&imlimit=500"
  $.getJSON url, (data) ->
    images = []
    for pageId, page of data.query.pages
      if page.images?
        images = page.images
      break
    callback(images)
