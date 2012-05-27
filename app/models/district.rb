class District < ActiveRecord::Base
  set_primary_key 'OGR_FID'
  require 'bedrock/acts_as_feature'
  acts_as_feature :geometry => 'SHAPE', :index => 'SHAPE', :fields => [:OGR_FID]
end
