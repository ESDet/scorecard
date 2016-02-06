module HighSchool
  def self.extend_object(o)
    super
    ['english', 'math', 'reading', 'science'].each do |s|
      o["#{s}_college_ready".to_sym] = if s == 'science'
        int_value(o, :esd_hs_2015s, "ct#{s}cr")
      else
        int_value(o, :esd_hs_2015s, "act#{s}cr")
      end

      ['eng', 'math', 'read', 'sci'].each do |t|
        if s =~ /#{t}/
          o["#{s}_college_ready_points".to_sym] = float_value(o, :esd_hs_2015s, "#{t}_cr_pts")
        end
      end

      o["#{s}_growth".to_sym] = float_value(o, :esd_hs_2015s, "adj_act#{s}")
    end
  end

  def graduate_in_four_years
    HighSchool.int_value(self, :esd_hs_2015s, :cepi_pct_grad4)
  end

  def graduate_in_five_years
    HighSchool.int_value(self, :esd_hs_2015s, :cepi_pct_grad5)
  end

  def enroll_in_college
    HighSchool.int_value(self, :esd_hs_2015s, :col_enr_pct)
  end

  def stay_in_college
    HighSchool.int_value(self, :esd_hs_2015s, :col_persist_pct)
  end

  def current_stats
    self.andand.esd_hs_2015s
  end

  def college_readiness_ranking
    current_stats.andand.cr_cat_pts.andand.to_i
  end

  def growth_ranking
    current_stats.andand.adj_act_cat_pts.andand.to_i
  end

  def graduation_ranking
    current_stats.andand.gradrate_cat_pts.andand.to_i
  end

  def post_secondary_ranking
    current_stats.andand.col_cat_pts.andand.to_i
  end

  def climate_ranking
    current_stats.andand.net5e_cat_pts.andand.to_i
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
