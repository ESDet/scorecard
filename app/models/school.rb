module School
  def self.extend_object(o)
    super
    five_essentials = {
      'Category5E' => 'overall_rating',
      'E_Ldr' => 'effective_leaders',
      'E_Tch' => 'collaborative_teachers',
      'E_Fam' => 'involved_families',
      'E_Env' => 'supportive_environment',
      'E_Ins' => 'ambitious_instruction',
      'Report_School_Id' => 'report_id'
    }
    five_essentials.each do |k, v|
      o["five_e_#{v}".to_sym] = if k == 'Category5E'
        o.fiveessentials_2015s.andand.send(k)
      else
        o.fiveessentials_2015s.andand.send(k).to_i
      end
    end
  end

  def recommended?
    field_2016_recommended
  end

  def status
    field_school_scorecard_status.name
  end

  def district_code
    meap_2014s.andand.DistrictCode
  end

  def building_code
    meap_2014s.andand.BuildingCode
  end

  def governance
    field_governance.andand.name
  end

  def authorizer
    field_authorizer.andand.name
  end

  def operator
    field_operator.andand.name
  end

  def overview_text
    school_profiles.andand.field_message.andand.value
  end

  def email
    school_profiles.andand.field_email
  end

  def phone
    school_profiles.andand.field_general_contact_phone
  end

  def school_url
    normalize_url(school_profiles.andand.field_school_url)
  end

  def facebook_url
    normalize_url(school_profiles.andand.field_facebook_url)
  end

  def photo
    school_profiles.andand.field_photos_url.andand.first
  end

  def photos
    school_profiles.andand.field_photos
  end

  def dress_code
    school_profiles.andand.field_dress_code.label
  end

  def dress_code?
    school_profiles.andand.field_dress_code.
      andand.machine_name.present?
  end

  def bullying_policy
    school_profiles.andand.field_bullying_policy.
      andand.label
  end

  def attendance
    k12_supplemental_2015s.andand.attendance_all
  end

  def parent_involvement
    list_labels school_profiles.andand.field_parent_involvement
  end

  def has_academic_programs?
    academic_focus.present? ||
    has_ell? ||
    instructional_model.present? ||
    special_ed_level.present? ||
    special_ed_programs.present?
  end

  def academic_focus
    list_labels school_profiles.andand.field_academic_focus
  end

  def instructional_model
    list_labels school_profiles.andand.field_instructional_model
  end

  def has_classes?
    has_arts? || has_foreign_language?
  end

  def has_arts?
    arts_media.present? ||
      arts_music.present? ||
      arts_performing_written.present? ||
      arts_visual.present?
  end

  def arts_visual
    list_labels school_profiles.andand.field_arts_visual
  end

  def arts_media
    list_labels school_profiles.andand.field_arts_media
  end

  def arts_music
    list_labels school_profiles.andand.field_arts_music
  end

  def arts_performing_written
    list_labels school_profiles.andand.field_arts_performing_written
  end

  def has_foreign_language?
    immersion.present? || foreign_languages.present?
  end

  def immersion
    school_profiles.andand.field_immersion.andand.label
  end

  def foreign_languages
    list_labels school_profiles.andand.field_foreign_language
  end

  def ap_classes
    list_labels school_profiles.andand.field_ap_classes
  end

  def dual_enrollment
    school_profiles.andand.field_dual_enrollment
  end

  def dual_enrollment_institution
    school_profiles.andand.field_dual_enrollment_institution
  end

  def special_ed_level
    school_profiles.andand.field_special_ed_level.andand.label
  end

  def special_ed_programs
    list_labels school_profiles.andand.field_special_ed_programs
  end

  def wheelchar_accessible
    school_profiles.andand.field_wheelchair_accessible
  end

  def wheelchair_accessible?
    school_profiles.andand.field_wheelchair_accessible
  end

  def has_ell?
    ell_level.present? || ell_languages.present?
  end

  def ell_level
    school_profiles.andand.field_ell_level.andand.label
  end

  def ell_languages
    list_labels school_profiles.andand.field_ell_languages
  end

  def college_prep
    school_profiles.andand.field_college_prep
  end

  def has_support?
    extra_learning_resources.present? ||
    staff_resources.present?
  end

  def extra_learning_resources
    list_labels school_profiles.andand.field_extra_learning_resources
  end

  def facilities
    list_labels school_profiles.andand.field_facilities
  end

  def skills_training
    school_profiles.andand.field_skills_training
  end

  def staff_resources
    list_labels school_profiles.andand.field_staff_resources
  end

  def has_sports?
    boys_sports.present? || girls_sports.present?
  end

  def boys_sports
    list_labels school_profiles.andand.field_boys_sports
  end

  def girls_sports
    list_labels school_profiles.andand.field_girls_sports
  end

  def has_clubs?
    student_clubs.present? || has_other_student_clubs?
  end

  def has_other_student_clubs?
    student_clubs_dance.present? ||
    student_clubs_language.present? ||
    student_clubs_other.present?
  end

  def student_clubs
    list_labels school_profiles.andand.field_student_clubs
  end

  def student_clubs_dance
    school_profiles.andand.field_student_clubs_dance
  end

  def student_clubs_language
    school_profiles.andand.field_student_clubs_language
  end

  def student_clubs_other
    list_labels school_profiles.andand.field_student_clubs_other
  end

  def application_process
    school_profiles.andand.field_application_process
  end

  def application_process?
    school_profiles.andand.field_application_process &&
      school_profiles.andand.field_application_process.
      andand.machine_name.downcase == 'yes'
  end

  def admissions_url
    school_profiles.andand.field_admissions_url
  end

  def application_fee
    school_profiles.andand.field_application_fee
  end

  def application_fee_amount
    school_profiles.andand.field_application_fee_amount
  end

  def applications_received
    school_profiles.andand.field_applications_received
  end

  def michigan_percentile
    k12_supplemental_2015s.andand.michigan_ttb
  end

  def street
    field_address.andand.thoroughfare
  end

  def hours
    school_profiles.andand.hours
  end

  def before_after_care_keys
    school_profiles.andand.field_before_after_care.
      andand.map { |f| f['machine_name'] }
  end

  def before_after_care
    list_labels school_profiles.andand.
      field_before_after_care.andand.reverse || []
  end

  def council_district
    school_profiles.andand.field_council_district
  end

  def transportation_options
    list_labels school_profiles.andand.
      field_transportation_options
  end

  def average_commute
    k12_supplemental_2015s.andand.avg_commute
  end

  def total_enrollment
    meap_2014s.andand.TOTAL_ENROLLMENT.andand.to_i
  end

  def african_american_enrollment
    percentage_of_total_enrollment(
      meap_2014s.andand.AFRICAN_AMERICAN_ENROLLMENT
    )
  end

  def asian_enrollment
    percentage_of_total_enrollment(
      meap_2014s.andand.ASIAN_ENROLLMENT
    )
  end

  def hispanic_enrollment
    percentage_of_total_enrollment(
      meap_2014s.andand.HISPANIC_ENROLLMENT
    )
  end

  def white_enrollment
    percentage_of_total_enrollment(
      meap_2014s.andand.WHITE_ENROLLMENT
    )
  end

  def other_enrollment
    percentage_of_total_enrollment(
      meap_2014s.andand.HAWAIIAN_ENROLLMENT.to_i +
        meap_2014s.andand.TWO_OR_MORE_RACES_ENROLLMENT.to_i +
        meap_2014s.andand.AMERICAN_INDIAN_ENROLLMENT.to_i
    )
  end

  def male_enrollment
    percentage_of_total_enrollment(
      meap_2014s.andand.MALE_ENROLLMENT
    )
  end

  def female_enrollment
    percentage_of_total_enrollment(
      meap_2014s.andand.FEMALE_ENROLLMENT
    )
  end

  def free_reduced_lunch
    n = meap_2014s.andand.ECONOMIC_DISADVANTAGED_ENROLLMENT
    percentage_of_total_enrollment(n) if n && n != 9
  end

  def english_learner
    n = meap_2014s.andand.ENGLISH_LANGUAGE_LEARNERS_ENROLLMENT
    percentage_of_total_enrollment(n) if n && n != 9
  end

  def special_education
    n = meap_2014s.andand.SPECIAL_EDUCATION_ENROLLMENT
    percentage_of_total_enrollment(n) if n && n != 9
  end

  def schedule
    list_labels school_profiles.andand.field_schedule
  end

  private

  def list_labels(field)
    field.map { |s| s['label'] } if field
  end

  def percentage_of_total_enrollment(num)
    if num && total_enrollment > 0
      sprintf("%.1f", num.to_f / total_enrollment * 100)
    end
  end

end
