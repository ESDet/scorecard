class SchoolsController < ApplicationController

  caches_action :index, :if => proc { request.format.json? }, :cache_path => Proc.new { |controller| controller.params.merge({ :v => AppConfig.cache_key }) }
  caches_action :overview, :cache_path => Proc.new { |controller| controller.params.merge({ :v => AppConfig.cache_key }) }
  

  
  def index
    filter = ['all', 'k8', 'high'].include?(params[:filter]) ? params[:filter] : nil
    type = School::TYPES.keys.include?(params[:type].andand.to_sym) ? params[:type] : nil
    session[:filter]  = filter
    session[:type]    = type
    session[:loc]     = params[:loc]
    
    @title = current_search    
    @schools = scope_from_filters(filter, type, params[:loc]).order('points desc')
    #@schools = @schools.all if @schools.is_a?(Class)
    #@schools = @schools.sort { |a,b| b.points.to_i <=> a.points.to_i }

    respond_to do |format|
      format.html do
        @school_o = Bedrock::Overlay.from_config('schools',
          :ty         => :geojson,
          :url        => schools_path(:format => :json, :filter => session[:filter], :loc => session[:loc], :type => session[:type]),
          :mouseover  => true,
          :key => {
            '#f48b68' => 'K8 Schools',
            '#00aff0' => 'High Schools',
            '#ff00ff' => 'K12 Schools',
          })
        @district_o = Bedrock::Overlay.from_config('districts',
          :ty => :geojson,
          :elements => [District.find(580)])
        @map = Bedrock::Map.new({
          #:extent         => Bedrock::city_extents(:detroit),
          :base_layers    => ['street'],
          :layers         => [ @district_o, @school_o ],
          :layer_control  => true,
          :center => { :lon => -83.09577941894531, :lat => 42.364885996366525 },
          :min_zoom => 11,
          :max_zoom => 18,
          :zoom => 12,
          :layer_control => false,
        })
        render :layout => 'noside'
      end
      format.json do
        render :json => Bedrock::to_feature_collection(@schools.reject { |s| s.centroid.nil? })
      end
    end
  end
  
  def show
    begin
      @school = School.find_by_slug(params[:id]) || School.find(params[:id])
      redirect_to root_path and return if @school.nil?
    rescue
      render :text => '' and return if params[:id] == 'PIE' # PIE.htc requests
      redirect_to root_path and return
    end
    
    @subtitle = @school.name
        
    @school_o = Bedrock::Overlay.from_config('schools',
      :ty       => :geojson,
      :elements => [@school])
    @det_o = Bedrock::Overlay.from_config('districts',
      :ty => :geojson,
      :elements => [District.find(580)]
    )
    @map = Bedrock::Map.new({
      :base_layers    => ['street'],
      :layers         => [ @det_o, @school_o ],
      :layer_control  => true,
      :min_zoom => 10,
      :max_zoom => 18,
      :extent => Bedrock::city_extents(:detroit),
      :layer_control => false,
    })
    
    @grades = @school.grades
    
    @profile_fields = {
      "after_school_transportatio" => 'After School Transportation',
      "ap_classes" => 'AP Classes',
      "character_development" => 'Character Development',
      "college_counseling" => 'College Counseling',
      "counselor_student_ratio" => 'Counselor-to-Student Ratio',
      "discipline_programs" => 'Discipline Programs',
      "dual_enrollment" => 'Dual Enrollment',
      "dual_enrollment_institutio" => 'Dual Enrollment Institution',
      "early_child_center_relatio" => 'Early Childhood Center Relations',
      "early_childhood_programs" => 'Early Childhood Programs',
      "early_childhood_transition" => 'Early Childhood Transition',
      "email" => 'Email',
      "english_language_learners" => 'English Language Learners',
      "family_supports" => 'Family Support',
      #"grades_served" => 'Grades Served',
      "in_school_programs" => 'In-School Programs',
      "organized_sports" => 'Sports',
      "parent_supports" => 'Parent Support',
      #"school_contact_first_name",
      #"school_contact_last_name",
      "special_needs" => "Special Needs Students",
      "special_tracks" => "Special Tracks",
      "student_development_progra" => "Student Development Programs",
      "student_leadership_opportu" => "Student Leadership Opportunities",
      "transportation" => "Transportation",
    }

    ethnicities = %w(american_indian asian african_american hispanic hawaiian white two_or_more_races)
    @demographics = ethnicities.collect do |e|
      num = @school.meap_2012.send("#{e}_enrollment").to_s.gsub(/[^0-9]/, '').to_i
      num = 0 if num == 9
      [ "#{e.titleize}: #{num}", num]
    end
    
    @enrollment = %w(kindergarten 1 2 3 4 5 6 7 8 9 10 11 12).collect do |g|
      num = @school.meap_2012.send("grade_#{g}_enrollment").to_s.gsub(/[^0-9]/, '').to_i
      num = 0 if num == 9
      num
    end
    @enroll_ticks = %w(K 1 2 3 4 5 6 7 8 9 10 11 12)
    

    @tips = Hash[*(Tip.all.collect { |t| [t.name, t] }.flatten)]
    @category_copy = {
      'Turnaround' => ['Fresh start school',
        "These are schools that Michigan has identified as the lowest achieving five percent of schools in the state.
          They are mandated to perform a rapid turnaround to improve. As part of the mandate, the school has a new operator."],
      'New' => ['New school',
        "This school has been open since 2009 or sooner and as a result of being new, doesn't have the cumulative information
        needed for ESD to assign a grade."],
      'Specialty' => ['Specialty school', 
        "A specialty school serves students that have unique learning needs or skills.
        Examples can include: adult education and alternative learning programs."]
      }

=begin    

    # High school
    # ==============
    # R, W, M, S, X
    cats = ['R', 'W', 'M', 'S', 'X'].reverse
    
    munge = Proc.new { |school, arr, field|
      arr.collect { |i| school[field.gsub('#{i}', i)] }.enum_for(:each_with_index).collect { |score, index| [score.andand.to_i, index+1] }
    }
    
    high_school = munge.call(@school, cats, 'PCT_PROF_ALLSTUD_11_#{i}_MME_2012')
    high_state = munge.call(@school, cats, 'PCT_PROF_MI_ALLSTUD_11_#{i}_MME_2012')
    @high_ac = {
      :empty => high_school.reject { |s| s[0].nil? }.empty?,
      :school => {
        :scores => high_school,
        :labels => high_school.collect { |s| "#{s[0]}%" },
      },
      :state => {
        :scores => high_state,
        :labels => high_state.collect { |s| "#{s[0]}%" },
      },
      :ticks => [
        "Social Studies (#{@school.TREND_PCT_PROF_ALLSTUD_11_X_MME_2008_2012})",
        "Science (#{@school.TREND_PCT_PROF_ALLSTUD_11_S_MME_2008_2012})",
        "Math (#{@school.TREND_PCT_PROF_ALLSTUD_11_M_MME_2008_2012})",
        "Writing (#{@school.TREND_PCT_PROF_ALLSTUD_11_W_MME_2008_2012})",
        "Reading (#{@school.TREND_PCT_PROF_ALLSTUD_11_R_MME_2008_2012})"
      ]
    }
    
    @high_act = {
      :school => [ [@school.AVG_ALLSTUD_ALLSUB_ACT_2012.andand.round(1) || 'N/A' , 1 ] ],
      :state => [ [@school.AVG_MI_ALLSTUD_ALLSUB_ACT_2012.andand.round(1) || 'N/A', 1] ],
      :ticks => [ "Trend: #{@school.TREND_ALLSTUD_ALLSUB_ACT_2008_2012 || 'N/A'}" ],
    }
    @high_grad = {
      :school => [ [@school.PCT_ALLSTUD_12_GRAD_4YR_2012.andand.round(0) || 'N/A' , 1 ] ],
      :state => [ [@school.PCT_MI_ALLSTUD_12_GRAD_4YR_2012.andand.round(0) || 'N/A', 1] ],
      :ticks => [ "Trend: #{@school.TREND_ALLSTUD_12_GRAD_4YR_2007_2011 || 'N/A'}" ],
    }
    
    # Elementary school 
    cats = [
      ['ALLSTUD',   'All'],
      ['FEMALE',    'Female'],
      ['MALE',      'Male'],
      ['LOWINCOME', 'Low Income'],
      ['SPED', 'Special Education']
    ].reverse
    
    @r_cats = cats.reject { |c| @school["PCT_PROF_#{c[0]}_ALL_R_MEAP_2012"].nil? }
    @m_cats = cats.reject { |c| @school["PCT_PROF_#{c[0]}_ALL_M_MEAP_2012"].nil? }
    
    reading_school = munge.call(@school, @r_cats.collect { |c| c[0] }, 'PCT_PROF_#{i}_ALL_R_MEAP_2012')
    reading_state  = munge.call(@school, @r_cats.collect { |c| c[0] }, 'PCT_PROF_MI_#{i}_ALL_R_MEAP_2012')
    math_school    = munge.call(@school, @m_cats.collect { |c| c[0] }, 'PCT_PROF_#{i}_ALL_M_MEAP_2012')
    math_state     = munge.call(@school, @m_cats.collect { |c| c[0] }, 'PCT_PROF_MI_#{i}_ALL_M_MEAP_2012')
    
    third_school = munge.call(@school, ['R'], 'PCT_PROF_ALLSTUD_03_#{i}_MEAP_2012')
    third_state = munge.call(@school, ['R'], 'PCT_PROF_MI_ALLSTUD_03_#{i}_MEAP_2012')
    third_ticks = ["Proficiency"]
    third_ticks[0] += " (#{@school.TREND_PCT_PROF_ALLSTUD_03_R_MEAP_2007_2011})" unless @school.TREND_PCT_PROF_ALLSTUD_03_R_MEAP_2007_2011.nil?
    
    reading_ticks = @r_cats.collect { |cat| cat[1] }
    reading_ticks[reading_ticks.size-1] += " (Trend: #{@school.TREND_PCT_PROF_ALLSTUD_ALL_R_MEAP_2007_2011})" unless reading_ticks.empty? or @school.TREND_PCT_PROF_ALLSTUD_ALL_R_MEAP_2007_2011.blank?
    math_ticks = @m_cats.collect { |cat| cat[1] }
    math_ticks[math_ticks.size-1] += " (Trend: #{@school.TREND_PCT_PROF_ALLSTUD_ALL_M_MEAP_2007_2011})" unless math_ticks.empty? or @school.TREND_PCT_PROF_ALLSTUD_ALL_M_MEAP_2007_2011.blank?
    
    @elem_academics = {
      :reading => {
        :school => {
          :scores => reading_school,
          :labels => reading_school.collect { |s| "#{s[0]}%" }
        },
        :state => {
          :scores => reading_state,
          :labels => reading_state.collect  { |s| "#{s[0]}%" }        
        },
        :ticks => reading_ticks,
      },
      :math => {
        :school => {
          :scores => math_school,
          :labels => math_school.collect { |s| "#{s[0]}%" },
        },
        :state => {
          :scores => math_state,
          :labels => math_state.collect  { |s| "#{s[0]}%" },
        },
        :ticks => math_ticks,
      },
      :third => {
        :school => {
          :scores => third_school,
          :labels => third_school.collect  { |s| "#{s[0]}%" },
        },
        :state => {
          :scores => third_state,
          :labels => third_state.collect { |s| "#{s[0]}%" },
        },
        :ticks => third_ticks,
      },
    }
    
    @history = [ ]
    if @school.high?
      ['AVG_ALLSTUD_ALLSUB_ACT_', 'PCT_ALLSTUD_12_GRAD_4YR_'].each do |m|
        series = (2007..2012).collect { |year| [year, @school[m + year.to_s]] }.reject { |x| x[1].nil? }
        @history << series
      end
      @history_labels = ['Avg ACT Score', '4-Year Graduation Rate', '']
    else
      ['PCT_PROF_ALLSTUD_ALL_R_MEAP_', 'PCT_PROF_ALLSTUD_ALL_M_MEAP_', 'PCT_PROF_ALLSTUD_03_R_MEAP_'].each do |m|
        series = (2007..2012).collect { |year| [year, @school[m + year.to_s]] }.reject { |x| x[1].nil? }
        @history << series 
      end
      @history_labels = ['All Students MEAP Proficiency (Reading)', 'All Students MEAP Proficiency (Math)', '3rd Grade Reading Proficiency']
    end
    
=end
    respond_to do |format|
      format.html do
        render layout: 'noside'
      end
      #format.pdf { render :layout => false }
    end
  end
  
  def increment
    s = scope_from_filters(session[:filter], session[:type], session[:loc])
    if params[:by] == 1
      s = s.first(:conditions => ["id > ?", params[:id].to_i]) || s.first
    elsif params[:by] == -1
      s = s.last(:conditions => ["id < ?", params[:id].to_i]) || s.last
    end
    redirect_to (s.nil? ? schools_path : school_path(s.slug))
  end
  
  # Ajax update the count of schools matching a filter set
  def overview
    filter = ['all', 'elementary', 'middle', 'high'].include?(params[:filter]) ? params[:filter] : nil
    type = School::TYPES.keys.include?(params[:type].andand.to_sym) ? params[:type] : nil
    session[:filter]  = filter
    session[:type]    = type
    session[:loc]     = params[:loc]
    title = current_search    
    schools = scope_from_filters(filter, type, params[:loc])
    title = title.gsub('All ', '')
    title = title.gsub('Schools', 'School') if schools.count == 1
    render :text => "There #{schools.count==1?'is':'are'} #{schools.count} #{title} in Detroit"
  end
  
  private
  
  def scope_from_filters(filter, type, loc)
    logger.info "scope from filters: #{filter}, #{type}, #{loc}"
    schools = (filter.nil? or filter == 'all') ? School : School.send(filter)
    #schools = schools.send(type) if type
    schools = schools.where(:zip => loc) unless loc.blank?
    return schools
  end
  
end
