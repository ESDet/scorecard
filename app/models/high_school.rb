module HighSchool
  def self.extend_object(o)
    super
    ['english', 'math', 'reading', 'science'].each do |s|
      o["#{s}_college_ready".to_sym] = if s == 'science'
        int_value(o, :esd_hs_2015s, "ct#{s}cr")
      else
        int_value(o, :esd_hs_2015s, "act#{s}cr")
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

  def excellent_schools_grade
    esd_hs_2015s.andand.total_ltrgrade
  end

  def hours
    esd_hs_2015s.andand.hours
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
