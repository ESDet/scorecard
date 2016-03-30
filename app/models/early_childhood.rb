module EarlyChildhood
  def self.extend_object(o)
    super
    ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'].each do |d|
      o["#{d}_open".to_sym] = o.ec_profiles.send("field_#{d}_open")
      o["#{d}_close".to_sym] = o.ec_profiles.send("field_#{d}_close")
    end
  end

  def school_url
    normalize_url(ec_profiles.andand.field_website.andand.url)
  end

  def specialty
    list_names ec_profiles.andand.field_ec_specialty
  end

  def schedule
    list_labels ec_profiles.andand.field_ec_schedule
  end

  def age_from
    from = ec_profiles.andand.field_age_from
    if from.to_i > 11
      "#{(from.to_i / 12).to_i} years"
    else
      "#{from.to_i % 12} months"
    end if from
  end

  def age_to
    to = ec_profiles.andand.field_age_to
    if to.to_i > 11
      "#{(to.to_i / 12).to_i} years"
    else
      "#{to.to_i % 12} months"
    end if to
  end

  def capacity
    ec_profiles.andand.field_capacity
  end

  def eligibility
    ec_profiles.andand.field_ec_eligibility ? "Yes" : "No"
  end

  def subsidy
    list_names ec_profiles.andand.field_ec_subsidy
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

  def fees
    {
      'Application fee': application_fee,
      'Weekly cost of infant/toddler care': infant_toddler_care_weekly_cost,
      'Weekly cost of preschool': preschool_weekly_cost
    }.select { |k, v| v > 0 }
  end

  def application_fee
    ec_profiles.andand.field_ec_fee.to_f
  end

  def infant_toddler_care_weekly_cost
    ec_profiles.andand.field_ec_cost_b4.to_f
  end

  def preschool_weekly_cost
    ec_profiles.andand.field_ec_cost_prek.to_f
  end

  def transportation
    ec_profiles.andand.field_ec_transportation ? "Yes" : "No"
  end

  def contact
    ec_profiles.andand.field_ec_contact
  end

  def contract
    ec_profiles.andand.field_ec_contract ? "Yes" : "No"
  end

  def months_of_operation
    field_months_of_operation
  end

  def email
    ec_profiles.andand.field_email
  end

  def phone
    field_address.andand.phone_number
  end

  def state_rating
    case ec_state_ratings.andand.state_points
    when '0'
      'Below Bronze'
    when '2'
      'Bronze'
    when '4'
      'Silver'
    when '6'
      'Gold'
    end
  end

  def published_rating
    ec_state_ratings.andand.PublishedRating
  end

  def message
    ec_profiles.andand.field_ec_message
  end

  def points_total
    ec_state_ratings.andand.ptsTotal
  end

  def points_staff
    ec_state_ratings.andand.ptsStaff
  end

  def points_family
    ec_state_ratings.andand.ptsFamily
  end

  def points_admin
    ec_state_ratings.andand.ptsAdmin
  end

  def points_env
    ec_state_ratings.andand.ptsEnv
  end

  def points_curriculum
    ec_state_ratings.andand.ptsCurr
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

  def teacher_score_mean
    esd_el_2015s.andand.teacher_score_mean_2014
  end

  def site_visit_rating
    esd_el_2015s.andand.Overall_Site_Visit_Rating
  end

  def site_visit_rating_year
    esd_el_2015s.andand.SiteVisitRatingYear
  end

  def sas_score_rating
    esd_el_2015s.andand.sas_score_rating
  end

  def teacher_survey_rating
    if esd_el_2015s.andand.teacher_survey_rating == "Not rated - Missing data"
      "Did not participate"
    else
      esd_el_2015s.andand.teacher_survey_rating
    end
  end

  def staff_survey_rating_year
    esd_el_2015s.andand.StaffSurveyRatingYear
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
    esd_el_2015s.andand.CLC_FairAverage.to_f
  end

  def community_professionalism_fair_average
    esd_el_2015s.andand.Professionalism_FairAverage.to_f
  end

  def community_safety_fair_average
    esd_el_2015s.andand.Safety_FairAverage.to_f
  end

  def community_interactions_fair_average
    esd_el_2015s.andand.Interactions_FairAverage.to_f
  end

  def community_family_fair_average
    esd_el_2015s.andand.FamilyCommunity_FairAverage.to_f
  end

  private

  def list_labels(field)
    field.map { |s| s['label'] } if field
  end

  def list_names(field)
    field.map { |s| s['name'] } if field
  end
end
