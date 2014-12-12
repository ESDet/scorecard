module Bedrock
  class Map
  
    attr_accessor :div_id, :extent, :center, :zoom, :base_layers, :layers, :geolocate, :min_zoom, :max_zoom, :layer_control, :hash
  
    def initialize(options = {})
      options.each do |k,v|
        self.send("#{k}=", v)
      end
      self.div_id ||= 'map'
      self.base_layers ||= ['street']
      self.min_zoom ||= 10
    end
    
    def key
      result = {}
      layers.each do |l|
        result.merge!(l.key || {})
      end
      return result
    end
    
    def layers_hash
      #Hash[ *layers.collect { |l| [l.id, l.to_hash] }.flatten ]
      layers.collect { |l| l.to_hash }
    end
    
    
    protected
    
    def max_extent(layers)
      s = layers.collect { |l| l.extent[0][:lat] }.min
      w = layers.collect { |l| l.extent[0][:lon] }.min
      n = layers.collect { |l| l.extent[1][:lat] }.max
      e = layers.collect { |l| l.extent[1][:lon] }.max
      [ { :lat => s, :lon => w }, { :lat => n, :lon => e } ]
    end
    
  end
end
