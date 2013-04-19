var map;

function main() {
    if (Modernizr.geolocation) {
        navigator.geolocation.getCurrentPosition(lookup_subjects);
    } else {
        display_error();
    }
}

function lookup_subjects(position) {
    var lat = parseFloat(position.coords.latitude);
    var lon = parseFloat(position.coords.longitude);
    var accuracy = position.coords.accuracy;

    var loc = new google.maps.LatLng(lat, lon);
    var opts = {
        zoom: get_zoom(),
        center: loc,
        mapTypeId: google.maps.MapTypeId.ROADMAP
    };

    url = "http://experimental.worldcat.org/mapfast/services?geo=" + lat + "," + lon + ";crs=wgs84&radius=100000&mq=&sortby=distance&max-results=50";
    $.getJSON(url, display_subjects);
    map = new google.maps.Map(document.getElementById("map_canvas"), opts);

    var marker = new google.maps.Marker({
        map: map,
        position: loc,
        icon: get_centerpin(),
        title: 'Current Location',
    });

}

function display_subjects(data) {
    $.each(data.Placemark, display_subject);
}

function display_subject(index, subject) {
    // create a link to worldcat to find books for this subject
    s = subject.name.replace(/ -- /g, " ");
    url = "http://www.worldcat.org/search?q=su:" + s + "&qt=advanced";

    // create a marker for the subject
    var coords = subject.point.coordinates.split(",");
    var lat = parseFloat(coords[0]);
    var lon = parseFloat(coords[1]);
    var loc = new google.maps.LatLng(lat, lon);

    var icon = get_pushpin();

    var marker = new google.maps.Marker({
        map: map,
        icon: icon,
        position: loc,
        title: subject.name
    });

    // add a info window to the marker so that it displays when 
    // someone clicks on the marker, could be a good place
    // for some sorta javascript templating language eh?
    
    html = '<span class="map_info">' + 
             subject.name + '<br>' + 
             '(' + subject.point.coordinates + ')' +
             '<br>' + 
             '<a href="' + url + '" target="_blank">Find Books on ' + 
               '<img class="worldcat" src="http://www.worldcat.org/wcpa/rel20110216/images/logo_wcmasthead_en.png">' + 
             '</a>' +
           '</span>';
    var info = new google.maps.InfoWindow({ content: html});
    info.setPosition(loc);
    google.maps.event.addListener(marker, 'click', function() {
        info.open(map, marker);
    });
}

function display_error() {
    html = "<p class='error'>Your browser doesn't seem to support the HTML5 geolocation API. You will need either: Firefox (3.5+), Safari (5.0+) Chrome (5.0+), Opera (10.6+), iPhone (3.0+) or Android (2.0+). Sorry!</p>";
    $("#subject_list").replaceWith(html);
}

function get_pushpin() {
    return get_pin("http://maps.google.com/mapfiles/kml/pushpin/red-pushpin.png");
}

function get_centerpin() {
    return get_pin("http://maps.google.com/mapfiles/kml/pushpin/blue-pushpin.png");
}

function get_pin(url) {
    if (is_handheld()) {
        size = 84;
    } else {
        size = 30;
    }
    return new google.maps.MarkerImage(url, new google.maps.Size(64, 64), new google.maps.Point(0, 0), new google.maps.Point(0, size), new google.maps.Size(size, size));
}

function get_zoom() {
    if (is_handheld()) {
        return 15;
    } else {
        return 12;
    }
}
