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
    :earlychild, :esd_el_2014, :esd_k8_2014, :esd_hs_2014, :esd_site_visit_2014, :fiveessentials_2014].each do |k|
    serialize k, OpenStruct
  end
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
  
  def elementary?;  k8? or k12?; end
  def middle?;      k8? or k12?; end
  def high?;        school_type == GRADES[:high] or k12?; end
  def k8?;          school_type == GRADES[:k8]; end
  def k12?;         school_type == GRADES[:k12]; end
  def earlychild?;  school_type == 'EC'; end
  
  def display?;     self.basic.scorecard_display == '1'; end
  
  def my_properties
    kinds = []
    kinds << 'earlychild' if earlychild?
    kinds << 'elementary' if elementary?
    kinds << 'middle' if middle?
    kinds << 'high' if high?
    
    k12 = (School.where(:bcode => self.bcode).count == 2)
    result = {
      :name       => self.name,
      :bcode      => self.bcode,
      :level      => k12 ? 'K12' : (self.high? ? 'HS' : (self.earlychild? ? 'EC' : 'K8')),
      :classes    => kinds.join(' '),
      :cumulative => self.grades[:cumulative][:letter],
      :seal       => earlychild? ?
        seal_image(:mini, self.esd_el_2014.andand.overall_rating) :
        School.grade_image(self.overall_grade, :small)
    }
    # FIXME inefficient
    others = School.where(:centroid => self.centroid).select('id, name, address, school_type, grades_served, bcode, slug') - [self]
    result[:others] = others.collect { |o| { :id => o.id, :name => o.name, :slug => o.slug, :grades => o.grades_served } } unless others.empty?
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
      }[self.esd_el_2014.andand.overall_rating] || 0
      return mul * 100 + self.earlychild.andand.gscpts.to_i
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
      
    elsif self.earlychild
      h[:status][:summary_table] = summary_table(:status)
      return h
      
    end

    [:status, :progress, :climate].each { |s| h[s][:summary_table] = summary_table(s) }
    h[:status][:details] = details(:status)
    h[:status][:history] = history(:status)
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
            :value    => e.pr2_math.to_f.round(2),
            :points   => e.pr2_math_pts,
            :possible => e.pr2_math_ptsps },
          { :name     => "Percent of Students Proficient in Reading & Writing (2-Year Average)",
            :key      => :pr2_ela,
            :value    => e.pr2_ela.to_f.round(2),
            :points   => e.pr2_ela_pts,
            :possible => e.pr2_ela_ptsps },
          { :name     => "Percent of Students Proficient in Science & Social Studies (2-Year Average)",
            :key      => :pr2_other,
            :value    => e.pr2_other.to_f.round(2),
            :points   => e.pr2_other_pts,
            :possible => e.pr2_other_ptsps }
        ] 
      end
      if high? and e = self.esd_hs_2014
        h += [
          { :name     => "ACT Composite Score (2 Year Average)",
            :key      => :act2_comp,
            :value    => e.act2_comp.to_f.round(1),
            :points   => e.act2_comp_pts,
            :possible => e.act2_comp_psspts },
          { :name     => "Percent College Ready Measured by ACT Scores",
            :key      => :act2_pcr,
            :value    => e.act2_pcr.to_f.round(2),
            :points   => e.act2_pcr_pts,
            :possible => e.act2_pcr_psspts },
        ]
        h += [
          { :name     => "4-Year Graduation Rate, Class 2012",
            :key      => :gradrate,
            :value    => e.gradrate.to_f.round(2),
            :points   => e.gradrate_pts,
            :possible => e.gradrate_psspts },
        ] unless e.gradrate.blank?
      end
      
      if earlychild? and ec = self.earlychild
        h += [
          #{ :name => 'Total Score',
          #  :key  => :gscpts,
          #  :points => ec.gscpts,
          #  :possible => 50,
          #},
          { :name => 'Staff Qualifications and Professional Development',
            :key => :gscptsstaff,
            :points => ec.gscptsstaff,
            :possible => 16,
          },
          { :name => 'Family and Community Partnerships',
            :key => :gscptsfamily,
            :points => ec.gscptsfamily,
            :possible => 8,
          },
          { :name => 'Administration and Management',
            :key => :gscptsadmin,
            :points => ec.gscptsadmin,
            :possible => 6,
          },
          { :name => 'Environment',
            :key => :gscptsenv,
            :points => ec.gscptsenv,
            :possible => 8,
          },
          { :name => 'Curriculum and Instruction',
            :key => :gscptscurr,
            :points => ec.gscptscurr,
            :possible => 12,
          },
        ]
      end
    end
    
    if cat == :progress
      if elementary? and e = self.esd_k8_2014
        h += [
          { :name     => " Percent of Students Making Progress on MEAP",
            :key      => :plc_comp,
            :value    =>  e.plc_comp.to_f.round(2),
            :points   =>  e.plc_comp_pts,
            :possible =>  e.plc_comp_ptsps },
          { :name     => "Percent of Students Reaching their 1-Year Growth Target (Math & Reading)",
            :key      => :bench_comp,
            :value    =>  e.bench_comp.to_f.round(2),
            :points   =>  e.bench_comp_pts,
            :possible =>  e.bench_comp_ptsps }
        ]
      end
              
      if high? and e = esd_hs_2014
        h += [
          { :name     => "Year-over-Year ACT Composite Score Gain (2 Year Average, 2010-11 to 2011-12, 2011-12 to 2012-13)",
            :key      => :act_grwth,
            :value    => e.act_grwth.to_f.round(2),
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
              :value    => e.site_s.to_f.round(2),
              :points   => e.site_s_pts,
              :possible => e.site_s_ptsps },
            { :name     => "Net 5Essentials Score (2012-13)",
              :key      => :net5e_1213,
              :value    => e.net5e,
              :points   => e.net5e_pts,
              :possible => e.net5e_ptsps },
            { :name     => "5Essentials Trend",
              :key      => :five_e_grwth,
              :value    => e.five_e_grwth,
              :points   => e.five_e_grwth_pts,
              :possible => e.five_e_grwth_ptsps },
          ]
      elsif high? and e = self.esd_hs_2014
        h += [
          { :name     => "Community-Led Site Visit Score",
            :key      => :site_s,
            :value    => e.site_s.to_f.round(2),
            :points   => e.site_s_pts,
            :possible => e.site_s_psspts },
          { :name     => "Net 5Essentials Score (2012-13)",
            :key      => :net5e_1213,
            :value    => e.net5e,
            :points   => e.net5e_pts,
            :possible => e.net5e_psspts },
          { :name     => "5Essentials Trend",
            :key      => :five_e_grwth,
            :value    => e.five_e_grwth,
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
      dump = meap_2012.andand.marshal_dump
      return {} if dump.nil?
      if k8?
        [:math, :reading].each do |subject|   # used to have :science
          h[subject] = {}
          #logger.info dump.inspect
          grades = (3..8).select { |g| dump.has_key? "grade_#{g}_#{subject}_tested".to_sym }
          #logger.info grades.inspect
          grades.each do |g|
            next if g == 3 and subject == :math  # Weird, it's 100% everywhere for now
            prof   = dump["grade_#{g}_#{subject}_proficient".to_sym].to_i
            tested = dump["grade_#{g}_#{subject}_tested".to_sym].to_i
            prof   = (prof == 9)   ? 0 : prof
            tested = (tested == 9) ? 0 : tested
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
          a[subject] = act.andand[key].to_i
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
      2012 => meap_2012.andand.marshal_dump,
      2011 => meap_2011.andand.marshal_dump,
      2010 => meap_2010.andand.marshal_dump,
      2009 => meap_2009.andand.marshal_dump
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
          h[grade][subject][year] = percent unless percent.nil?
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
    return nil if tested == 0
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
    normalize_url(self.profile.andand.school_url)
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
  
  
  def self.seal_image(category, rating)
    return 'el_icons/Overview.png' if category == :overview
    return 'el_icons/EL_Award_Participant.png' if ![:community, :state, :staff].include?(category) and rating.andand.match(/Below|Not/)
    cat = {
      :overall    => 'Award',
      :mini       => 'Mobile',
      :community  => 'Sub_Comm',
      :state      => 'Sub_State',
      :staff      => 'Sub_Staff',
    }[category]
    
    valid_metals = ['Bronze', 'Silver', 'Gold']
    metal = valid_metals.include?(rating) ? rating : ((category == :overall and !rating.nil?)? 'Participant' : 'None')
    
    "el_icons/EL_#{cat}_#{metal}.png"
  end
  
  def seal_image(category, rating)
    School.seal_image(category, rating)
  end
  
  def self.grade_image(letter, style=:normal)
    valid = %w[A Aplus B Bplus C Cplus D F]
    mod = letter.andand.gsub('+', 'plus')
    mod = valid.include?(mod) ? mod : 'NA'
    return "el_icons/Sm_#{mod}.png" if style == :small
    "el_icons/K12_Grade_#{mod}.png"
  end
  
end