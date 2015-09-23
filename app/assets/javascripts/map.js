$(function() {
  Map = function(args) {
    L.Icon.Default.imagePath = '/assets';

    var _center = args.center;
    delete args['center'];
    var _markers = args.markers;
    delete args['markers'];
    var _zoom = args.zoom;
    delete args['zoom'];

    if (_center) {
      var _map = L.map('map', args).
        setView(_center, _zoom);

      L.tileLayer('http://a.tiles.mapbox.com/v4/esd.ExcellentSchoolsDetroit/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoiZXNkIiwiYSI6InBab1ZlUWsifQ.Gwmbd8beRpVIc2kw3xs_QA', {
        minZoom: 11,
        maxZoom: 16
      }).addTo(_map);

      var customMarker = L.Marker.extend({
        options: { id: null }
      });

      var _layers = [];
      for (var m in _markers) {
        if (_markers[m].center) {
          var marker = new customMarker(
            _markers[m].center,
            {id: _markers[m].id}
          ).addTo(_map);
          marker.bindPopup(_markers[m].html);
          _layers.push(marker);
        }
      }
    }
    return {
      layers: _layers
    }
  };
});
