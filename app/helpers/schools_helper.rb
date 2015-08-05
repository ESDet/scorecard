module SchoolsHelper
  def schools_cache_key
    key = "schools/all/"
    key << "#{@grade}/" if @grade.present?
    key << "#{@loc}/" if @loc.present?
    @filters.sort.each { |f| key << "#{f}/" }
    key << @schools.max_by { |s| s.timestamp.to_i }.timestamp
  end

  def percentile_suffix(percentile)
    p = percentile.to_i
    if p < 10 || p > 20
      return "st" if percentile.end_with?("1")
      return "nd" if percentile.end_with?("2")
      return "rd" if percentile.end_with?("3")
      "th"
    else
      "th"
    end
  end
end

