// Generated by CoffeeScript 1.5.0
(function() {
  var drawMap, init, interleave, location, pageSize;

  pageSize = 25;

  jQuery(function() {
    var $;
    $ = jQuery;
    return init();
  });

  init = function() {
    if (Modernizr.geolocation) {
      return navigator.geolocation.getCurrentPosition(location);
    } else {
      return console.log("no geo :-(");
    }
  };

  location = function(position) {
    var lat, lon, url;
    lat = parseFloat(position.coords.latitude);
    lon = parseFloat(position.coords.longitude);
    url = ("http://api.geonames.org/findNearbyWikipediaJSON?lat=" + lat + "&lng=" + lon + "&radius=10&username=wikimedia&maxRows=") + pageSize;
    return $.ajax({
      url: url,
      dataType: "jsonp",
      jsonpCallback: 'lookup'
    });
  };

  this.lookup = function(geo) {
    var article, titles, url;
    titles = ((function() {
      var _i, _len, _ref, _results;
      _ref = geo.geonames;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        article = _ref[_i];
        _results.push(encodeURIComponent(article.title));
      }
      return _results;
    })()).join("|");
    url = ("http://en.wikipedia.org/w/api.php?action=query&prop=images&format=json&titles=" + titles + "&callback=?&imlimit=500") + pageSize;
    console.log(url);
    return $.getJSON(url, function(wiki) {
      var results;
      results = interleave(geo, wiki);
      return drawMap(results);
    });
  };

  interleave = function(geo, wiki) {
    var images, page, pageId, _i, _len, _ref, _ref1;
    images = {};
    _ref = wiki.query.pages;
    for (pageId in _ref) {
      page = _ref[pageId];
      if (page.images !== void 0) {
        images[page.title] = page.images;
      } else {
        images[page.title] = [];
      }
    }
    _ref1 = geo.geonames;
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      page = _ref1[_i];
      page.images = images[page.title];
    }
    return geo.geonames;
  };

  drawMap = function(results) {
    var article, dl, dt, _i, _len, _results;
    dl = $("#results");
    _results = [];
    for (_i = 0, _len = results.length; _i < _len; _i++) {
      article = results[_i];
      dt = $("<dt><a href='http://" + article.wikipediaUrl + "'>" + article.title + "</a></dt>");
      if (article.images.length === 0) {
        dt.addClass("needImage");
      }
      dl.append(dt);
      _results.push(dl.append($("<dd>" + article.summary + "</dd>")));
    }
    return _results;
  };

}).call(this);
