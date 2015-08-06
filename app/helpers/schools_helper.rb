module SchoolsHelper
  def schools_cache_key
    key = "schools/all/"
    key << "#{@grade}/" if @grade.present?
    key << "#{@loc}/" if @loc.present?
    @filters.sort.each { |f| key << "#{f}/" }
    key << @schools.max_by { |s| s.timestamp.to_i }.timestamp
  end

  def percentile_suffix(percentile)
    p = percentile || "0"
    if p.to_i < 10 || p.to_i > 20
      return "st" if p.end_with?("1")
      return "nd" if p.end_with?("2")
      return "rd" if p.end_with?("3")
      "th"
    else
      "th"
    end
  end
end

