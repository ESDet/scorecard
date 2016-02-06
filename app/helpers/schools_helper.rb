module SchoolsHelper
  def schools_cache_key
    key = 'schools/all'
    key << "/#{@grade}" if @grade.present?
    key << "/#{@loc}" if @loc.present?
    @filters.sort.each { |f| key << "/#{f}" }
    key << "/#{@schools.max_by { |s| s.timestamp.to_i }.timestamp}"
  end

  def percentile_suffix(percentile)
    p = percentile || '0'
    if p.to_i < 10 || p.to_i > 20
      return 'st' if p.end_with?('1')
      return 'nd' if p.end_with?('2')
      return 'rd' if p.end_with?('3')
      'th'
    else
      'th'
    end
  end

  def rank_text(value)
    if value < 2
      "<span class='very-weak'>VERY WEAK</span>"
    elsif value >= 2 && value < 4
      "<span class='weak'>WEAK</span>"
    elsif value >= 4 && value < 6
      "<span class='average'>AVERAGE</span>"
    elsif value >= 6 && value < 8
      "<span class='strong'>STRONG</span>"
    elsif value >= 8 && value <= 10
      "<span class='very-strong'>VERY STRONG</span>"
    end.html_safe
  end

  def rank_text_color(value)
    if value < 2
      'very-weak'
    elsif value >= 2 && value < 4
      'weak'
    elsif value >= 4 && value < 6
      'average'
    elsif value >= 6 && value < 8
      'strong'
    elsif value >= 8 && value <= 10
      'very-strong'
    end
  end

  def climate_text(value, school_level)
    case school_level
    when :hs
      if value == 0
        'Did not participate'
      elsif value == 2
        'Not yet organized'
      elsif value == 4
        'Partially Organized'
      elsif value == 6
        'Moderately Organized'
      elsif value == 8
        'Organized'
      elsif value == 10
        'Well Organized'
      end
    when :k8
      if value == 0
        'Did not participate'
      elsif value == 1
        'Not yet organized'
      elsif value == 2
        'Partially Organized'
      elsif value == 3
        'Moderately Organized'
      elsif value == 4
        'Organized'
      elsif value == 5
        'Well Organized'
      end
    end
  end
end

