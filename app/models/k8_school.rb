module K8School
  def self.extend_object(o)
    super
    ['math', 'ela', 'science', 'socstud'].each do |s|
      mstep_sub, meap_sub = case s
      when 'science'
        ['sci', 'sci']
      when 'socstud'
        ['soc', 'ss']
      else
        [s, s]
      end

      ["2016", "2017"].each do |year|
        o["#{s}_mstep_prepared_#{year}".to_sym] = int_value(o, "esd_k8_#{year}s", "mstep_#{mstep_sub}prof")
        o["#{s}_mstep_prepared_points_#{year}".to_sym] = float_value(o, "esd_k8_#{year}s", "mstep_#{mstep_sub}pts")

        if year == "2016"
          o["#{s}_meap_prepared_2016".to_sym] = int_value(o, :esd_k8_2016s, "frac_prof#{s}")
          o["#{s}_meap_prepared_points_2016".to_sym] = float_value(o, :esd_k8_2016s, "pr2_#{meap_sub}_pts")
        end

        o["#{s}_growth_#{year}".to_sym] = float_value(o, "esd_k8_#{year}s", "mean_pctl_#{s}")

        o["#{s}_scatter_prof_#{2016}".to_sym] = float_value(o, "esd_k8_#{year}s", "scatter_#{s}prof")
        o["#{s}_scatter_growth_#{2016}".to_sym] = float_value(o, "esd_k8_#{year}s", "scatter_#{s}growth")
      end
    end

    ["2016", "2017"].each do |year|
      o["reading_growth_#{year}".to_sym] = float_value(o, "esd_k8_#{year}s", "mean_pctl_reading")
      o["reading_growth_points_#{year}".to_sym] = float_value(o, "esd_k8_#{year}s", :pts_progress_read)
      o["math_growth_points_#{year}".to_sym] = float_value(o, "esd_k8_#{year}s", :pts_progress_math)
    end
  end

  def current_stats
    self.try(:esd_k8_2017s)
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
    if v = o[set].try(:send, value)
      (v.to_f * 100).to_i
    end
  end

  def self.float_value(o, set, value)
    if v = o[set].try(:send, value)
      v.to_f.round
    end
  end
end
