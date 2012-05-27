class Other < ActiveRecord::Base
  set_primary_key 'OGR_FID'
  set_table_name '_other'
  require 'bedrock/acts_as_feature'
  acts_as_feature :geometry => 'centroid', :fields => [:OGR_FID, :name2, :address1]
end