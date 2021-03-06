Map = function(args) {
  L.Icon.Default.imagePath = '/assets';

  var _center = args.center;
  delete args['center'];
  var _markers = args.markers;
  delete args['markers'];
  var _zoom = args.zoom;
  delete args['zoom'];

  var _addMarkersToMap = function(schools) {
    for (var m in schools) {
      if (schools[m].center) {
        var marker = new customMarker(
          schools[m].center,
          {id: schools[m].id}
        ).addTo(_map);
        marker.bindPopup(schools[m].html);
        _layers.push(marker);
      }
    }
  };

  var _showMarkers = function(ids) {
    $(_layers).each(function(i, n) {
      if (ids.indexOf(parseInt(n.options.id)) != -1) {
        n._icon.style.display = 'block';
        n._shadow.style.display = 'block';
      } else {
        n._icon.style.display = 'none';
        n._shadow.style.display = 'none';
      }
    });
  }

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
    _addMarkersToMap(_markers);
  }

  return {
    addMarkersToMap: _addMarkersToMap,
    showMarkers: _showMarkers,
    layers: _layers
  }
};
