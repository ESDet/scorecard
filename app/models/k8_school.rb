module K8School
  def self.extend_object(o)
    super
    ['math', 'ela', 'science', 'socstud'].each do |s|
      o["#{s}_meap_prepared".to_sym] = int_value(o, :esd_k8_2016s, "frac_prof#{s}")

      mstep_sub, meap_sub = case s
      when 'science'
        ['sci', 'sci']
      when 'socstud'
        ['soc', 'ss']
      else
        [s, s]
      end

      o["#{s}_mstep_prepared".to_sym] = int_value(o, :esd_k8_2016s, "mstep_#{mstep_sub}prof")
      o["#{s}_mstep_prepared_points".to_sym] = float_value(o, :esd_k8_2016s, "mstep_#{mstep_sub}pts")

      o["#{s}_meap_prepared_points".to_sym] = float_value(o, :esd_k8_2016s, "pr2_#{meap_sub}_pts")

      o["#{s}_growth".to_sym] = float_value(o, :esd_k8_2016s, "mean_pctl_#{s}")

      o["#{s}_scatter_prof".to_sym] = float_value(o, :esd_k8_2016s, "scatter_#{s}prof")
      o["#{s}_scatter_growth".to_sym] = float_value(o, :esd_k8_2016s, "scatter_#{s}growth")
    end

    o[:reading_growth] = float_value(o, :esd_k8_2016s, "mean_pctl_reading")
    o[:reading_growth_points] = float_value(o, :esd_k8_2016s, :pts_progress_read)
    o[:math_growth_points] = float_value(o, :esd_k8_2016s, :pts_progress_math)
  end

  def current_stats
    self.andand.esd_k8_2016s
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
      v.to_f.round
    end
  end
end
