module EarlyChildhood
  def self.image(category, rating, year = nil)
    return '/assets/images/el_icons/Overview.png' if category == :overview
    return '/assets/images/el_icons/EL_Award_NoRating.png'    if ![:community, :state, :staff].include?(category) and rating.andand.downcase.andand.include?('not rated')
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
      "/assets/images/el_icons/EL_#{cat}_#{metal}_#{year}.png"
    else
      "/assets/images/el_icons/EL_#{cat}_#{metal}.png"
    end
  end

  def specialty
    field_ec_specialty
  end

  def schedule
    field_ec_schedule
  end

  def age_from
    field_age_from.to_i
  end

  def age_to
    field_age_to.to_i
  end

  def capacity
    field_capacity
  end

  def eligibility
    field_ec_eligibility
  end

  def subsidy
    field_ec_subsidy
  end

  def special
    field_ec_special
  end

  def setting
    field_ec_setting
  end

  def environment
    field_ec_environment
  end

  def meals
    field_ec_meals
  end

  def pay_schedule
    field_ec_payschedule
  end

  def fee
    field_ec_fee.to_f
  end

  def transportation
    field_ec_transportation
  end

  def contact
    field_ec_contact
  end

  def contract
    field_ec_contract
  end

  def months_of_operation
    field_months_of_operation
  end

  def email
    field_ec_email
  end

  def phone
    field_address.andand.phone_number
  end

  def published_rating
    PublishedRating
  end

  def message
    field_ec_message
  end

  def points_total
    ptsTotal
  end

  def points_staff
    ptsStaff
  end

  def points_family
    ptsFamily
  end

  def points_admin
    ptsAdmin
  end

  def points_env
    ptsEnv
  end

  def points_curriculum
    ptsCurr
  end

  def additional_info
    field_ec_additional
  end

  def age_groups
    field_ec_agegroups
  end

  def enrichment
    field_ec_enrichment
  end

  def evaluation
    field_ec_evaluation
  end

  def extended
    field_ec_extended
  end

  def facilities
    field_ec_facilities
  end

  def feedback_freq
    field_ec_feedbackfreq
  end

  def feedback_type
    field_ec_feedbacktype
  end

  def language
    field_ec_language
  end

  def medical
    field_ec_medical
  end

  def mental
    field_ec_mental
  end

  def partner_one
    field_ec_partner1
  end

  def partner_one_detail
    field_ec_partner1_detail
  end

  def partner_two
    field_ec_partner2
  end

  def partner_two_detail
    field_ec_partner2_detail
  end

  def partner_three
    field_ec_partner3
  end

  def partner_three_detail
    field_ec_partner3_detail
  end

  def physical_activity
    field_ec_physactivity
  end

  def support
    field_ec_supports
  end

  def actual_enrollment
    field_ec_actual_enrollment
  end

  def licensed_enrollment
    field_ec_licensed_enrollment
  end

  def license_type
    field_ec_license_type
  end

  def special_enrollment
    field_ec_special_enrollment
  end

  def subsidy_enrollment
    field_ec_subsidy_enrollment
  end
end
