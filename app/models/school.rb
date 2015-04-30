class School < ActiveRecord::Base
  require 'bedrock/acts_as_feature'
  require 'bedrock/acts_as_geocoded'
  require 'definitions'
  include Definitions

  acts_as_feature :geometry => 'centroid', :fields => [:id, :name, :address, :address2, :grades_served, :slug, :grade, :points],
    :add_properties => :my_properties
  #acts_as_geocoded :address => :address, :point => :centroid, :sleep => 0.15
  utm_factory = RGeo::Geographic.projected_factory(:projection_proj4 => "+proj=utm +zone=17 +ellps=WGS84 +datum=WGS84 +units=m +no_defs")
  set_rgeo_factory_for_column(:centroid, utm_factory)

  require 'mogrify'
  include Mogrify
  [:basic, :profile, :meap_2012, :meap_2011, :meap_2010, :meap_2009, :esd_k8_2013, :esd_k8_2013_r1, :esd_hs_2013,
    :act_2013, :fiveessentials_2013, :meap_2013, :act_2014,
    :earlychild, :ecs, :esd_el_2014, :esd_el_2015, :esd_k8_2014, :esd_hs_2014, :esd_site_visit_2014, :fiveessentials_2014].each do |k|
    serialize k, OpenStruct
  end
  serialize :others, Array
  before_save :set_slug
  before_save :set_totals


  def self.square_array(arr)
    result = []
    arr.each_with_index do |a,i|
      arr[i+1..-1].each do |b|
        result << "#{a}-#{b}"
      end
    end
    return result
  end


  GRADES = {
    :ec         => 'EC',
    :k8         => 'K8',
    :k12        => 'K12',
    :suburban   => 'Suburban',
    :elementary => ['K8', 'K12'],
    :k8hs       => ['K8', 'K12', 'HS'],
    :middle     => ['K8', 'K12'],
    :high       => 'HS',
  }

  TYPES = {
    :charter          => 'Charter',
    :dps              => 'DPS',
    :dps_charter      => 'DPS Charter',
    :dps_rising       => 'DPS Detroit Rising',
    :dps_traditional  => 'DPS Traditional',
    :eaa              => 'EAA',
    :eaa_charter      => 'EAA Charter',
    :independent      => 'Independent',
    :parochial        => 'Parochial',
    :traditional      => 'Traditional public',
  }

  FIVE_E_LABELS = {
    :"response rate on student survey"    => 'Response rate on student survey',
    :"response rate on teacher survey"    => 'Response rate on teacher survey',
    :"essential: effective leaders"       => 'Effective Leaders',
    :"essential: collaborative teachers"  => 'Collaborative Teachers',
    :"essential: involved families"       => 'Involved Families',
    :"essential: supportive environment"  => 'Supportive Environment',
    :"essential: ambitious instruction"   => 'Ambitious Instruction',
  }

  NA_GRADES = ['N/A', 'Incomplete Status &amp; No Progress Data', 'No Progress Data', 'Incomplete Status Data', 'Undetermined',
    'No Status/Progress Data', 'No Status Data']


  GRADES.slice(:ec, :k8, :k12, :suburban, :k8hs, :high).each do |k,v|
    scope k, where(:school_type => v)
  end
  scope :elementary, where("grades_served REGEXP 'kp|KP|kf|KF|\\b1\\b|\\b2\\b|\\b3\\b|4|5'")
  scope :middle, where("grades_served REGEXP '6|7|8'")
  #scope :high, where("grades_served REGEXP '9|10|11|12'")

  TYPES.each do |k,v|
    scope k,         where(:sch => v)
  end

  scope :not_ec, where("school_type <> 'EC'")

  def elementary?;  grades_served.andand.match(/kp|KP|kf|KF|\b1\b|\b2\b|\b3\b|4|5/); end
  def middle?;      grades_served.andand.match(/6|7|8/); end
  def high?;        school_type == GRADES[:high] or k12?; end
  def k8?;          school_type == GRADES[:k8]; end
  def k12?;         school_type == GRADES[:k12]; end
  def earlychild?;  school_type == 'EC'; end

  def display?;     self.basic.scorecard_display == '1'; end
  def type_s
   case self.school_type
    when 'EC' then 'Pre-School'
    when 'HS' then 'High School'
    when 'K8'
      self.middle? ? 'Middle School' : 'Elementary School'
    else
      nil
    end
  end

  def my_properties
    kinds = []
    kinds << 'earlychild' if earlychild?
    kinds << 'elementary' if elementary?
    kinds << 'middle' if middle?
    kinds << 'high' if high?

    result = {
      :name       => self.name,
      :bcode      => self.bcode,
      :level      => k12 ? 'K12' : (self.high? ? 'HS' : (self.earlychild? ? 'EC' : 'K8')),
      :classes    => kinds.join(' '),
      :cumulative => self.grades[:cumulative][:letter],
      :seal       => earlychild? ?
        School.el_image(:mini, self.esd_el_2015.andand.overall_rating) :
        School.k12_image(self.overall_grade, :small),
      :others     => self.others,
    }
    return result
  end

  def esd
    return self.esd_hs_2014 if self.high?
    return self.esd_k8_2014 if self.k8?
    nil
  end

  # For really simple sorting
  def total_points
    if earlychild?
      mul = {
        'Gold' => 4,
        'Silver' => 3,
        'Bronze' => 2,
        'Below Bronze' => 1,
      }[self.esd_el_2015.andand.overall_rating] || 0
      return mul * 100 + self.ecs.andand.ptsTotal.to_i
    end

    percent = nil
    if high? and defined?(self.esd_hs_2014) and self.esd_hs_2014
      percent = self.esd_hs_2014.total_pct.to_f
    elsif elementary? and defined?(self.esd_k8_2014) and self.esd_k8_2014
      percent = self.esd_k8_2014.total_pct.to_f
    end
    return percent.nil? ? nil : (percent * 100).to_i
  end

  def overall_grade
    if high? and defined?(self.esd_hs_2014) and self.esd_hs_2014
      return self.esd_hs_2014.total_ltrgrade
    elsif elementary? and defined?(self.esd_k8_2014) and self.esd_k8_2014
      return self.esd_k8_2014.total_ltrgrade
    end
    return nil
  end



  def grades
    cat = esd.andand.schoolcategory.andand.titleize

    h = { :cumulative => {}, :status => {}, :progress => {}, :climate => {}, :other => {} }
    return h if esd.nil? and !earlychild?

    if self.high? and self.esd_hs_2014
      # Common to all HS varieties:
      h[:status] = {
        :letter   => esd.status_ltrgrade.blank? ? 'N/A' : esd.status_ltrgrade,
        :total    => esd.status_pts,
        :possible => esd.status_psspts,
        :details  => [] }
      h[:progress] = {
        :letter   => esd.progress_ltrgrade.blank? ? 'N/A' : esd.progress_ltrgrade,
        :total    => esd.progress_pts,
        :possible => esd.progress_psspts }
      h[:climate] = {
        :letter   => esd.culture_ltrgrade.blank? ? 'N/A' : esd.culture_ltrgrade,
        :total    => esd.culture_pts,
        :possible => esd.culture_psspts }
      h[:other] = {
        :total    => esd.studchrs_pts.to_i + esd.fafsa_rate_pts.to_i }

      if ['Mature', 'New', 'Turnaround'].include? cat
        h[:cumulative] = {
          :letter   => self.overall_grade || 'N/A',
          :total    => esd.total_pts,
          :possible => esd.total_psspts,
          :percent  => esd.total_pct }
      end

    elsif self.k8? and esd_k8_2014
      # Common to all the K8 varieties..
      h[:status] = {
        :letter   => esd.status_ltrgrade.blank? ? 'N/A' : esd.status_ltrgrade,
        :total    => esd.pts_status,
        :possible => esd.ptspos_status,
        :details  => [] }
      h[:progress] = {
        :letter   => esd.progress_ltrgrade.blank? ? 'N/A' : esd.progress_ltrgrade,
        :total    => esd.pts_progress,
        :possible => esd.ptspos_progress }
      h[:climate] = {
        :letter   => esd.culture_ltrgrade.blank? ? 'N/A' : esd.culture_ltrgrade,
        :total    => esd.pts_culture,
        :possible => esd.ptspos_culture }
      h[:other] = {
        :total    => esd.studchrs_pts }

      if ['Mature', 'New', 'Turnaround'].include? cat
        h[:cumulative] = {
          :letter   => esd.total_ltrgrade.blank? ? 'N/A' : esd.total_ltrgrade,
          :total    => esd.pts_earned,
          :possible => esd.pts_possible,
          :percent  => esd.total_pct }
      end

    elsif self.ecs
      h[:status][:summary_table] = summary_table(:status)
      return h

    end

    [:status, :progress, :climate].each { |s| h[s][:summary_table] = summary_table(s) }
    h[:status][:details] = details(:status)
    h[:progress][:history] = history(:status)
    h[:climate][:details] = details(:climate)

    return h
  end


  def summary_table(cat)
    h = []
    if cat == :status
      if elementary? and e = self.esd_k8_2014
        h += [
          { :name     => "Percent of Students Proficient in Math (2-Year Average)",
            :key      => :pr2_math,
            :value    => e.pr2_math.blank? ? nil : e.pr2_math.to_f.round(2),
            :points   => e.pr2_math_pts,
            :possible => e.pr2_math_ptsps,
            :display  => :percent },
          { :name     => "Percent of Students Proficient in Reading & Writing (2-Year Average)",
            :key      => :pr2_ela,
            :value    => e.pr2_ela.blank? ? nil : e.pr2_ela.to_f.round(2),
            :points   => e.pr2_ela_pts,
            :possible => e.pr2_ela_ptsps,
            :display  => :percent },
          { :name     => "Percent of Students Proficient in Science & Social Studies (2-Year Average)",
            :key      => :pr2_other,
            :value    => e.pr2_other.blank? ? nil : e.pr2_other.to_f.round(2),
            :points   => e.pr2_other_pts,
            :possible => e.pr2_other_ptsps,
            :display  => :percent },
        ]
      end
      if high? and e = self.esd_hs_2014
        h += [
          { :name     => "ACT Composite Score (2 Year Average)",
            :key      => :act2_comp,
            :value    => e.act2_comp.blank? ? nil : e.act2_comp.to_f.round(1),
            :points   => e.act2_comp_pts,
            :possible => e.act2_comp_psspts },
          { :name     => "Percent College Ready Measured by ACT Scores",
            :key      => :act2_pcr,
            :value    => e.act2_pcr.blank? ? nil : e.act2_pcr.to_f.round(2),
            :points   => e.act2_pcr_pts,
            :possible => e.act2_pcr_psspts,
            :display  => :percent },
        ]
        h += [
          { :name     => "4-Year Graduation Rate, Class 2013",
            :key      => :gradrate,
            :value    => e.gradrate.blank? ? nil : e.gradrate.to_f.round(2),
            :points   => e.gradrate_pts,
            :possible => e.gradrate_psspts,
            :display  => :percent },
        ] unless e.gradrate.blank?
      end

      if earlychild? and ec = self.ecs
        h += [
          #{ :name => 'Total Score',
          #  :key  => :gscpts,
          #  :points => ec.ptsTotal,
          #  :possible => 50,
          #},
          { :name => 'Staff Qualifications and Professional Development',
            :key => :gscptsstaff,
            :points => ec.ptsStaff,
            :possible => 16,
          },
          { :name => 'Family and Community Partnerships',
            :key => :gscptsfamily,
            :points => ec.ptsFamily,
            :possible => 8,
          },
          { :name => 'Administration and Management',
            :key => :gscptsadmin,
            :points => ec.ptsAdmin,
            :possible => 6,
          },
          { :name => 'Environment',
            :key => :gscptsenv,
            :points => ec.ptsEnv,
            :possible => 8,
          },
          { :name => 'Curriculum and Instruction',
            :key => :gscptscurr,
            :points => ec.ptsCurr,
            :possible => 12,
          },
        ]
      end
    end

    if cat == :progress
      if elementary? and e = self.esd_k8_2014
        h += [
          { :name     => "Percent of Students Making Progress on MEAP",
            :key      => :plc_comp,
            :value    =>  e.plc_comp.blank? ? nil : e.plc_comp.to_f.round(2),
            :points   =>  e.plc_comp_pts,
            :possible =>  e.plc_comp_ptsps,
            :display  => :percent },
          { :name     => "Percent of Students Reaching their 1-Year Growth Target (Math & Reading)",
            :key      => :bench_comp,
            :value    =>  e.bench_comp.blank? ? nil : e.bench_comp.to_f.round(2),
            :points   =>  e.bench_comp_pts,
            :possible =>  e.bench_comp_ptsps,
            :display  => :percent },
        ]
      end

      if high? and e = esd_hs_2014
        h += [
          { :name     => "Year-over-Year ACT Composite Score Gain (2 Year Average, 2010-11 to 2011-12, 2011-12 to 2012-13)",
            :key      => :act_grwth,
            :value    => e.act_grwth.blank? ? nil : e.act_grwth.to_f.round(2),
            :points   => e.act_grwth_pts,
            :possible => e.act_grwth_psspts },
        ] unless e.act_grwth.blank?
      end
    end

    if cat == :climate
      if elementary? and e = self.esd_k8_2014
          h += [
            { :name     => "Community-Led Site Visit Score",
              :key      => :site_s,
              :value    => e.site_s.blank? ? nil : e.site_s.to_f.round(2),
              :points   => e.site_s_pts,
              :possible => e.site_s_ptsps },
            { :name     => "Net 5Essentials Score (2013-14)",
              :key      => :net5e_1213,
              :value    => e.net5e,
              :points   => e.net5e_pts,
              :possible => e.net5e_ptsps },
            { :name     => "5Essentials Trend",
              :key      => :five_e_grwth,
              :value    => e.five_e_grwth.blank? ? nil : e.five_e_grwth.to_f.round(1),
              :points   => e.five_e_grwth_pts,
              :possible => e.five_e_grwth_ptsps },
          ]
      elsif high? and e = self.esd_hs_2014
        h += [
          { :name     => "Community-Led Site Visit Score",
            :key      => :site_s,
            :value    => e.site_s.blank? ? nil : e.site_s.to_f.round(2),
            :points   => e.site_s_pts,
            :possible => e.site_s_psspts },
          { :name     => "Net 5Essentials Score (2013-14)",
            :key      => :net5e_1213,
            :value    => e.net5e,
            :points   => e.net5e_pts,
            :possible => e.net5e_psspts },
          { :name     => "5Essentials Trend",
            :key      => :five_e_grwth,
            :value    => e.five_e_grwth.blank? ? nil : e.five_e_grwth.to_f.round(1),
            :points   => e.five_e_grwth_pts,
            :possible => e.five_e_grwth_psspts },
        ]
      end
    end

    h
  end

  # So far only Academic Status & Climate tabs implemented
  def details(tab)

    h = {}
    if tab == :status
      dump = meap_2013.andand.marshal_dump
      return {} if dump.nil?
      if k8?
        [:math, :reading].each do |subject|   # used to have :science
          h[subject] = {}
          #logger.info dump.inspect
          grades = (3..8).select { |g| dump.has_key? "grade_#{g}_#{subject}_tested".to_sym }
          #logger.info grades.inspect
          grades.each do |g|
            #next if g == 3 and subject == :math  # Weird, it's 100% everywhere for now
            prof   = dump["grade_#{g}_#{subject}_proficient".to_sym].to_i
            tested = dump["grade_#{g}_#{subject}_tested".to_sym].to_i
            #logger.info "grade #{g} #{subject} - #{prof} and #{tested}"
            #prof   = (prof == 9)   ? 0 : prof
            #tested = (tested == 9) ? 0 : tested
            next if tested == 0
            percent = (100.0 * prof.to_f / tested.to_f).to_i
            h[subject][g] = percent
          end
        end
      end

      if high?
        a = {}
        act = act_2014.andand.marshal_dump
        return {} if act.nil?

        #logger.ap act
        # Bar charts with % meeting for All Subjects, Reading, Math, Science, and English (exclude Null values) from ACT 2014
        [:allsub, :reading, :math, :english, :science].each do |subject|
          key = "#{subject}percentmeeting".to_sym
          a[subject] = act.andand[key].andand.to_i
        end
        h[:act] = a
      end

    elsif tab == :climate
      dump = fiveessentials_2014.andand.marshal_dump
      return {} if dump.nil?
      FIVE_E_LABELS.each do |key, label|
        val = dump[key].to_i
        h[label] = val unless val.blank? or val == 0
      end

    else
      throw "Tab not implemented yet"
    end
    h
  end


  def history(tab)
    throw "Not implemented yet" unless tab == :status
    dump = {
      2013 => meap_2013.andand.marshal_dump,
      2012 => meap_2012.andand.marshal_dump,
      2011 => meap_2011.andand.marshal_dump,
      2010 => meap_2010.andand.marshal_dump,
    }
    h = {}
    (3..8).each do |grade|
      h[grade] = {}
      [:reading, :math].each do |subject| # Used to have :science
        next if grade == 3 and subject == :math  # Bogus 100%s
        h[grade][subject] = {}
        dump.each do |year, dump|
          next if dump.blank?
          percent = meap_percent(year, grade, subject, dump)
          h[grade][subject][year] = percent # unless percent.nil?
        end
      end
    end
    return h
  end

  def meap_percent(year, grade, subject, dump=nil)
    h = dump.nil? ? self.send("meap_#{year}").andand.marshal_dump : dump
    return h if h.nil?
    pf = "grade_#{grade}_#{subject}_proficient".to_sym
    tf = "grade_#{grade}_#{subject}_tested".to_sym
    prof   = dump[pf].to_i
    tested = dump[tf].to_i
    prof   = 0 if prof == 9
    tested = 0 if tested == 9
    return nil if prof == 0 or tested == 0
    return (100.0 * prof.to_f / tested.to_f).to_i
  end


  # To make link_to use slugs
  def to_param
    slug
  end

  def set_slug
    self.name ||= "School #{self.bcode}"
    self.slug = transliterate(self.name)
  end

  def set_totals
    self.points = self.total_points
    self.grade = self.overall_grade
  end

  def gmaps_url
    opts = {
        :q => "#{self.address}, #{self.address2}",
        #:q => "#{self.centroid.y}, #{self.centroid.x}",
      }
    "http://maps.google.com?#{opts.to_query}"
  end

  def school_url
    normalize_url(self.profile.andand.school_url || self.ecs.andand.website)
  end

  def facebook_url
    normalize_url(self.profile.andand.facebook_url)
  end

  def normalize_url(u)
    return u if u.nil?
    x = u.gsub(/^(http|https):\/\//, '')
    return nil if x.blank?
    "http://#{x}"
  end


  def self.el_image(category, rating)
    return 'el_icons/Overview.png' if category == :overview
    return 'el_icons/EL_Award_NoRating.png'    if ![:community, :state, :staff].include?(category) and rating.andand.downcase.andand.include?('not rated')
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
      'Silver'        => 'Silver',
      'Gold'          => 'Gold',
      'Incomplete'    => 'NoRating',
    }
    metal = valid_metals[rating].andand.gsub(' ', '') || 'None'
    #metal = ((category == :overall and !rating.nil?) ? 'Participant' : 'None')
    "el_icons/EL_#{cat}_#{metal}.png"
  end


  def self.k12_image(letter, style=:normal)
    valid = %w[A Aplus B Bplus C Cplus D F Promising]
    mod = letter.andand.gsub('+', 'plus')
    mod = valid.include?(mod) ? mod : 'NA'
    return "el_icons/Sm_#{mod}.png" if style == :small
    "el_icons/K12_Grade_#{mod}.png"
  end

  def early_child
    ecs || earlychild
  end

  def ec_specialty
    get_api_value(ecs.field_ec_specialty) || earlychild.andand.gscspecialty
  end

  def ec_schedule
    get_api_value(ecs.field_ec_schedule) || earlychild.andand.gscschedule
  end

  def ec_age_from
    ecs.field_age_from['und'].first['value'].to_i
  end

  def ec_age_to
    ecs.field_age_to['und'].first['value'].to_i
  end

  def ec_capacity
    get_api_value(ecs.field_capacity) || earlychild.andand.gsccapacity
  end

  def ec_eligibility
    get_api_value(ecs.field_ec_eligibility) || earlychild.andand.gsceligibility
  end

  def ec_subsidy
    get_api_value(ecs.field_ec_subsidy) || earlychild.andand.gscsubsidy
  end

  def ec_special
    get_api_value(ecs.field_ec_special) || earlychild.andand.gscspecial
  end

  def ec_setting
    get_api_value(ecs.field_ec_setting) || earlychild.andand.gscsetting
  end

  def ec_environment
    get_api_value(ecs.field_ec_environment) || earlychild.andand.environment
  end

  def ec_meals
    get_api_value(ecs.field_ec_meals) || earlychild.andand.meals
  end

  def ec_pay_schedule
    get_api_value(ecs.field_ec_payschedule) || earlychild.andand.gscpayschedule
  end

  def ec_fee
    get_api_value(ecs.field_ec_fee).to_f || earlychild.andand.gscfee
  end

  def ec_transportation
    get_api_value(ecs.field_ec_transportation) || earlychild.andand.transportation
  end

  def ec_contract
    get_api_value(ecs.field_ec_contract) || earlychild.andand.gsccontract
  end

  def ec_months_of_operation
    get_api_value(ecs.field_months_of_operation) || earlychild.andand.monthsofoperation
  end

  def ec_email
    get_api_value(ecs.field_ec_email) || earlychild.andand.gscemail
  end

  def ec_phone
    ecs.field_address ? ecs.field_address['und'].first['phone_number'] : earlychild.andand.gscemail
  end

  def ec_published_rating
    ecs.PublishedRating || earlychild.andand.publishedrating
  end

  def ec_message
    get_api_value(ecs.field_ec_message) || earlychild.andand.gscmessage
  end

  def ec_points_total
    ecs.ptsTotal || earlychild.andand.gscpts
  end

  def ec_points_staff
    ecs.ptsStaff || earlychild.andand.gscptsstaff
  end

  def ec_points_family
    ecs.ptsFamily || earlychild.andand.gscptsfamily
  end

  def ec_points_admin
    ecs.ptsAdmin || earlychild.andand.gscptsadmin
  end

  def ec_points_env
    ecs.ptsEnv || earlychild.andand.gscptsenv
  end

  def ec_points_curriculum
    ecs.ptsCurr || earlychild.andand.gscptscurr
  end

  private

  def get_api_value(field)
    if field.is_a?(Hash)
      n = field['und']
      if n.is_a?(Hash)
        n.map do |k, v|
          v.map { |k, v| v if k == 'name'}
        end.flatten.select { |k| !k.blank? }.join(", ")
      else
        n.first['value']
      end
    elsif field.is_a?(Array)
      field.first
    end
  end


end
