class School < ActiveRecord::Base
  require 'bedrock/acts_as_feature'
  require 'bedrock/acts_as_geocoded'
  acts_as_feature :geometry => 'centroid', :fields => [:id, :SCHOOL_NAME_2011, :SCHOOL_STREET_ADDRESS_2011, :AUTHORIZED_GRADES_2011], :add_properties => :my_properties
  acts_as_geocoded :address => :SCHOOL_STREET_ADDRESS_2011, :point => :centroid
  
  def name; self['SCHOOL_NAME_2011']; end
  
  scope :elementary, where(:AUTHORIZED_GRADES_2011 => ['K-5'])
  scope :middle,     where(:AUTHORIZED_GRADES_2011 => ['6-8'])
  scope :high,       where(:AUTHORIZED_GRADES_2011 => ['9-12'])
  
  def elementary?; self.id % 3 == 0; end
  def middle?;     self.id % 3 == 1; end
  def high?;       self.id % 3 == 2; end
  
  def my_properties
    { :level => self.id % 3 }
  end
    
end