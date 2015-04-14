require 'bedrock/engine'
require 'bedrock/tile_helper'
require 'bedrock/acts_as_feature'
require 'bedrock/acts_as_geocoded'

module Bedrock
  mattr_accessor :config_hash
  mattr_accessor :cloudmade_key, :cloudmade_style
  mattr_accessor :default_city, :default_state
  mattr_accessor :autocomplete_table, :autocomplete_column

  def self.setup
    yield self
  end

  @@city_extents = {
    'detroit'     => [ { :lat => 42.254038, :lon => -83.28793 }, { :lat => 42.4620, :lon => -82.897 } ],
    'wayne'       => [ { :lat => 42.01665183556825, :lon => -83.56887817382812 }, { :lat => 42.47108395294282, :lon => -82.84790039062499 } ],
    'macomb'      => [ { :lat => 42.4275113263909, :lon => -83.14178466796875 }, { :lat => 42.91821786558452, :lon => -82.694091796875 } ],
    'new-orleans' => [ { :lat => 29.861, :lon => -90.148 }, { :lat => 30.179, :lon => -89.619 } ],
    'nola'        => [ { :lat => 29.861, :lon => -90.148 }, { :lat => 30.179, :lon => -89.619 } ],
    'nyc'         => [ { :lat => 40.447, :lon => -74.541 }, { :lat => 40.947, :lon => -73.253 } ],
    'us'          => [ { :lat => 23.5, :lon => -127.3 }, { :lat => 48.5, :lon => -64.6 } ],
  }
  def self.city_extents(city)
    @@city_extents[city.to_s]
  end

  def self.extent(env)
    if env.nil?
      ::Rails.logger.info "Bedrock.extent returning nil cause it got nil envelope"
      return nil
    end
    return [ { :lon => env.min_x, :lat => env.min_y }, { :lon => env.max_x, :lat => env.max_y } ] if env.is_a? RGeo::Cartesian::BoundingBox

    if env.is_a? Array or env.is_a?(ActiveRecord::Relation)
      return nil if env.empty?
      bb = RGeo::Cartesian::BoundingBox.new(env[0].geometry.factory)
      env.each { |f| bb.add f.geometry }
      return [ { :lon => bb.min_x, :lat => bb.min_y }, { :lon => bb.max_x, :lat => bb.max_y } ]
    end

    pts = env.exterior_ring.points
    [ { :lon => pts[0].x, :lat => pts[0].y },
      { :lon => pts[2].x, :lat => pts[2].y } ]
  end

  def self.merge_extents(a, b)
    return a if b.nil?
    return b if a.nil?
    [ { :lon => [a[0][:lon], b[0][:lon]].min, :lat => [a[0][:lat], b[0][:lat]].min },
      { :lon => [a[1][:lon], b[1][:lon]].max, :lat => [a[1][:lat], b[1][:lat]].max } ]
  end


  def self.to_feature_collection(elements)
    elements = elements.to_a if elements.is_a? ActiveRecord::Relation
    elements = [elements] unless elements.is_a? Array
    features = elements.reject { |e| e.nil? or e.geometry.nil? }.collect { |e| e.to_feature }
    fc = RGeo::GeoJSON::FeatureCollection.new(features)
    begin
      return RGeo::GeoJSON.encode(fc)
    rescue => e
      ::Rails.logger.info e.inspect
      ::Rails.logger.info e.backtrace
      return RGeo::GeoJSON.encode(RGeo::GeoJSON::FeatureCollection.new([]))
    end
  end

end
