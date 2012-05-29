class School < ActiveRecord::Base
  require 'bedrock/acts_as_feature'
  acts_as_feature :geometry => 'centroid', :fields => [:id, :SCHOOL_NAME_2011]
  
  def name; self['SCHOOL_NAME_2011']; end
  
end