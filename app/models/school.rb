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

  def grades_served
    school_profiles.andand.field_grades_served
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
    if i = school_profiles.andand.field_parent_involvement
      i == 'y' ? "Yes" : "No"
    end
  end

  def academic_focus
    school_profiles.andand.field_academic_focus
  end

  def instructional_model
    school_profiles.andand.field_instructional_model
  end

  def arts_visual
    school_profiles.andand.field_arts_visual
  end

  def arts_media
    school_profiles.andand.field_arts_media
  end

  def arts_music
    school_profiles.andand.field_arts_music
  end

  def arts_performing_written
    school_profiles.andand.field_arts_performing_written
  end

  def immersion
    if i = school_profiles.andand.field_immersion
      i == 'yes' ? "Yes" : "No"
    end
  end

  def foreign_language
    school_profiles.andand.field_foreign_language
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
    school_profiles.andand.field_extra_learning_resources
  end

  def facilities
    school_profiles.andand.field_facilities
  end

  def skills_training
    school_profiles.andand.field_skills_training
  end

  def before_after_care
    school_profiles.andand.field_before_after_care
  end

  def staff_resources
    school_profiles.andand.field_staff_resources
  end

  def boys_sports
    school_profiles.andand.field_boys_sports
  end

  def girls_sports
    school_profiles.andand.field_girls_sports
  end

  def student_clubs
    school_profiles.andand.field_student_clubs
  end

  def student_clubs_dance
    school_profiles.andand.field_student_clubs_dance
  end

  def student_clubs_language
    school_profiles.andand.field_student_clubs_language
  end

  def student_clubs_other
    school_profiles.andand.field_student_clubs_other
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
end
