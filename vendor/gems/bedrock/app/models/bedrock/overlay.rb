module Bedrock
  class Overlay
    @@accessors = [:id, :name, :ty, :extent, :elements, :url, :template, :style, :style_handler,
      :key, :names, :interaction, :mouseover, :geometry_type, :zindex, :hide]
    attr_accessor *@@accessors
    
    def initialize(options = {})
      options.each do |k,v|
        begin; self.send("#{k}=", v); rescue; end
      end
      self.elements = Bedrock::to_feature_collection(self.elements.to_a) unless self.elements.is_a?(Hash) or self.elements.nil?
      self.ty ||= :geojson if self.elements or self.url # backwards compatibility
      self.name ||= self.id  # Allow a friendly name in addition to layer id
    end
    
    def self.from_config(name, options={})
      config = Bedrock.config_hash['layers'][name]
      config2 = {:id => name}.merge(config).merge(options)
      o = Overlay.new(config2)
    end

    def to_hash
      Hash[ *@@accessors.collect { |a| [a, self.send(a)] }.flatten ]
      #result = {}
      #@@accessors.each { |a| result[a] = self.send(a) }
      #return result
    end
    
  end
end
