class School < ActiveRecord::Base
  require 'bedrock/acts_as_feature'
  require 'bedrock/acts_as_geocoded'
  
  acts_as_feature :geometry => 'centroid', :fields => [:id, :name, :address, :grades_served, :slug], :add_properties => :my_properties
  #acts_as_geocoded :address => :address, :point => :centroid, :sleep => 0.15
  utm_factory = RGeo::Geographic.projected_factory(:projection_proj4 => "+proj=utm +zone=17 +ellps=WGS84 +datum=WGS84 +units=m +no_defs")
  set_rgeo_factory_for_column(:centroid, utm_factory)
  
  require 'mogrify'
  include Mogrify
  serialize :basic, OpenStruct
  serialize :profile, OpenStruct
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
  def closed?;      false; end 
  
  def my_properties
    result = {
      :name   => self.name,
      :level  => self.high? ? 'HS' : (self.middle? ? 'MS' : 'ES'),
      :cumulative => self.grades[:cumulative][:letter]
    }
    others = School.where(['address = ? and id <> ?', self.address, self.id]).select('id, name, address, grades_served, bcode, slug')
    result[:others] = others.collect { |o| { :id => o.id, :name => o.name, :slug => o.slug, :grades => o.grades_served } } unless others.empty?
    return result
  end
  
  def esd
    esd = (self.esd_hs_2013 || self.esd_k8_2013)
  end
  
  def grades
    cat = esd.andand.schoolcategory
    
    h = { :cumulative => {}, :status => {}, :progress => {}, :climate => {}, :other => {} }
    return h if esd.nil?
    
    if self.esd_hs_2013
      # Common to all HS varieties:
      h[:status] = {
        :letter   => esd.status_ltrgrade.blank? ? '?' : esd.status_ltrgrade,
        :total    => esd.status_pts,
        :possible => esd.status_psspts   }
      h[:progress] = {
        :letter   => esd.progress_ltrgrade.blank? ? '?' : esd.progress_ltrgrade,
        :total    => esd.progress_pts,
        :possible => esd.progress_psspts }
      h[:climate] = {
        :letter   => esd.culture_ltrgrade.blank? ? '?' : esd.culture_ltrgrade,
        :total    => esd.culture_pts,
        :possible => esd.culture_psspts }
      h[:other] = {
        :total    => esd.studchrs_pts.to_i + esd.fafsa_rate_pts.to_i }

      if cat == 'Mature'
        h[:cumulative] = {
          :letter   => esd.mature_ltrgrade.blank? ? '?' : esd.mature_ltrgrade,
          :total    => esd.total_pts,
          :possible => esd.total_psspts,
          :percent  => esd.mature_pct }
      
      elsif cat == 'New'
        h[:cumulative] = {
          :letter   => esd.newschool_designation.blank? ? '?' : esd.newschool_designation,
          :total    => esd.total_pts,
          :possible => esd.total_psspts,
          :percent  => esd.newschool_pct }
          
      elsif cat == 'Turnaround'
        h[:cumulative] = {
          :letter   => esd.turnaround_designation.blank? ? '?' : esd.turnaround_designation,
          :total    => esd.turnaround_pts,
          :possible => esd.turnaround_psspts,
          :percent  => esd.turnaround_pct }
      end
      
    elsif self.esd_k8_2013
      # Common to all the K8 varieties..
      h[:status] = {
        :letter   => esd.status_ltrgrade.blank? ? '?' : esd.status_ltrgrade,
        :total    => esd.pts_status,
        :possible => esd.ptspos_status }
      h[:progress] = {
        :letter   => esd.progress_ltrgrade.blank? ? '?' : esd.progress_ltrgrade,
        :total    => esd.pts_progress,
        :possible => esd.ptspos_progress }
      h[:climate] = {
        :letter   => esd.culture_ltrgrade.blank? ? '?' : esd.culture_ltrgrade,
        :total    => esd.pts_culture,
        :possible => esd.ptspos_culture }
      h[:other] = {
        :total    => esd.studchrs_pts }

      if cat == 'Mature'
        h[:cumulative] = {
          :letter   => esd.mature_ltrgrade.blank? ? '?' : esd.mature_ltrgrade,
          :total    => esd.pts_earned,
          :possible => esd.pts_possible,
          :percent  => esd.mature_pct }
        
      elsif cat == 'New'
        h[:cumulative] = {
          :letter   => esd.newschool_designation.blank? ? '?' : esd.newschool_designation,
          :total    => esd.pts_earned,
          :possible => esd.pts_possible,
          :percent  => esd.newschool_pct }
      
      elsif cat == 'Turnaround'
        h[:cumulative] = {
          :letter   => esd.turnaround_designation.blank? ? '?' : esd.turnaround_designation,
          :total    => esd.turnaround_pts_earned,
          :possible => esd.turnaround_pts_possible,
          :percent  => esd.turnaround_pct }
      end
    
    end
    return h
  end
  
  def set_slug
    self.name ||= "School #{self.bcode}"
    self.slug = transliterate(self.name)
  end
      
end