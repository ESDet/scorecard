class School < ActiveRecord::Base
  require 'bedrock/acts_as_feature'
  require 'bedrock/acts_as_geocoded'
  acts_as_feature :geometry => 'centroid', :fields => [:id, :SCHOOL_NAME_2011, :SCHOOL_STREET_ADDRESS_2011, :AUTHORIZED_GRADES_2011, :TEMPLATE]
  acts_as_geocoded :address => :SCHOOL_STREET_ADDRESS_2011, :point => :centroid, :sleep => 0.1
  
  def name; self['SCHOOL_NAME_TEMPLATE_2011'].gsub('_', ' '); end
  

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
    :elementary => ['ES', 'K8'],
    :middle     => ['MS', 'K8'],
    :high       => ['HS'],
    :k8         => ['K8'],
  }
  
  scope :elementary, where(:TEMPLATE => GRADES[:elementary])
  scope :middle,     where(:TEMPLATE => GRADES[:middle])
  scope :high,       where(:TEMPLATE => GRADES[:high])
  scope :k8,         where(:TEMPLATE => GRADES[:k8]) 
  
  def elementary?;  GRADES[:elementary].include?  self.TEMPLATE; end
  def middle?;      GRADES[:middle].include?      self.TEMPLATE; end
  def high?;        GRADES[:high].include?        self.TEMPLATE; end
  def k8?;          GRADES[:k8].include?          self.TEMPLATE; end  
      
end