module School
  def self.extend_object(o)
    super
    five_essentials = {
     'Category5E' => 'overall_rating',
     'E_Ldr' => 'effective_leaders',
     'E_Tch' => 'collaborative_teachers',
     'E_Fam' => 'involved_families',
     'E_Env' => 'supportive_environment',
     'E_Ins' => 'ambitious_instruction'
    }
    five_essentials.each do |k, v|
      o["five_e_#{v}"] = if k == 'Category5E'
        o.andand.fiveessentials_2015s.andand.send(k)
      else
        o.andand.fiveessentials_2015s.andand.send(k).to_i
      end
    end
  end

  def self.image(letter, style=:normal)
    valid = %w[A Aplus B Bplus C Cplus D F Promising]
    mod = letter.andand.gsub('+', 'plus')
    mod = valid.include?(mod) ? mod : 'NA'
    return "/assets/images/el_icons/Sm_#{mod}.png" if style == :small
    "/assets/images/el_icons/K12_Grade_#{mod}.png"
  end

  def high?
    school_type == 'hs'
  end

  def k8?
    school_type == 'k8'
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
    school_profiles.andand.field_school_url
  end

  def facebook_url
    school_profiles.andand.field_facebook_url
  end

  def photo
    if !photos.empty?
      photos.andand.first['filename']
    end
  end

  def photos
    school_profiles.andand.field_photos
  end

  def dress_code
    school_profiles.andand.field_dress_code.andand.label
  end

  def bullying_policy
    if p = school_profiles.andand.field_bullying_policy
      p == 'y' ? "Yes" : "No"
    end
  end

  def parent_involvement
    list_labels school_profiles.andand.field_parent_involvement
  end

  def academic_focus
    list_labels school_profiles.andand.field_academic_focus
  end

  def instructional_model
    list_labels school_profiles.andand.field_instructional_model
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

  def immersion
    school_profiles.andand.field_immersion.label
  end

  def foreign_languages
    list_labels school_profiles.andand.field_foreign_language
  end

  def ap_classes
    school_profiles.andand.field_ap_classes
  end

  def dual_enrollment
    school_profiles.andand.field_dual_enrollment == 'yes'
  end

  def dual_enrollment_institution
    school_profiles.andand.field_dual_enrollment_institution
  end

  def special_ed_level
    school_profiles.andand.field_special_ed_level.andand.label
  end

  def special_ed_programs
    school_profiles.andand.field_special_ed_programs
  end

  def ell_level
    school_profiles.andand.field_ell_level.andand.label
  end

  def ell_languages
    school_profiles.andand.field_ell_languages
  end

  def college_prep
    school_profiles.andand.field_college_prep
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

  def before_after_care
    school_profiles.andand.field_before_after_care
  end

  def staff_resources
    list_labels school_profiles.andand.field_staff_resources
  end

  def boys_sports
    list_labels school_profiles.andand.field_boys_sports
  end

  def girls_sports
    list_labels school_profiles.andand.field_girls_sports
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
    if p = school_profiles.andand.field_application_process
      p == 'yes' ? "Yes" : "No"
    end
  end

  def admissions_url
    school_profiles.andand.field_admissions_url
  end

  def application_fee
    if f = school_profiles.andand.field_application_fee
     f == 'yes' ? "Yes" : "No"
    end
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
    field_address.thoroughfare
  end

  def before_after_care
    school_profiles.andand.field_before_after_care.andand.
      map { |c| c['label'] }
  end

  def transportation_options
    school_profiles.andand.field_transportation_options.
      andand.map { |t| t['label'] }
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
      meap_2014s.andand.WHITE_ENROLLMENT +
        meap_2014s.andand.TWO_OR_MORE_RACES_ENROLLMENT +
        meap_2014s.andand.AMERICAN_INDIAN_ENROLLMENT
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
    percentage_of_total_enrollment(n) if n != 9
  end

  def english_learner
    n = meap_2014s.andand.ENGLISH_LANGUAGE_LEARNERS_ENROLLMENT
    percentage_of_total_enrollment(n) if n != 9
  end

  def special_education
    n = meap_2014s.andand.SPECIAL_EDUCATION_ENROLLMENT
    percentage_of_total_enrollment(n) if n != 9
  end

  def schedule
    list_labels school_profiles.andand.field_schedule
  end

  private

  def list_labels(field)
    field.map { |s| s['label'] } if field
  end

  def percentage_of_total_enrollment(num)
    if num
      sprintf("%d.2", num.to_f / total_enrollment * 100)
    end
  end

end
