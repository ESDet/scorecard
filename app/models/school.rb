class School < ActiveRecord::Base
  require 'bedrock/acts_as_feature'
  require 'bedrock/acts_as_geocoded'
  
  acts_as_feature :geometry => 'centroid', :fields => [:id, :SCHOOL_NAME_2011, :SCHOOL_STREET_ADDRESS_2012, :AUTHORIZED_GRADES_2012, :TEMPLATE, :slug], :add_properties => :my_properties
  #acts_as_geocoded :address => :SCHOOL_STREET_ADDRESS_2012, :point => :centroid, :sleep => 0.15
  utm_factory = RGeo::Geographic.projected_factory(:projection_proj4 => "+proj=utm +zone=17 +ellps=WGS84 +datum=WGS84 +units=m +no_defs")
  set_rgeo_factory_for_column(:centroid, utm_factory)
  
  #def name; self['name'].andand.gsub('_', ' '); end
    
  require 'mogrify'
  include Mogrify
  serialize :meap_2012, OpenStruct
  serialize :esd_k8_2013, OpenStruct
  serialize :esd_hs_2013, OpenStruct
  before_save :set_slug
  

  def self.square_array(arr)
    result = []
    arr.each_with_index do |a,i|
      arr[i+1..-1].each do |b|
        result << "#{a}-#{b}"
      end
    end
    return result
  end


  GRADES = {
    :p2         => 'pk',
    :elementary => '1, 2, 3, 4, 5',
    :middle     => '6, 7, 8',
    :high       => '9, 10, 11, 12',
    :k8         => 'KF, 1, 2, 3, 4, 5, 6, 7, 8',
  }
  
  TYPES = {
    :charter          => 'Charter',
    :dps              => 'DPS',
    :dps_charter      => 'DPS Charter',
    :dps_rising       => 'DPS Detroit Rising',
    :dps_traditional  => 'DPS Traditional',
    :eaa              => 'EAA',
    :eaa_charter      => 'EAA Charter',
    :independent      => 'Independent',
    :parochial        => 'Parochial',
    :traditional      => 'Traditional public',
  }
  
  GRADES.each do |k,v|
    scope k,         where("grades_served like '%#{v}%'")
  end
  
  TYPES.each do |k,v|
    scope k,         where(:SCHOOL_TYPE_2012 => v)
  end
  
  def elementary?;  grades_served.andand.include? GRADES[:elementary]; end
  def middle?;      grades_served.andand.include? GRADES[:middle];      end
  def high?;        grades_served.andand.include? GRADES[:high]; end
  def k8?;          grades_served.andand.include? GRADES[:k8]; end
  def closed?;      false; end #!self.CLOSE_DATE.blank?;      end
  
  def my_properties
    result = {
      :name => self.name
    }
    others = School.where(['SCHOOL_STREET_ADDRESS_2012 = ? and id <> ?', self.SCHOOL_STREET_ADDRESS_2012, self.id]).select('id, SCHOOL_NAME_TEMPLATE_2011, SCHOOL_STREET_ADDRESS_2012, AUTHORIZED_GRADES_2012, TEMPLATE, slug')
    result[:others] = others.collect { |o| { :id => o.id, :name => o.name, :slug => o.slug, :grades => o.AUTHORIZED_GRADES_2012 } } unless others.empty?
    return result
  end
  
  def set_slug
    self.name ||= "School #{self.bcode}"
    self.slug = transliterate(self.name)
  end
      
end