module K8School
  def self.extend_object(o)
    super
    ['math', 'ela', 'science', 'socstud'].each do |s|
      define_method("#{s}_prepared") do
        float_value(esd_k8_2015s, "frac_prof#{s}")
      end

      define_method("#{s}_growth") do
        float_value(esd_k8_2015s, "mean_pctl_#{s}")
      end
    end
  end

  private

  def float_value(set, value)
    if v = set.andand.send(value)
      v.to_f
    end
  end
end
