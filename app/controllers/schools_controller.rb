class SchoolsController < ApplicationController

  def index
    @schools = School.all
  end
  
  def show
    @school = School.find params[:id]
    @subtitle = @school.SCHOOL_NAME_2011
    @high = @school.id % 2 == 0 # @school.AUTHORIZED_GRADES_2011 == '9-12'
    
    @school_o = Bedrock::Overlay.from_config('schools',
      :ty       => :geojson,
      :elements => [@school])
    @map = Bedrock::Map.new({
      :base_layers    => ['street'],
      :layers         => [ @school_o ],
      :layer_control  => true,
      :center => { :lon => @school.centroid.x, :lat => @school.centroid.y },
      :min_zoom => 12,
      :max_zoom => 18,
      :zoom => 12,
    })

    ethnicities = [ 'BLACK', 'LATINO', 'WHITE', 'ASIAN', 'OTHER' ]
    @demographics = ethnicities.collect { |e| [ "#{e.capitalize} " + @school["PCT_#{e}_FALL_2011"].to_i.to_s + "%", @school["PCT_#{e}_FALL_2011"] ] }

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
