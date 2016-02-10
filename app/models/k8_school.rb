module K8School
  def self.extend_object(o)
    super
    ['math', 'ela', 'science', 'socstud'].each do |s|
      o["#{s}_prepared".to_sym] = int_value(o, :esd_k8_2015s, "frac_prof#{s}")

      sub = s == 'socstud' ? 'ss' : s
      sub = s == 'science' ? 'sci' : sub
      o["#{s}_prepared_points".to_sym] = float_value(o, :esd_k8_2015s, "pr2_#{sub}_pts")

      o["#{s}_growth".to_sym] = float_value(o, :esd_k8_2015s, "mean_pctl_#{s}")

    end
    o[:reading_growth] = float_value(o, :esd_k8_2015s, "mean_pctl_reading")
    o[:reading_growth_points] = float_value(o, :esd_k8_2015s, :pts_progress_read)
    o[:math_growth_points] = float_value(o, :esd_k8_2015s, :pts_progress_math)
  end

  def current_stats
    self.andand.esd_k8_2015s
  end

  def excellent_schools_grade
    current_stats.andand.total_ltrgrade
  end

  def proficiency_ranking
    current_stats.andand.prof_cat_points.andand.to_f
  end

  def growth_ranking
    current_stats.andand.growth_cat_points.andand.to_f
  end

  def climate_ranking
    current_stats.andand.net5e_cat_pts.andand.to_f
  end

  private

  def self.int_value(o, set, value)
    if v = o[set].andand.send(value)
      (v.to_f * 100).to_i
    end
  end

  def self.float_value(o, set, value)
    if v = o[set].andand.send(value)
      v.to_f
    end
  end
end
