$(document).ready(function() {
  Map = function(args) {
    L.Icon.Default.imagePath = '/assets/images';

    var _map = L.map('map').
      setView(args.center, args.zoom);

    L.tileLayer('http://a.tiles.mapbox.com/v4/esd.ExcellentSchoolsDetroit/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoiZXNkIiwiYSI6InBab1ZlUWsifQ.Gwmbd8beRpVIc2kw3xs_QA', {
      minZoom: 11,
      maxZoom: 16
    }).addTo(_map);

    var customMarker = L.Marker.extend({
      options: { id: null }
    });

    var _layers = [];
    for (var m in args.markers) {
      if (args.markers[m].center) {
        var marker = new customMarker(
          args.markers[m].center,
          {id: args.markers[m].id}
        ).addTo(_map);
        marker.bindPopup(args.markers[m].html);
        _layers.push(marker);
      }
    }
    return {
      layers: _layers
    }
  };
});
