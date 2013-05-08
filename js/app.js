// Generated by CoffeeScript 1.5.0
(function() {
  var defaultZoom, display, displayResults, drawMap, getMarker, layer, locate, map, markers, pageSize, refreshRate, searchWikipedia, seenPosition,
    _this = this,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  map = null;

  layer = null;

  markers = {};

  seenPosition = {};

  pageSize = 100;

  refreshRate = 30 * 1000;

  defaultZoom = 16;

  jQuery(function() {
    var $;
    $ = jQuery;
    if ($.bbq.getState('lat') && $.bbq.getState('lon') && $.bbq.getState('zoom')) {
      return display();
    } else {
      return locate();
    }
  });

  locate = function() {
    if (Modernizr.geolocation) {
      return navigator.geolocation.getCurrentPosition(function(pos) {
        var lat, lon;
        lat = parseInt(pos.coords.latitude * 10000) / 10000;
        lon = parseInt(pos.coords.longitude * 10000) / 10000;
        $.bbq.pushState({
          lat: lat,
          lon: lon,
          zoom: defaultZoom
        });
        return display();
      });
    }
  };

  display = function() {
    var lat, lon, zoom;
    lat = $.bbq.getState('lat');
    lon = $.bbq.getState('lon');
    zoom = $.bbq.getState('zoom');
    drawMap(lat, lon, zoom);
    if (seenPosition["" + lat + ":" + lon]) {
      return;
    }
    seenPosition["" + lat + ":" + lon] = true;
    layer.fire('data:loading');
    console.log("spinner on");
    return searchWikipedia(lat, lon, displayResults);
  };

  searchWikipedia = function(lat, lon, callback, results, queryContinue) {
    var continueParams, name, param, q, url;
    url = "http://en.wikipedia.org/w/api.php";
    q = {
      action: "query",
      prop: "info|extracts|coordinates|pageprops|templates",
      tllimit: 500,
      exlimit: "max",
      exintro: 1,
      explaintext: 1,
      generator: "geosearch",
      ggsradius: 5000,
      ggscoord: "" + lat + "|" + lon,
      ggslimit: 200,
      format: "json"
    };
    continueParams = {
      extracts: "excontinue",
      coordinates: "cocontinue",
      templates: "tlcontinue"
    };
    if (queryContinue) {
      for (name in continueParams) {
        param = continueParams[name];
        if (queryContinue[name]) {
          q[param] = queryContinue[name][param];
        }
      }
    }
    console.log(q.excontinue, q.cocontinue, q.tlcontinue);
    console.log(q);
    return $.ajax({
      url: url,
      data: q,
      dataType: "jsonp",
      success: function(response) {
        var article, articleId, newValues, prop, resultsArticle, _ref;
        if (!results) {
          results = response;
        }
        _ref = response.query.pages;
        for (articleId in _ref) {
          article = _ref[articleId];
          resultsArticle = results.query.pages[articleId];
          for (prop in continueParams) {
            if (prop === 'extracts') {
              prop = 'extract';
            }
            newValues = article[prop];
            if (!newValues) {
              continue;
            }
            if (Array.isArray(newValues)) {
              if (!resultsArticle[prop]) {
                resultsArticle[prop] = [];
              }
              resultsArticle[prop] = resultsArticle[prop].concat(newValues);
            } else {
              resultsArticle[prop] = article[prop];
            }
          }
        }
        if (response['query-continue']) {
          if (!queryContinue) {
            queryContinue = response['query-continue'];
          } else {
            for (name in continueParams) {
              param = continueParams[name];
              if (response['query-continue'][name]) {
                queryContinue[name] = response['query-continue'][name];
              }
            }
          }
          return searchWikipedia(lat, lon, callback, results, queryContinue);
        } else {
          layer.fire('data:loaded');
          return callback(results);
        }
      }
    });
  };

  drawMap = function(lat, lon, zoom) {
    if (!map) {
      map = L.map('map', {
        center: [lat, lon],
        zoom: zoom,
        maxZoom: 17,
        minZoom: 13
      });
      layer = L.tileLayer('http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 22
      });
      layer.addTo(map);
      map.on('dragend', function(e) {
        var center;
        center = map.getCenter();
        $.bbq.pushState({
          lat: center.lat,
          lon: center.lng
        });
        return display();
      });
      return map.on('zoomend', function(e) {
        return $.bbq.pushState({
          zoom: map.getZoom()
        });
      });
    }
  };

  displayResults = function(results) {
    var article, articleId, marker, _ref, _results;
    _ref = results.query.pages;
    _results = [];
    for (articleId in _ref) {
      article = _ref[articleId];
      if (markers[article.title]) {
        continue;
      }
      if (!article.coordinates) {
        console.log("article " + article.title + " missing geo from api");
        continue;
      }
      marker = getMarker(article);
      marker.addTo(map);
      _results.push(markers[article.title] = marker);
    }
    return _results;
  };

  getMarker = function(article) {
    var color, help, icon, marker, needsWorkTemplates, pos, template, url, _i, _len, _ref, _ref1, _ref2;
    pos = article.coordinates[0];
    url = "http://en.wikipedia.org/wiki/" + article.title.replace(' ', '_');
    icon = "book";
    color = "blue";
    needsWorkTemplates = ["Template:Copy edit", "Template:Cleanup-copyedit", "Template:Cleanup-english", "Template:Copy-edit", "Template:Copyediting", "Template:Gcheck", "Template:Grammar", "Template:Copy edit-section", "Template:Copy edit-inline", "Template messages/Cleanup", "Template:Tone"];
    _ref = article.templates;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      template = _ref[_i];
      if (_ref1 = template.title, __indexOf.call(needsWorkTemplates, _ref1) >= 0) {
        icon = "icon-edit";
        color = "orange";
        help = "This article is in need of copy-editing.";
      }
      if ((_ref2 = template.title) === "Template:Citation needed") {
        icon = "icon-external-link";
        color = "orange";
        help = "This article needs one or more citations.";
      }
    }
    if (!article.pageprops.page_image) {
      icon = "icon-camera-retro";
      color = "red";
      help = "This article needs an image.";
    }
    marker = L.marker([pos.lat, pos.lon], {
      title: article.title,
      icon: L.AwesomeMarkers.icon({
        icon: icon,
        color: color
      })
    });
    marker.bindPopup("<div class='summary'><a target='_new' href='" + url + "'>" + article.title + "</a> - " + article.extract + " <div class='help'>" + help + "</div></div>");
    return marker;
  };

}).call(this);
