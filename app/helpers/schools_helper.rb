module SchoolsHelper
  def schools_cache_key
    key = "schools/all/"
    key << "#{@grade}/" if @grade.present?
    key << "#{@loc}/" if @loc.present?
    @filters.sort.each { |f| key << "#{f}/" }
    key << @schools.max_by { |s| s.timestamp.to_i }.timestamp
  end
end

