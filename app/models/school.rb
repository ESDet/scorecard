class School < ActiveRecord::Base
  require 'bedrock/acts_as_feature'
  require 'bedrock/acts_as_geocoded'
  
  acts_as_feature :geometry => 'centroid', :fields => [:id, :name, :address, :address2, :grades_served, :slug, :grade, :points], :add_properties => :my_properties
  #acts_as_geocoded :address => :address, :point => :centroid, :sleep => 0.15
  utm_factory = RGeo::Geographic.projected_factory(:projection_proj4 => "+proj=utm +zone=17 +ellps=WGS84 +datum=WGS84 +units=m +no_defs")
  set_rgeo_factory_for_column(:centroid, utm_factory)
  
  require 'mogrify'
  include Mogrify
  [:basic, :profile, :meap_2012, :meap_2011, :meap_2010, :meap_2009, :esd_k8_2013, :esd_hs_2013, :act_2013].each do |k|
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
    :early      => 'Early childhood',
    :k8         => 'K8',
    :k12        => 'K12',
    :suburban   => 'Suburban',
    :elementary => ['Early childhood', 'K8', 'K12'],
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
  
  GRADES.each do |k,v|
    scope k,         where(:school_type => v)
  end
  
  TYPES.each do |k,v|
    scope k,         where(:sch => v)
  end
  
  def elementary?;  k8? or k12?; end
  def middle?;      k8? or k12?; end
  def high?;        school_type == GRADES[:high] or k12?; end
  def k8?;          school_type == GRADES[:k8]; end
  def k12?;         school_type == GRADES[:k12]; end
  
  def display?;     self.basic.scorecard_display == '1'; end
  
  def my_properties
    kinds = []
    kinds << 'elementary' if elementary?
    kinds << 'middle' if middle?
    kinds << 'high' if high?
    
    result = {
      :name       => self.name,
      :level      => self.k12? ? 'K12' : (self.high? ? 'HS' : 'K8'),
      :classes    => kinds.join(' '),
      :cumulative => self.grades[:cumulative][:letter]
    }
    others = School.where(['address = ? and id <> ?', self.address, self.id]).select('id, name, address, grades_served, bcode, slug')
    result[:others] = others.collect { |o| { :id => o.id, :name => o.name, :slug => o.slug, :grades => o.grades_served } } unless others.empty?
    return result
  end
  
  def esd
    self.esd_hs_2013 || self.esd_k8_2013
  end
  
  # For really simple sorting
  def total_points 
    highs = {
      'Mature' => :total_pts,
      'New' => :total_pts,
      'Turnaround' => :turnaround_pts,
      'Specialty' => :total_pts,
    }
    elems = {
      'Mature' => :pts_earned,
      'New' => :pts_earned,
      'Turnaround' => :turnaround_pts_earned,
    }
      
    if high? and self.esd_hs_2013
      sym = highs[self.esd_hs_2013.schoolcategory]
      return nil if sym.nil?
      return self.esd_hs_2013.send(sym).to_i
    elsif elementary? and self.esd_k8_2013
      sym = elems[self.esd_k8_2013.schoolcategory]
      return nil if sym.nil?
      return self.esd_k8_2013.send(sym).to_i
    end
    return nil
  end
  
  def overall_grade
    fields = {
      'Mature'      => :mature_ltrgrade,
      'New'         => :newschool_designation,
      'Turnaround'  => :turnaround_designation,
      'Specialty'   => nil,
    }
      
    if high? and self.esd_hs_2013
      sym = fields[self.esd_hs_2013.schoolcategory]
      return nil if sym.nil?
      return self.esd_hs_2013.send(sym)
    elsif elementary? and self.esd_k8_2013
      sym = fields[self.esd_k8_2013.schoolcategory]
      return nil if sym.nil?
      return self.esd_k8_2013.send(sym)
    end
    return nil
  end
  
  
  
  def grades
    cat = esd.andand.schoolcategory
    
    h = { :cumulative => {}, :status => {}, :progress => {}, :climate => {}, :other => {} }
    return h if esd.nil?
    
    if self.esd_hs_2013
      # Common to all HS varieties:
      h[:status] = {
        :letter   => esd.status_ltrgrade.blank? ? 'NG' : esd.status_ltrgrade,
        :total    => esd.status_pts,
        :possible => esd.status_psspts,
        :details  => [] }
      h[:progress] = {
        :letter   => esd.progress_ltrgrade.blank? ? 'NG' : esd.progress_ltrgrade,
        :total    => esd.progress_pts,
        :possible => esd.progress_psspts }
      h[:climate] = {
        :letter   => esd.culture_ltrgrade.blank? ? 'NG' : esd.culture_ltrgrade,
        :total    => esd.culture_pts,
        :possible => esd.culture_psspts }
      h[:other] = {
        :total    => esd.studchrs_pts.to_i + esd.fafsa_rate_pts.to_i }

      if cat == 'Mature'
        h[:cumulative] = {
          :letter   => esd.mature_ltrgrade.blank? ? 'NG' : esd.mature_ltrgrade,
          :total    => esd.total_pts,
          :possible => esd.total_psspts,
          :percent  => esd.mature_pct }
      
      elsif cat == 'New'
        h[:cumulative] = {
          :letter   => esd.newschool_designation.blank? ? 'NG' : esd.newschool_designation,
          :total    => esd.total_pts,
          :possible => esd.total_psspts,
          :percent  => esd.newschool_pct }
          
      elsif cat == 'Turnaround'
        h[:cumulative] = {
          :letter   => esd.turnaround_designation.blank? ? 'NG' : esd.turnaround_designation,
          :total    => esd.turnaround_pts,
          :possible => esd.turnaround_psspts,
          :percent  => esd.turnaround_pct }
      end
      
    elsif self.esd_k8_2013
      # Common to all the K8 varieties..
      h[:status] = {
        :letter   => esd.status_ltrgrade.blank? ? 'NG' : esd.status_ltrgrade,
        :total    => esd.pts_status,
        :possible => esd.ptspos_status,
        :details  => [] }
      h[:progress] = {
        :letter   => esd.progress_ltrgrade.blank? ? 'NG' : esd.progress_ltrgrade,
        :total    => esd.pts_progress,
        :possible => esd.ptspos_progress }
      h[:climate] = {
        :letter   => esd.culture_ltrgrade.blank? ? 'NG' : esd.culture_ltrgrade,
        :total    => esd.pts_culture,
        :possible => esd.ptspos_culture }
      h[:other] = {
        :total    => esd.studchrs_pts }

      if cat == 'Mature'
        h[:cumulative] = {
          :letter   => esd.mature_ltrgrade.blank? ? 'NG' : esd.mature_ltrgrade,
          :total    => esd.pts_earned,
          :possible => esd.pts_possible,
          :percent  => esd.mature_pct }
        
      elsif cat == 'New'
        h[:cumulative] = {
          :letter   => esd.newschool_designation.blank? ? 'NG' : esd.newschool_designation,
          :total    => esd.pts_earned,
          :possible => esd.pts_possible,
          :percent  => esd.newschool_pct }
      
      elsif cat == 'Turnaround'
        h[:cumulative] = {
          :letter   => esd.turnaround_designation.blank? ? 'NG' : esd.turnaround_designation,
          :total    => esd.turnaround_pts_earned,
          :possible => esd.turnaround_pts_possible,
          :percent  => esd.turnaround_pct }
      end
      
    end

    [:status, :progress, :climate].each { |s| h[s][:summary_table] = summary_table(s) }
    h[:status][:details] = details(:status)
    h[:status][:history] = history(:status)

    return h
  end
  
  
  def summary_table(cat)
    h = []
    if cat == :status
      if elementary? and e = self.esd_k8_2013
        h += [
          { :name     => "Math Proficienty Rate (2-Year Avg)",
            :value    => esd.pr2_math.to_f.round(2),
            :points   => esd.pr2_math_pts,
            :possible => esd.pr2_math_ptsps },
          { :name     => "ELA (Reading + Writing) Proficiency Rate (2-Year Average)",
            :value    => esd.pr2_ela.to_f.round(2),
            :points   => esd.pr2_ela_pts,
            :possible => esd.pr2_ela_ptsps },
          { :name     => "Other (Science & Social Studies) Proficiency Rate (2-Year Average)",
            :value    => esd.pr2_other.to_f.round(2),
            :points   => esd.pr2_other_pts,
            :possible => esd.pr2_other_ptsps }
        ] 
      end
      if high? and e = self.esd_hs_2013
        h += [
          { :name     => "ACT Composite Score (2 Year Average)",
            :value    => esd.act2_comp.to_f.round(1),
            :points   => esd.act2_comp_pts,
            :possible => esd.act2_comp_psspts },
          { :name     => "ACT Percent College Ready",
            :value    => esd.act2_pcr.to_f.round(2),
            :points   => esd.act2_pcr_pts,
            :possible => esd.act2_pcr_psspts },
          { :name     => "Graduation Rate (2011-12)",
            :value    => esd.gradrate.to_f.round(2),
            :points   => esd.gradrate_pts,
            :possible => esd.gradrate_psspts },
        ]
      end
    end
    
    if cat == :progress
      if elementary? and e = self.esd_k8_2013
        h += [
          { :name     => "Performance Level Change Score",
            :value    =>  e.plc_comp.to_f.round(2),
            :points   =>  e.plc_comp_pts,
            :possible =>  e.plc_comp_ptsps },
          { :name     => "NWEA/Scantron Percent Meeting Growth Target",
            :value    =>  e.bench_comp.to_f.round(2),
            :points   =>  e.bench_comp_pts,
            :possible =>  e.bench_comp_ptsps }
        ]
      end
              
      if high? and e = esd_hs_2013
        h += [
          { :name     => "Year-over-Year ACT Composite Score Gain (2 Year Average, 2010-11 to 2011-12, 2011-12 to 2012-13)",
            :value    => e.act_grwth.to_f.round(2),
            :points   => e.act_grwth_pts,
            :possible => e.act_grwth_psspts },
        ]
      end
    end
    
    if cat == :climate
      if elementary? and e = self.esd_k8_2013
          h += [
            { :name     => "Site Visit Average Score",
              :value    => e.site_s.to_f.round(2),
              :points   => e.site_s_pts,
              :possible => e.site_s_ptsps },
            { :name     => "Net 5Essentials Score (2012-13)",
              :value    => e.net5e_1213,
              :points   => e.net5e_1213_pts,
              :possible => e.net5e_1213_ptsps },
            { :name     => "5Essentials Growth Score",
              :value    => e.five_e_grwth,
              :points   => e.five_e_grwth_pts,
              :possible => e.five_e_grwth_ptsps },
          ]
      elsif high? and e = self.esd_hs_2013
        h += [
          { :name     => "Site Visit Average Score",
            :value    => e.site_s.to_f.round(2),
            :points   => e.site_s_pts,
            :possible => e.site_s_psspts },
          { :name     => "Net 5Essentials Score (2012-13)",
            :value    => e.net5e_1213,
            :points   => e.net5e_1213_pts,
            :possible => e.net5e_1213_psspts },
          { :name     => "5Essentials Growth Score",
            :value    => e.five_e_grwth,
            :points   => e.five_e_grwth_pts,
            :possible => e.five_e_grwth_psspts },
        ]
      end
    end
    
    h
  end
  
  # So far only Academic Status tab implemented
  def details(tab)
    throw "Not implemented yet" unless tab == :status
    h = {}
    dump = meap_2012.marshal_dump
    if k8?
      [:math, :reading].each do |subject|   # used to have :science
        h[subject] = {}
        logger.info dump.inspect
        grades = (3..8).select { |g| logger.info "grade_#{g}_#{subject}_tested"; dump.has_key? "grade_#{g}_#{subject}_tested".to_sym }
        logger.info grades.inspect
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
      act = act_2013.andand.marshal_dump
      
      logger.ap act
      # Bar charts with % meeting for All Subjects, Reading, Math, Science, and English (exclude Null values) from ACT 2013
      [:allsub, :reading, :math, :english, :science].each do |subject|
        key = "#{subject}percentmeeting".to_sym
        logger.info "#{key} = #{act[key]}"
        a[subject] = act.andand[key].to_i
      end
      h[:act] = a
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
end