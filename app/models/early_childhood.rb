module EarlyChildhood
  def specialty
    ec_profiles.andand.field_ec_specialty
  end

  def schedule
    list_labels ec_profiles.andand.field_ec_schedule
  end

  def age_from
    ec_profiles.andand.field_age_from
  end

  def age_to
    ec_profiles.andand.field_age_to
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
    ec_profiles.andand.field_ec_special.andand.
      map { |s| s['name'] }
  end

  def setting
    ec_profiles.andand.field_ec_setting.andand.label
  end

  def environment
    list_names ec_profiles.andand.field_ec_environment
  end

  def meals
    list_names ec_profiles.andand.field_ec_meals
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
    list_names ec_profiles.andand.field_ec_enrichment
  end

  def evaluation
    list_names ec_profiles.andand.field_ec_evaluation
  end

  def extended
    list_names ec_profiles.andand.field_ec_extended
  end

  def facilities
    list_names ec_profiles.andand.field_ec_facilities
  end

  def feedback_freq
    list_names ec_profiles.andand.field_ec_feedbackfreq
  end

  def feedback_type
    list_names ec_profiles.andand.field_ec_feedbacktype
  end

  def language
    list_names ec_profiles.andand.field_ec_language
  end

  def medical
    list_names ec_profiles.andand.field_ec_medical
  end

  def mental
    list_names ec_profiles.andand.field_ec_mental
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
    list_names ec_profiles.andand.field_ec_physactivity
  end

  def support
    list_names ec_profiles.andand.field_ec_supports
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

  def staff_program_environment_average
    esd_el_2015s.andand.PhysicalEnviron_Staff_Average
  end

  def staff_family_community_average
    esd_el_2015s.andand.FamilyCommunity_Staff_Average
  end

  def staff_cultural_linguistic_average
    esd_el_2015s.andand.CulturalLinguistic_Staff_Average
  end

  def staff_culture_climate_average
    esd_el_2015s.andand.CultureClimate_Staff_Average
  end

  def community_clc_fair_average
    esd_el_2015s.andand.CLC_FairAverage
  end

  def community_professionalism_fair_average
    esd_el_2015s.andand.Professionalism_FairAverage
  end

  def community_safety_fair_average
    esd_el_2015s.andand.Safety_FairAverage
  end

  def community_interactions_fair_average
    esd_el_2015s.andand.Interactions_FairAverage
  end

  def community_family_fair_average
    esd_el_2015s.andand.FamilyCommunity_FairAverage
  end

  private

  def list_labels(field)
    field.map { |s| s['label'] } if field
  end

  def list_names(field)
    field.map { |s| s['name'] } if field
  end
end
