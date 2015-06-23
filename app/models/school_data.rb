class SchoolData < OpenStruct
  def initialize(hash=nil)
    @table = {}
    @hash_table = {}

    if hash
      hash.each do |k,v|
        if k == :included
          v.each do |i|
            type = i['type']
            i.delete('type')
            @table[type.to_sym] = (i.is_a?(Hash) ? self.class.new(i) : i)
            @hash_table[type.to_sym] = i
            new_ostruct_member(type)
          end
        else
          @table[k.to_sym] = (v.is_a?(Hash) ? self.class.new(v) : v)
          @hash_table[k.to_sym] = v
          new_ostruct_member(k)
        end
      end
    end
  end

  def display_name
    if school_profiles && school_profiles.title
      school_profiles.title
    else
      name
    end
  end

  def school_type
    if field_school_type
      field_school_type.andand.name.downcase
    else
      type
    end
  end

  def earlychild?
    type == 'ecs'
  end

  def cache_key
    "schools/#{tid}-#{timestamp}"
  end

  def can_cache?
    tid && timestamp
  end

  def center
    if field_geo
      [field_geo.lat.to_f, field_geo.lon.to_f]
    end
  end

  def marker
    if grades_served
      grades = "Grades #{grades_served.join(', ')}"
    end
    {
      id: tid,
      center: center,
      html: "<a href='/schools/#{link}'>#{display_name}</a><br/>" +
       "#{street}<br/>#{grades if grades}"
    }
  end

  def street
    if field_address
      field_address.thoroughfare
    end
  end

  def link
    if earlychild?
      "#{tid}-ecs-#{transliterate(name)}"
    else
      "#{tid}-#{school_type}-#{transliterate(name)}"
    end
  end

  def grades_served
    unless earlychild?
      if school_profiles
        school_profiles.field_grades_served.andand.
          map { |g| g['label'] }
      end
    end
  end

  def age_groups
    if earlychild?
      ec_profiles.andand.field_ec_agegroups.andand.
        map { |a| a['name'] }
    end
  end


  private

  def transliterate(str)
    return nil if str.nil?
    s = str.dup
    s.downcase!
    s.gsub!(/'/, '')
    s.gsub!(/[^A-Za-z0-9]+/, ' ')
    s.strip!
    s.gsub!(/\ +/, '-')
    return s
  end
end
