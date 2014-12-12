module Bedrock
  module TileHelper
    
    def self.included(c)
       #c.helper_method :tileSize
    end        
  
    def tileSize
      256
    end
    def initialResolution
     2 * Math::PI * 6378137 / tileSize
     # 156543.03392804062 for tileSize 256 pixels
    end
    def originShift
      2 * Math::PI * 6378137 / 2.0
      # 20037508.342789244
    end
    def TileLatLonBounds(tx, ty, zoom)
      bounds = TileBounds(tx, ty, zoom)
      minLat, minLon = MetersToLatLon(bounds[0], bounds[1])
      maxLat, maxLon = MetersToLatLon(bounds[2], bounds[3])
      return [-maxLat, minLon, -minLat, maxLon]
    end
    def TileBounds(tx, ty, zoom)
      minx, miny = PixelsToMeters( tx*tileSize, ty*tileSize, zoom )
      maxx, maxy = PixelsToMeters( (tx+1)*tileSize, (ty+1)*tileSize, zoom )
      return [minx, miny, maxx, maxy]
    end  
    # Converts XY point from Spherical Mercator EPSG:900913 to lat/lon in WGS84 Datum
    def MetersToLatLon(mx, my)
        lon = (mx / originShift) * 180.0
        lat = (my / originShift) * 180.0
        lat = 180 / Math::PI * (2 * Math::atan(Math::exp(lat * Math::PI / 180.0)) - Math::PI / 2.0)
        return [lat, lon]
    end
    #"Converts pixel coordinates in given zoom level of pyramid to EPSG:900913"
    def PixelsToMeters(px, py, zoom)
      res = Resolution( zoom )
      mx = px * res - originShift
      my = py * res - originShift
      return [mx, my]
    end
    #"Resolution (meters/pixel) for given zoom level (measured at Equator)"
    def Resolution(zoom)
      # return (2 * math.pi * 6378137) / (self.tileSize * 2**zoom)
      return initialResolution / (2**zoom)
    end
    
  end
end  