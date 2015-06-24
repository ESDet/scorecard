module EarlyChildhood
  def self.image(category, rating, year = nil)
    return '/assets/el_icons/Overview.png' if category == :overview
    return '/assets/el_icons/EL_Award_NoRating.png' if ![:community, :state, :staff].include?(category) and rating.andand.downcase.andand.include?('not rated')
    #return 'el_icons/EL_Award_Participant.png' if ![:community, :state, :staff].include?(category) and rating.andand.match(/Below|Not/)
    cat = {
      :overall    => 'Award',
      :mini       => 'Mobile',
      :community  => 'Sub_Comm',
      :state      => 'Sub_State',
      :staff      => 'Sub_Staff',
    }[category]

    valid_metals = {
      'Below Bronze'  => 'BelowBronze',
      'Bronze'        => 'Bronze',
      'Below Bronze - Rating in progress' => 'BelowBronze',
      'Bronze - Rating in progres' => 'Bronze',
      'Bronze - Rating in progress' => 'Bronze',
      'Silver'        => 'Silver',
      'Silver - Rating in progress' => 'Silver',
      'Gold'          => 'Gold',
      'Incomplete'    => 'NoRating'
    }
    metal = valid_metals[rating].andand.gsub(' ', '') || 'None'
    #metal = ((category == :overall and !rating.nil?) ? 'Participant' : 'None')
    if year && category != :mini
      "/assets/el_icons/EL_#{cat}_#{metal}_#{year}.png"
    else
      "/assets/el_icons/EL_#{cat}_#{metal}.png"
    end
  end

  def specialty
    ec_profiles.andand.field_ec_specialty
  end

  def schedule
    ec_profiles.andand.field_ec_schedule
  end

  def age_from
    ec_profiles.andand.field_age_from.to_i
  end

  def age_to
    ec_profiles.andand.field_age_to.to_i
  end

  def capacity
    ec_profiles.andand.field_capacity
  end

  def eligibility
    ec_profiles.andand.field_ec_eligibility
  end

  def subsidy
    ec_profiles.andand.field_ec_subsidy
  end

  def special
    ec_profiles.andand.field_ec_special
  end

  def setting
    ec_profiles.andand.field_ec_setting
  end

  def environment
    ec_profiles.andand.field_ec_environment
  end

  def meals
    ec_profiles.andand.field_ec_meals
  end

  def pay_schedule
    ec_profiles.andand.field_ec_payschedule
  end

  def fee
    ec_profiles.andand.field_ec_fee.to_f
  end

  def transportation
    ec_profiles.andand.field_ec_transportation ? "Yes" : "No"
  end

  def contact
    ec_profiles.andand.field_ec_contact
  end

  def contract
    ec_profiles.andand.field_ec_contract
  end

  def months_of_operation
    ec_profiles.andand.field_months_of_operation
  end

  def email
    ec_profiles.andand.field_ec_email
  end

  def phone
    ec_profiles.andand.field_address.andand.phone_number
  end

  def published_rating
    ec_profiles.andand.PublishedRating
  end

  def message
    ec_profiles.andand.field_ec_message
  end

  def points_total
    ec_profiles.andand.ptsTotal
  end

  def points_staff
    ec_profiles.andand.ptsStaff
  end

  def points_family
    ec_profiles.andand.ptsFamily
  end

  def points_admin
    ec_profiles.andand.ptsAdmin
  end

  def points_env
    ec_profiles.andand.ptsEnv
  end

  def points_curriculum
    ec_profiles.andand.ptsCurr
  end

  def additional_info
    ec_profiles.andand.field_ec_additional
  end

  def enrichment
    ec_profiles.andand.field_ec_enrichment
  end

  def evaluation
    ec_profiles.andand.field_ec_evaluation
  end

  def extended
    ec_profiles.andand.field_ec_extended
  end

  def facilities
    ec_profiles.andand.field_ec_facilities
  end

  def feedback_freq
    ec_profiles.andand.field_ec_feedbackfreq
  end

  def feedback_type
    ec_profiles.andand.field_ec_feedbacktype
  end

  def language
    ec_profiles.andand.field_ec_language
  end

  def medical
    ec_profiles.andand.field_ec_medical
  end

  def mental
    ec_profiles.andand.field_ec_mental
  end

  def partner_one
    ec_profiles.andand.field_ec_partner1
  end

  def partner_one_detail
    ec_profiles.andand.field_ec_partner1_detail
  end

  def partner_two
    ec_profiles.andand.field_ec_partner2
  end

  def partner_two_detail
    ec_profiles.andand.field_ec_partner2_detail
  end

  def partner_three
    ec_profiles.andand.field_ec_partner3
  end

  def partner_three_detail
    ec_profiles.andand.field_ec_partner3_detail
  end

  def physical_activity
    ec_profiles.andand.field_ec_physactivity
  end

  def support
    ec_profiles.andand.field_ec_supports
  end

  def actual_enrollment
    ec_profiles.andand.field_ec_actual_enrollment
  end

  def licensed_enrollment
    ec_profiles.andand.field_ec_licensed_enrollment
  end

  def license_type
    ec_profiles.andand.field_ec_license_type
  end

  def special_enrollment
    ec_profiles.andand.field_ec_special_enrollment
  end

  def subsidy_enrollment
    ec_profiles.andand.field_ec_subsidy_enrollment
  end
end
