class SchoolsController < ApplicationController

  def index
    if params[:zip]
      @zip = params[:zip].to_i
      @schools = School.where(['SCHOOL_CITY_STATE_ZIP_2011 like ?', "%#{@zip}"])
      @title = "Schools in #{@zip}"
    elsif params[:filter]
      filter = params[:filter]
      redirect_to schools_path and return unless ['elementary', 'middle', 'high'].include? filter
      @schools = School.send(filter)
      @title = "#{filter.capitalize} Schools"
    else
      @schools = School
      @title = "All Schools"
    end
    @schools = @schools.order('SCHOOL_NAME_2011')
    
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

    # R, W, M, S, X
    cats = ['R', 'W', 'M', 'S', 'X'].reverse
    
    munge = Proc.new { |school, arr, field|
      arr.collect { |i| school[field.gsub('#{i}', i)] }.enum_for(:each_with_index).collect { |score, index| [score.andand.to_i, index+1] }
    }
    
    school = munge.call(@school, cats, 'PCT_PROF_ALLSTUD_11_#{i}_MME_2011')
    state = munge.call(@school, cats, 'PCT_PROF_MI_ALLSTUD_11_#{i}_MME_2011')
    @high_ac = {
      :empty => school.reject { |s| s[0].nil? }.empty?,
      :school => school,
      :state => state,
      :ticks => [
        "Social Studies (#{@school.TREND_PCT_PROF_ALLSTUD_11_X_MME_2007_2011})",
        "Science (#{@school.TREND_PCT_PROF_ALLSTUD_11_S_MME_2007_2011})",
        "Math (#{@school.TREND_PCT_PROF_ALLSTUD_11_M_MME_2007_2011})",
        "Writing (#{@school.TREND_PCT_PROF_ALLSTUD_11_W_MME_2007_2011})",
        "Reading (#{@school.TREND_PCT_PROF_ALLSTUD_11_R_MME_2007_2011})"
      ]
    }
    
    # Elementary school 
    cats = [
      ['ALLSTUD',   'All students'],
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
    third_ticks = ["3rd Grade Reading"]
    third_ticks[0] += " (#{@school.TREND_PCT_PROF_ALLSTUD_03_R_MEAP_2007_2011})" unless @school.TREND_PCT_PROF_ALLSTUD_03_R_MEAP_2007_2011.nil?
    
    reading_ticks = @r_cats.collect { |cat| cat[1] }
    reading_ticks[reading_ticks.size-1] += " (Trend: #{@school.TREND_PCT_PROF_ALLSTUD_ALL_R_MEAP_2007_2011})"
    math_ticks = @m_cats.collect { |cat| cat[1] }
    math_ticks[math_ticks.size-1] += " (Trend: #{@school.TREND_PCT_PROF_ALLSTUD_ALL_M_MEAP_2007_2011})"
    
    @elem_academics = {
      :reading => {
        :school => reading_school,
        :state => reading_state,
        :ticks => reading_ticks
      },
      :math => {
        :school => math_school,
        :state => math_state,
        :ticks => math_ticks
      },
      :third => {
        :school => third_school,
        :state => third_state,
        :ticks => third_ticks
      },
    }
    respond_to do |format|
      format.html { }
      #format.pdf { render :layout => false }
    end
  end
  
  def increment
    if params[:by] == 1
      s = School.first(:conditions => ["id > ?", params[:id].to_i]) || School.first
    elsif params[:by] == -1
      s = School.last(:conditions => ["id < ?", params[:id].to_i]) || School.last
    end
    redirect_to (s || schools_path)
  end
  
end
