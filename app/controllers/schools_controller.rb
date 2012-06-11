class SchoolsController < ApplicationController

  def index
    @schools = School.all
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

    # R, W, M, S, X
    cats = ['R', 'W', 'M', 'S', 'X'].reverse
    school = cats.collect { |i| @school["PCT_PROF_ALLSTUD_11_#{i}_MME_2011"] }.enum_for(:each_with_index).collect { |score, index| [score.to_i, index+1] }
    @high_ac = {
      :school => school,
      :state => school,
      :ticks => [
        "Social Studies (#{@school.TREND_PCT_PROF_ALLSTUD_11_X_MME_2007_2011})",
        "Science (#{@school.TREND_PCT_PROF_ALLSTUD_11_S_MME_2007_2011}",
        "Math (#{@school.TREND_PCT_PROF_ALLSTUD_11_M_MME_2007_2011})",
        "Writing (#{@school.TREND_PCT_PROF_ALLSTUD_11_W_MME_2007_2011})",
        "Reading (#{@school.TREND_PCT_ALLSTUD_11_R_MME_2007_2011})"
      ]
    }
    
    # Elementary school 
    cats = [
      ['ALLSTUD',   'All students'],
      ['FEMALE',    'Female'],
      ['MALE',      'Male'],
      ['LOWINCOME', 'Low Income'],
      ['SPED',      'Special Education'],
    ].reverse
    reading_school = cats.collect { |k,name| @school["PCT_PROF_#{k}_05_R_MEAP_2011"] }.enum_for(:each_with_index).collect { |score, index| [score.to_i, index+1] }
    reading_state = reading_school
    math_school = cats.collect { |k,name| @school["PCT_PROF_#{k}_05_M_MEAP_2011"] }.enum_for(:each_with_index).collect { |score, index| [score.to_i, index+1] }
    @elem_academics = {
      :reading => {
        :school => reading_school,
        :state => reading_school
      },
      :math => {
        :school => math_school,
        :state => math_school
      },
      :ticks => cats.collect { |cat| cat[1] }
    }
    respond_to do |format|
      format.html { }
      #format.pdf { render :layout => false }
    end
  end
  
end
