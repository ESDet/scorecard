class DPS < ActiveRecord::Base
  set_primary_key 'OGR_FID'
  set_table_name '_dps'
  require 'bedrock/acts_as_feature'
  acts_as_feature :geometry => 'centroid', :fields => [:OGR_FID, :schname2, :address]
  
end