class School < ActiveRecord::Base
  set_primary_key 'OGR_FID'
  require 'bedrock/acts_as_feature'
  acts_as_feature :geometry => 'centroid', :fields => [:OGR_FID, :schname2, :address]
  
end