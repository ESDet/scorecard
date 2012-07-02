class SchoolsController < ApplicationController

  def index
    filter = ['all', 'elementary', 'middle', 'high'].include?(params[:filter]) ? params[:filter] : nil    
    session[:filter] = filter
    session[:loc] = params[:loc]
    
    @title = current_search    
    @schools = scope_from_filters(filter, params[:loc]).order('SCHOOL_NAME_2011')

    respond_to do |format|
      format.html { }
      format.json do
        render :json => Bedrock::to_feature_collection(@schools)
      end
    end
  end
  
  def show
    @school = School.find params[:id]
    @subtitle = @school.SCHOOL_NAME_2011
        
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
      #:center => { :lon => @school.centroid.x, :lat => @school.centroid.y },
      :min_zoom => 10,
      :max_zoom => 18,
      #:zoom => 12,
      :extent => Bedrock::city_extents(:detroit),
      :layer_control => false,
    })

    ethnicities = [ 'BLACK', 'LATINO', 'WHITE', 'ASIAN', 'OTHER' ]
    @demographics = ethnicities.collect { |e| [ "#{e.capitalize} " + @school["PCT_#{e}_FALL_2011"].to_i.to_s + "%", @school["PCT_#{e}_FALL_2011"] ] }

    @elements = [
      [ 'Effective leaders', 'Principals and teachers implement a shared vision for success.', @school.SCORE_LDR_5E_2012 ],
      [ 'Collaborative teachers', "Teachers collaborate to promote professional growth.", @school.SCORE_TCH_5E_2012 ],
      [ "Involved families", "The entire staff builds external relationships.", @school.SCORE_FAM_5E_2012 ],
      [ "Supportive environment", "The school is safe, demanding, and supportive.", @school.SCORE_ENV_5E_2012 ],
      [ 'Ambitious instruction', "Classes are engaging and challenging.", @school.SCORE_INS_5E_2012 ],
    ]

    @sitevisit = {
      :env => [
        [ 'The school exterior makes a good first impression.', @school.SCHOOL_EXTERIOR_SITEVISIT_2012 ],
        [ 'There are procedures in place to ensure school safety and security.', @school.SAFETY_PROCEDURES_SITEVISIT_2012 ],
        [ 'Physical facilities are well maintained and in good repair.', @school.FACILITY_CONDITION_SITEVISIT_2012 ]
      ],
      :culture => [
        [ 'Student progress and achievement is recognized.', @school.STUDENT_RECOGNITION_SITEVISIT_2012 ],
      ],
      :community => [
        [ 'The school has a clear mission or vision statement.', @school.CLEAR_MISSION_SITEVISIT_2012 ],
        [ 'Teachers appear to have positive relationships with the students.', @school.TCH_STUD_RELATE_SITEVISIT_2012 ],
        [ "Students appear to be following the school's code of conduct.", @school.STUD_BEHAVE_SITEVISIT_2012 ],
        [ 'The school calendar lists activities and programs and is available to staff, students, parents, and the community.', @school.CALENDAR_SITEVISIT_2012 ],
      ]
    }

    @activities = {
      :arts => ('A'..'H').collect { |i| @school["#{i}_ART_CULTURE_ACTIVITIES_2012"] }.reject { |i| i.blank? },
      :wellness => ('A'..'H').collect { |i| @school["#{i}_WELLNESS_FITNESS_ACTIVITIES_2012"] }.reject { |i| i.blank? },
      :academic => ('A'..'H').collect { |i| @school["#{i}_ACADEMIC_ACTIVITES_2012"] }.reject { |i| i.blank? }
    }
    @programs = ('A'..'M').collect { |i| @school["#{i}_PROGRAMS_LEARNING_2012"] }.reject { |i| i.blank? }

    # High school
    # ==============
    # R, W, M, S, X
    cats = ['R', 'W', 'M', 'S', 'X'].reverse
    
    munge = Proc.new { |school, arr, field|
      arr.collect { |i| school[field.gsub('#{i}', i)] }.enum_for(:each_with_index).collect { |score, index| [score.andand.to_i, index+1] }
    }
    
    high_school = munge.call(@school, cats, 'PCT_PROF_ALLSTUD_11_#{i}_MME_2011')
    high_state = munge.call(@school, cats, 'PCT_PROF_MI_ALLSTUD_11_#{i}_MME_2011')
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
        "Social Studies (#{@school.TREND_PCT_PROF_ALLSTUD_11_X_MME_2007_2011})",
        "Science (#{@school.TREND_PCT_PROF_ALLSTUD_11_S_MME_2007_2011})",
        "Math (#{@school.TREND_PCT_PROF_ALLSTUD_11_M_MME_2007_2011})",
        "Writing (#{@school.TREND_PCT_PROF_ALLSTUD_11_W_MME_2007_2011})",
        "Reading (#{@school.TREND_PCT_PROF_ALLSTUD_11_R_MME_2007_2011})"
      ]
    }
    
    @high_act = {
      :school => [ [@school.AVG_ALLSTUD_ALLSUB_ACT_2011.andand.round(1) || 'N/A' , 1 ] ],
      :state => [ [@school.AVG_MI_ALLSTUD_ALLSUB_ACT_2011.andand.round(1) || 'N/A', 1] ],
      :ticks => [ "Trend: #{@school.TREND_ALLSTUD_ALLSUB_ACT_2007_2011 || 'N/A'}" ],
    }
    @high_grad = {
      :school => [ [@school.PCT_ALLSTUD_12_GRAD_4YR_2011.andand.round(0) || 'N/A' , 1 ] ],
      :state => [ [@school.PCT_MI_ALLSTUD_12_GRAD_4YR_2011.andand.round(0) || 'N/A', 1] ],
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
    
    @r_cats = cats.reject { |c| @school["PCT_PROF_#{c[0]}_ALL_R_MEAP_2011"].nil? }
    @m_cats = cats.reject { |c| @school["PCT_PROF_#{c[0]}_ALL_M_MEAP_2011"].nil? }
    
    reading_school = munge.call(@school, @r_cats.collect { |c| c[0] }, 'PCT_PROF_#{i}_ALL_R_MEAP_2011')
    reading_state  = munge.call(@school, @r_cats.collect { |c| c[0] }, 'PCT_PROF_MI_#{i}_ALL_R_MEAP_2011')
    math_school    = munge.call(@school, @m_cats.collect { |c| c[0] }, 'PCT_PROF_#{i}_ALL_M_MEAP_2011')
    math_state     = munge.call(@school, @m_cats.collect { |c| c[0] }, 'PCT_PROF_MI_#{i}_ALL_M_MEAP_2011')
    
    third_school = munge.call(@school, ['R'], 'PCT_PROF_ALLSTUD_03_#{i}_MEAP_2011')
    third_state = munge.call(@school, ['R'], 'PCT_PROF_MI_ALLSTUD_03_#{i}_MEAP_2011')
    third_ticks = ["Proficiency"]
    third_ticks[0] += " (#{@school.TREND_PCT_PROF_ALLSTUD_03_R_MEAP_2007_2011})" unless @school.TREND_PCT_PROF_ALLSTUD_03_R_MEAP_2007_2011.nil?
    
    reading_ticks = @r_cats.collect { |cat| cat[1] }
    reading_ticks[reading_ticks.size-1] += " (Trend: #{@school.TREND_PCT_PROF_ALLSTUD_ALL_R_MEAP_2007_2011})" unless reading_ticks.empty?
    math_ticks = @m_cats.collect { |cat| cat[1] }
    math_ticks[math_ticks.size-1] += " (Trend: #{@school.TREND_PCT_PROF_ALLSTUD_ALL_M_MEAP_2007_2011})" unless math_ticks.empty?
    
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
    respond_to do |format|
      format.html { }
      #format.pdf { render :layout => false }
    end
  end
  
  def increment
    s = scope_from_filters(session[:filter], session[:loc])
    if params[:by] == 1
      s = s.first(:conditions => ["id > ?", params[:id].to_i]) || s.first
    elsif params[:by] == -1
      s = s.last(:conditions => ["id < ?", params[:id].to_i]) || s.last
    end
    redirect_to (s || schools_path)
  end
  
  private
  
  def scope_from_filters(filter, loc)
    logger.info "scope from filters: #{filter}, #{loc}"
    schools = (filter.nil? or filter == 'all') ? School : School.send(filter)
    schools = schools.where(['SCHOOL_CITY_STATE_ZIP_2011 like ?', "%#{loc}"]) unless loc.blank?
    return schools
  end
  
end
