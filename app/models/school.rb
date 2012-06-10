class School < ActiveRecord::Base
  require 'bedrock/acts_as_feature'
  acts_as_feature :geometry => 'centroid', :fields => [:id, :SCHOOL_NAME_2011]
  
  def name; self['SCHOOL_NAME_2011']; end
  
  def elementary?; self.id % 3 == 0; end
  def middle?;     self.id % 3 == 1; end
  def high?;       self.id % 3 == 2; end
  
end