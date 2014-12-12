module Bedrock
  module ActsAsGeocoded
    extend ActiveSupport::Concern

    included do
    end
    
    module ClassMethods
      def acts_as_geocoded(options = {})
        cattr_accessor :address_field, :point_field, :required, :geocode_delay
        self.address_field = options[:address]
        self.point_field   = options[:point]
        self.required      = options[:required]
        self.geocode_delay = options[:delay]
        throw "Must specificy :address and :point column names." unless self.address_field and self.point_field
        self.before_save :geocode_address
      end
    end

    # TODO: Validate it, prevent save if the addy didn't code
    def geocode_address
      if self.address_field.is_a?(String) and self.address_field.include?('#')
        query_address = eval('"' + self.address_field + '"')
        #puts "geocode_address: #{query_address} with address_field #{self.address_field}"
      else
        return unless self.send("#{address_field}_changed?") or self[self.point_field].nil? or self[self.point_field].x == 0
        query_address = self.send(address_field)
      end
      geo = Bedrock::Geocoder.geocode(query_address)
      self[self.point_field] = RGeo::Geographic.spherical_factory.point(geo.andand[:location].andand[:lon] || 0, geo.andand[:location].andand[:lat] || 0)
      sleep self.geocode_delay if self.geocode_delay
      return geo
    end
        
  end
end


ActiveRecord::Base.send :include, Bedrock::ActsAsGeocoded