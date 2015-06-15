module HighSchool
  def self.extend_object(o)
    super
    ['english', 'math', 'reading', 'science'].each do |s|
      define_method("#{s}_college_ready") do
        if s == 'science'
          float_value(esd_hs_2015s, "ct#{s}cr")
        else
          float_value(esd_hs_2015s, "act#{s}cr")
        end
      end

      define_method("#{s}_growth") do
        float_value(esd_hs_2015s, "adj_act#{s}")
      end
    end
  end

  def graduate_in_four_years
    float_value(esd_hs_2015s, :cepi_pct_grad4)
  end

  def graduate_in_five_years
    float_value(esd_hs_2015s, :cepi_pct_grad5)
  end

  def enroll_in_college
    float_value(esd_hs_2015s, :col_enr_pct)
  end

  def stay_in_college
    float_value(esd_hs_2015s, :col_persist_pct)
  end

  private

  def float_value(set, value)
    if v = set.andand.send(value)
      v.to_f
    end
  end
end
