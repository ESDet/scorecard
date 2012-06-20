class School < ActiveRecord::Base
  require 'bedrock/acts_as_feature'
  require 'bedrock/acts_as_geocoded'
  acts_as_feature :geometry => 'centroid', :fields => [:id, :SCHOOL_NAME_2011, :SCHOOL_STREET_ADDRESS_2011, :AUTHORIZED_GRADES_2011], :add_properties => :my_properties
  acts_as_geocoded :address => :SCHOOL_STREET_ADDRESS_2011, :point => :centroid
  
  def name; self['SCHOOL_NAME_2011']; end
  

  def self.square_array(arr)
    result = []
    arr.each_with_index do |a,i|
      arr[i+1..-1].each do |b|
        result << "#{a}-#{b}"
      end
    end
    return result
  end


  # K-5, 6-12, 7-12, 5-12, 6-8, 9-11, K-PartÐ8, PK-1, PK-5, PK-8, K-12, K-Part-12... etc
  GRADES = [ 'PK', 'PK-Part', 'K', 'K-Part' ] + (1..12).collect { |g| g.to_s }
  GRADE_RANGES = {
    :elementary => GRADES[0..8],
    :middle     => GRADES[9..11],
    :high       => GRADES[12..15]
  }
  GRADE_COMBOS = {
    :elementary => square_array(GRADE_RANGES[:elementary]),
    :middle     => square_array(GRADE_RANGES[:middle]),
    :high       => square_array(GRADE_RANGES[:high])
  }
  
  scope :elementary, where(:AUTHORIZED_GRADES_2011 => GRADE_COMBOS[:elementary])
  scope :middle,     where(:AUTHORIZED_GRADES_2011 => GRADE_COMBOS[:middle])
  scope :high,       where(:AUTHORIZED_GRADES_2011 => GRADE_COMBOS[:high])
  
  def elementary?;  GRADE_COMBOS[:elementary].include? self.AUTHORIZED_GRADES_2011; end
  def middle?;      GRADE_COMBOS[:middle].include? self.AUTHORIZED_GRADES_2011; end
  def high?;        GRADE_COMBOS[:high].include? self.AUTHORIZED_GRADES_2011; end
  
  def my_properties
    { :level => self.id % 3 }
  end
  

      
end