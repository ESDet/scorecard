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

  def ec_medal_text(medal)
    capitalized_medal = medal.gsub(/.*/, &:upcase)
    color_class = medal.downcase.gsub(/\s/, "-")
    size_class = capitalized_medal.split(" ").size > 1 ? 'medium' : 'big'
    content_tag(:div, capitalized_medal, class: "#{size_class} #{color_class}").html_safe
  end

  def ec_rank_html(field, rating_type, max_points, value)
    case rating_type
    when :community
      self.send "ec_rank_#{field.to_s}", [0.0...3.0, 3.0...3.45, 3.45...3.85, 3.85..4.0], value
    when :state
      if max_points == 16
        self.send "ec_rank_#{field.to_s}", [0...4, 4...8, 8...12, 12..16], value
      elsif max_points == 12
        self.send "ec_rank_#{field.to_s}", [0...3, 3...6, 6...9, 9..12], value
      elsif max_points == 8
        self.send "ec_rank_#{field.to_s}", [0...2, 2...4, 4...6, 6..8], value
      elsif max_points == 6
        self.send "ec_rank_#{field.to_s}", [0.0...1.5, 1.5...3.0, 3.0...4.5, 4.5..6.0], value

      end
    when :staff
      self.send "ec_rank_#{field.to_s}", [0.0...3.75, 3.75...4.25, 4.25...4.75, 4.75..5.0], value

    end
  end

  def ec_rank_text(ranges, value)
    if value.in?(ranges[0])
      "<span class='weak'>WEAK</span>"
    elsif value.in?(ranges[1])
      "<span class='average'>AVERAGE</span>"
    elsif value.in?(ranges[2])
      "<span class='strong'>STRONG</span>"
    elsif value.in?(ranges[3])
      "<span class='very-strong'>VERY STRONG</span>"
    else
      "<span>UNRANKED</span>"
    end.html_safe
  end

  def ec_rank_class(ranges, value)
    if value.in?(ranges[0])
      'weak'
    elsif value.in?(ranges[1])
      'average'
    elsif value.in?(ranges[2])
      'strong'
    elsif value.in?(ranges[3])
      'very-strong'
    end
  end

  def rank_text(value)
    if value.present?
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
    else
      'No data available'
    end
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
    if value.present?
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
    else
      'No data available'
    end
  end

  def strip_phone(ph)
    number = ph.gsub /[\.\s\(\-\)]/, ''
    number = number[1..-1] if number.starts_with?("1")
    number
  end

  def format_phone(ph)
    number = strip_phone(ph)
    "(#{number[0..2]}) #{number[3..5]}-#{number[6..9]}"
  end
end

