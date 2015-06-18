module K8School
  def self.extend_object(o)
    super
    ['math', 'ela', 'science', 'socstud'].each do |s|
      o["#{s}_prepared".to_sym] = int_value(o, :esd_k8_2015s, "frac_prof#{s}")

      o["#{s}_growth".to_sym] = float_value(o, :esd_k8_2015s, "mean_pctl_#{s}")
    end
    o[:reading_growth] = float_value(o, :esd_k8_2015s, "mean_pctl_reading")
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
