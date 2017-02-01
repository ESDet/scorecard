class SchoolData < OpenStruct
  def initialize(hash=nil)
    @table = {}
    @hash_table = {}

    if hash
      hash.each do |k,v|
        if k == :included
          v.each do |i|
            type = i['type']
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
    profile = ec? ? ec_profiles : school_profiles
    if profile.andand.title
      profile.andand.title
    else
      name
    end
  end

  def apply?
    field_ed_participant
  end

  def school_type
    if field_school_type
      field_school_type.andand.name.andand.downcase
    else
      type
    end
  end

  def ec?
    type == 'ecs'
  end

  def hs?
    school_type == 'hs'
  end

  def k8?
    school_type == 'k8'
  end

  def excellent_schools_grade
    if field_school_scorecard_status.name == 'New'
      'New'
    else
      if k8?
        grade = esd_k8_2016s.andand.total_ltrgrade
        grade.present? ? grade : 'N/A'
      elsif hs?
        grade = esd_hs_2016s.andand.total_ltrgrade
        grade.present? ? grade : 'N/A'
      end
    end
  end

  def early_childhood_rating
    if ec?
      ec_state_ratings.andand.overall_rating
    end
  end

  def early_childhood_image(category, medal, mobile: false, compare: false)
    school_medal = medal || early_childhood_rating
    return '/assets/el_icons/Overview.png' if category == :overview
    return '/assets/el_icons/EL_NoRating.png' if ![:community, :state, :staff].include?(category) and school_medal.andand.downcase.andand.include?('not rated')

    valid_metals = {
      'Below Bronze'  => 'CommunityReviewed',
      'Bronze'        => 'Bronze',
      'Below Bronze - Rating in progress' => 'CommunityReviewed',
      'Bronze - Rating in progres' => 'Bronze',
      'Bronze - Rating in progress' => 'Bronze',
      'Silver'        => 'Silver',
      'Silver - Rating in progress' => 'Silver',
      'Gold'          => 'Gold',
      'Incomplete'    => 'BelowBronze'
    }
    metal = valid_metals[school_medal].andand.gsub(' ', '') || 'BelowBronze'
    metal = 'BelowBronze' if compare && metal == 'CommunityReviewed'
    metal = 'Mobile_' + metal if mobile
    "/assets/el_icons/EL_#{metal}.png"
  end

  def gmaps_url
    opts = { :q => "#{street}, #{city} #{state}" }
    "http://maps.google.com?#{opts.to_query}"
  end

  def normalize_url(u)
    return if u.nil?
    x = u.gsub(/^(http|https):\/\//, '')
    return if x.blank?
    "http://#{x}"
  end

  def cache_key
    "schools/#{tid}-#{timestamp}"
  end

  def can_cache?
    tid && timestamp
  end

  def center
    if field_geo && field_geo.lat && field_geo.lon
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
      html: "<a href='#{gmaps_url}' target='_blank'>" +
        "#{display_name}</a><br/>" +
        "#{street}<br/>#{grades if grades}"
    }
  end

  def street
    field_address.andand.thoroughfare
  end

  def city
    field_address.andand.locality
  end

  def state
    field_address.andand.administrative_area
  end

  def id
    if ec?
      "#{tid}-ecs-#{transliterate(name)}"
    else
      "#{tid}-#{school_type}-#{transliterate(name)}"
    end
  end

  def short_id
    ec? ? "#{tid}-ecs" : "#{tid}-#{school_type}"
  end

  def grades_served
    unless ec?
      if school_profiles
        school_profiles.field_grades_served.andand.
          map { |g| g['label'] }
      end
    end
  end

  def age_groups
    if ec?
      ec_profiles.andand.field_ec_agegroups.andand.
        map { |a| a['name'] }
    end
  end

  def school_url
    if ec?
      normalize_url(ec_profiles.andand.field_website.andand.url)
    else
      normalize_url(school_profiles.andand.field_school_url)
    end
  end

  def phone
    if ec?
      field_address.andand.phone_number
    else
      school_profiles.andand.field_general_contact_phone
    end
  end

  def special_ids
    ec_profiles.andand.field_ec_special.andand.
      map { |s| s['tid'] }
  end

  def specialty_ids
    ec_profiles.andand.field_ec_specialty.andand.
      map { |s| s['tid'] }
  end

  def special_ed_ids
    if k8? || hs?
      school_profiles.andand.field_special_ed_programs.andand.
        map { |s| s['machine_name'] }.join(",")
    end
  end

  # Calculates the school weight for sorting in the search list
  #
  # @return [Float] the school's sort weight
  def sort_weight
    if !ec? && (excellent_schools_grade == 'N/A' || excellent_schools_grade == 'New') && field_2016_recommended
      # Put Recommended schools that don't have a grade, between C+ and C schools
      49.5
    else
      school_type_weight
    end
  end

  private

  # Calculates the school weight based on school type
  #
  # @return [Float] the school's sort weight
  def school_type_weight
    case school_type
      when 'k8'
        esd_k8_2016s ? esd_k8_2016s.total_pts.to_f * 100 : 0
      when 'hs'
        esd_hs_2016s ? esd_hs_2016s.total_pts.to_f * 100 : 0
      when 'ecs'
        if early_childhood_rating == 'Below Bronze'
          # Give Pre-K schools without a medal a score penalty
          ec_state_ratings.total_points.to_f / 15 * 100 / 2
        else
          ec_state_ratings.total_points.to_f / 15 * 100
        end
      else
        0
    end
  end

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
