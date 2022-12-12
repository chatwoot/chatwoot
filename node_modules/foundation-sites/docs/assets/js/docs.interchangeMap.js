!function() {
var loaded = false;
$('#docs-example-interchange').on('replaced.zf.interchange', function() {
  if(Foundation.MediaQuery.atLeast('large')){
    if(!loaded){
      $.getScript("https://maps.googleapis.com/maps/api/js?key=AIzaSyBOVwxUM9akvFrSWmmb2iKc7Fe0vjRBY7c&sensor=false&callback=initializeMaps")
      .done(function(){
        loaded = true;
      });
    }else{
      window.initializeMaps();
    }
  }
});

window.initializeMaps = function() {
  // Basic options for a simple Google Map
  // For more options see: https://developers.google.com/maps/documentation/javascript/reference#MapOptions
  var mapOptions = {
    // How zoomed in you want the map to start at (always required)
    zoom: 11,

    // The latitude and longitude to center the map (always required)
    center: new google.maps.LatLng(37.2845934,-121.951675), // ZURB HQ

    // How you would like to style the map.
    // This is where you would paste any style found on Snazzy Maps.
    styles: [{'featureType':'water','stylers':[{'visibility':'on'},{'color':'#acbcc9'}]},{'featureType':'landscape','stylers':[{'color':'#f2e5d4'}]},{'featureType':'road.highway','elementType':'geometry','stylers':[{'color':'#c5c6c6'}]},{'featureType':'road.arterial','elementType':'geometry','stylers':[{'color':'#e4d7c6'}]},{'featureType':'road.local','elementType':'geometry','stylers':[{'color':'#fbfaf7'}]},{'featureType':'poi.park','elementType':'geometry','stylers':[{'color':'#c5dac6'}]},{'featureType':'administrative','stylers':[{'visibility':'on'},{'lightness':33}]},{'featureType':'road'},{'featureType':'poi.park','elementType':'labels','stylers':[{'visibility':'on'},{'lightness':20}]},{},{'featureType':'road','stylers':[{'lightness':20}]}]
  };

  // Get the HTML DOM element that will contain your map
  // We are using a div with id="map" seen below in the <body>
  var mapElement = document.getElementById('map');

  // Create the Google Map using out element and options defined above
  var map = new google.maps.Map(mapElement, mapOptions);
  var markerOptions = {
    map: map,
    position: {lat: 37.2845934, lng: -121.951675},
    title: 'ZURB HQ'
  };
  var marker = new google.maps.Marker(markerOptions);
};

}();
