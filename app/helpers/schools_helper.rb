module SchoolsHelper
  def schools_cache_key
    key = "schools/all/"
    key << "#{@grade}/" if !@grade.blank?
    key << "#{@loc}/" if !@loc.blank?
    @filters.each { |f| key << "#{f}/" }
    key << @schools.max_by { |s| s.timestamp.to_i }.timestamp
  end
end

