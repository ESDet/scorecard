class SchoolsController < ApplicationController

  helper_method :format_phone

  def index
    @loc = params[:loc]
    @grade = params[:grade]
    @filters = params[:filters] || []

    @schools = if @loc.andand.match /^[0-9]{5}$/
      OldSchool.where(:zip => loc)
    elsif !@loc.blank?
      OldSchool.where("name like '%#{@loc}%'")
    end

    @schools = if @schools
      @grade.blank? ? @schools : @schools.send(@grade)
    else
      OldSchool.send(@grade) if !@grade.blank?
    end

    case @grade
    when 'ec'
      @filters.each do |f|
        @schools = case f
        when 'free_reduced'
          @schools.select do |s|
            s.subsidy == 'Accepts State Subsidy' ||
            s.specialty == 'Early Head Start' ||
            s.specialty == 'Head Start' ||
            s.specialty == 'Great Start Readiness Program'
          end
        when 'transportation'
          @schools.select do |s|
            s.transportation == true
          end
        when 'special_needs'
          @schools.select do |s|
            s.special && s.ec_special.size > 5
          end
        when 'meals'
          @schools.select do |s|
            s.meals.include?("Lunch") &&
            s.meals.include?("Afternoon Snack")
          end
        when 'home_based'
          @schools.select do |s|
            s.license_type == 'licensed group homes' ||
            s.license_type == 'registered family homes'
          end
        when 'center_based'
          @schools.select do |s|
            s.license_type == 'licensed centers'
          end
        when 'accreditation'
          @schools
        else
          @schools
        end
      end
    when 'k8', 'high'
      @filters.each do |f|
        @schools = case f
        when 'special_education'
          @schools.select do |s|
            s.special_ed_level == 'moderate' ||
            s.special_ed_level == 'intensive'
          end
        when 'arts'
          @schools.select do |s|
            (s.arts_media + s.arts_visual + s.arts_music +
            s.arts_performing_written).size > 8
          end
        when 'sports'
          @schools.select do |s|
            s.boys_sports.size > 4 &&
            s.girls_sports > 4
          end
        when 'transportation'
          @schools.select do |s|
            s.transportation_options == 'passes' ||
            s.transportation_options == 'busses' ||
            s.transportation_options == 'shared_bus'
          end
        when 'before_after_care'
          @schools.select do |s|
            s.before_after_care == 'after' ||
            s.before_after_care == 'before'
          end
        when 'app_required'
          @schools.select do |s|
            s.application_process == 'yes'
          end
        when 'college_readiness'
          @schools.select do |s|
            s.college_prep != 'none' &&
              (s.facilities == 'college_center'||
              s.extra_learning_resources == 'career_counseling' ||
              s.staff_resources == 'college_counselor')
          end
        else
          @schools
        end
      end
    else
      @schools = OldSchool.ec.where('esd_el_2015 is not null').
        order('points desc').limit(50) unless @schools
    end

    respond_to do |format|
      format.html do
        @school_o = Bedrock::Overlay.from_config('schools',
          :ty         => :geojson,
          #:url        => schools_path(:format => :json, :filter => filter, :loc => loc),
          :elements   => @schools,
          :mouseover  => false,
          :key => {
            '#f48b68' => 'K8 Schools',
            '#00aff0' => 'High Schools',
            '#ff00ff' => 'K12 Schools',
            '#134370' => 'Preschools',
          })
        @district_o = Bedrock::Overlay.from_config('districts',
          :ty => :geojson,
          :elements => [District.find(580)])
        @map = Bedrock::Map.new({
          #:extent         => Bedrock::city_extents(:detroit),
          :base_layers    => ['street'],
          :layers         => [ @district_o, @school_o ],
          :layer_control  => true,
          :center => Bedrock::city_extents(:detroit).first,
          :min_zoom => 11,
          :max_zoom => 18,
          :zoom => 12,
          :layer_control => false,
        })
      end
      format.json do
        render :json => Bedrock::to_feature_collection(@schools.reject { |s| s.centroid.nil? })
      end
    end
  end

  def show
    render :text => '' and return if params[:id] == 'PIE' # PIE.htc requests

    school_id = ActiveRecord::Base.connection.execute(
      "select tid from old_schools where slug = '#{params[:id]}'"
    ).first.first

    redirect_to root_path and return unless school_id

    school_type = params[:type]

    url = if school_type == 'ecs'
      "ecs/#{school_id}.json/?flatten_fields=true&includes=most_recent_ec_state_rating,ec_profile"
    else
      "schools/#{school_id}.json/?flatten_fields=true&includes=school_profile,act_2013,act_2012,act_2011meap_2013,meap_2012,meap_2011"
    end

    school_data = Portal.new.fetch(url)

    (redirect_to root_path and return) if school_data.first =~ /does not exist/

    @school = SchoolData.new school_data['data'].merge(included: school_data['included'])

    if @school.earlychild?
      @school.extend(EarlyChildhood)
    else
      @school.extend(School)
    end

    @school_o = Bedrock::Overlay.from_config('schools',
      :ty       => :geojson,
      :elements => [@school])
    @det_o = Bedrock::Overlay.from_config('districts',
      :ty => :geojson,
      :elements => [District.find(580)]
    )
    extent = Bedrock::city_extents(:detroit)
    extent = Bedrock.merge_extents(extent, [
      {
        :lon => @school.field_geo.lon.to_f,
        :lat => @school.field_geo.lat.to_f
      },
      { :lon => @school.field_geo.lon.to_f,
        :lat => @school.field_geo.lat.to_f
      }
    ])

    @map = Bedrock::Map.new({
      :base_layers    => ['street'],
      :layers         => [ @det_o, @school_o ],
      :layer_control  => false,
      :min_zoom       => 5,
      :max_zoom       => 15,
      :zoom           => 15,
      #:extent         => extent,
      :center         => {
        :lon => @school.field_geo.lon.to_f,
        :lat => @school.field_geo.lat.to_f
      }
    })

    if @school.earlychild?
      if @school.esd_el_2015
        @el = @school.esd_el_2015
        if @el.staffsurveyratingyear == "2014"
          @teacher_score_mean = @el.andand.teacher_score_mean_2014
        end
      else
        @el = @school.esd_el_2014
        @teacher_score_mean = @el.andand.teacher_score_mean
      end
      @staff_state_avg = 3.62

      age_format = lambda { |months|
        if months > 11
          "#{months / 12} years, #{months % 12} months"
        else
          "#{months % 12} months"
        end
      }
      render 'show_ec' and return
    end

    #@profile_fields = School::PROFILE_FIELDS
    ##@profile_fields_flat = @profile_fields.values.collect { |h| h.to_a }.flatten(1)

    #ethnicities = %w(total female male american_indian asian african_american hispanic hawaiian white two_or_more_races)
    #if @school.meap_2013
    #  @demographics = ethnicities.collect do |e|
    #    num = @school.meap_2013.send("#{e}_enrollment").to_s.gsub(/[^0-9]/, '').to_i
    #    num = 0 if num == 9
    #    num == 0 ? nil : [ "#{e.titleize}: #{num} students", num]
    #  end
    #  @demographics.reject! { |a| a.nil? }

    #  @enrollment = %w(kindergarten 1 2 3 4 5 6 7 8 9 10 11 12).collect do |g|
    #    num = @school.meap_2013.send("grade_#{g}_enrollment").to_s.gsub(/[^0-9]/, '').to_i
    #    num = 0 if num == 9
    #    num
    #  end
    #else
    #  @demographics = []
    #  @enrollment = []
    #end
    #@enroll_ticks = %w(K 1 2 3 4 5 6 7 8 9 10 11 12)

    #@sitevisit = {
    #  :overall_rating       => [0, 'Overall Rating', 'average of domain scores'],
    #  :domain_community     => [1, 'Welcoming Community Score', 'welcoming community score - overall_score'],
    #  :visitor_resources    => [2, 'Visitor resources score', 'visitor resources score - domain_community'],
    #  :welcoming_culture    => [2, 'Welcoming culture score', 'welcoming culture score 0- domain_community'],
    #  :domain_environment   => [1, 'Safe and Caring Environment Score', 'safe and caring environment score - overall_score'],
    #  :caring_environment   => [2, 'Caring environment score', 'caring environment score - domain_environment'],
    #  :safe_environment     => [2, 'Safe environment score', 'safe environment score - domain_environment'],
    #  :domain_expectations  => [1, 'High Expectations Score', 'high expectations score - overall_score'],
    #  :academic_displays    => [2, 'Academic displays score', 'academic displays score - domain_expectations'],
    #  :college_promoted     => [2, 'College emphasis score', 'college emphasis score - domain_expectations'],
    #}
    #@sitevisit_values = @school.esd_site_visit_2014.andand.marshal_dump

    #@extra_credit = {}
    #if e = @school.esd
    #  @extra_credit['Overall Student Characteristics Points'] = e.studchrs_pts
    #  if old = (@school.k8? ? @school.esd_k8_2014 : e)
    #    @extra_credit.merge!({
    #      'Socio-economic Status' => "#{(old.econdis_pct.to_f*100).to_i}%",
    #      'Special Education' => "#{(old.sped_pct.to_f*100).to_i}%",
    #      'English Language Learners' => "#{(old.ell_pct.to_f*100).to_i}%",
    #    })
    #  end
    #  if @school.high?
    #    @extra_credit['FAFSA Completion Rate'] = "#{(@school.esd_hs_2014.andand.fafsa_rate.to_f*100).to_i}%"
    #  end
    #end

    #@category_copy = {
    #  'Turnaround' => ['Fresh start school',
    #    "These are schools that Michigan has identified as the lowest achieving five percent of schools in the state.
    #      They are mandated to perform a rapid turnaround to improve. As part of the mandate, the school has a new operator."],
    #  'New' => ['New school',
    #    "This school has been open since 2009 or sooner and as a result of being new, doesn't have the cumulative information
    #    needed for ESD to assign a grade."],
    #  'Specialty' => ['Specialty school',
    #    "A specialty school serves students that have unique learning needs or skills.
    #    Examples can include: adult education and alternative learning programs."]
    #  }

    respond_to do |format|
      format.html do
      end
      #format.pdf { render :layout => false }
    end
  end


  def compare
    str = params[:which] || ''
    if str == 'clear'
      session[:compare] = []
      redirect_to '/compare', :notice => "Thank you, you may now choose new schools to compare." and return
    elsif str.blank?
      list = session[:compare] || []
    elsif m = str.match(/^\+([0-9,]+)$/)
      ids = m[1].split(',').collect { |i| i.to_i }
      list = (session[:compare] || []) + ids
    else
      list = str.split(',')
    end

    # Limit
    list = list.collect { |i| i.to_i }.uniq
    list.shift while list.size > AppConfig.max_compared

    session[:compare] = list

    @schools = School.where(:id => list)
    @grades = @schools.collect { |s| s.grades }

    @transposed = []
    @grades.each_with_index do |g,i|
      s = @schools[i]
      tx = {}

      if s.earlychild?
        tx['Overall Rating']            = s.published_rating
        tx['Address']                   = "#{s.address}<br/>#{s.address2}"
        tx['Total Points']              = s.points_total
        tx['Staff Qualifications']      = s.points_staff
        tx['Family/Community Partnerships'] = s.points_family
        tx['Administration']            = s.points_admin
        tx['Environment Pts']           = s.points_env
        tx['Curriculum']                = s.points_curriculum
        tx['Financial Assistance']      = format_field(s.subsidy)
        tx['Special Needs Experience']  = format_field(s.special)
        tx['Care Setting']              = s.setting
        tx['Environment']               = format_field(s.environment)
        tx['Meals Provided']            = format_field(s.meals)
        tx['Provides Transportation?']  = format_field(s.transportation)

      else
        tx['Overall Grade']     = g[:cumulative][:letter] || 'N/A'
        tx['Academic Status']   = g[:status][:letter]     || 'N/A'
        tx['Academic Progress'] = g[:progress][:letter]   || 'N/A'
        tx['School Climate']    = g[:climate][:letter]    || 'N/A'

        tx['Address']           = "#{s.address}<br/>#{s.address2}"
        tx['Grades Served']     = s.grades_served || 'Unknown'
        tx['Governance']        = s.basic.governance || 'Unknown'
      end

      @transposed[i] = tx
    end


    # Turn an array of hashes to a hash of arrays..
    @chart = {}
    @transposed.each_with_index do |h,i|
      h.each do |label,val|
        @chart[label] ||= []
        @chart[label][i] = val
      end
    end

    # When you go to add others to compare, we want to show only compatible
    # if only preschools
    types = @schools.collect { |s| s.school_type }.uniq.reject { |s| s.nil? }.sort.join('_')
    @filter = {
      'EC'    => 'ec',
      'HS_K8' => 'k8hs',
      'K8'    => 'k8',
      'HS'    => 'hs',
    }[types] || 'all'
  end

  private

  def format_field(val)
    if val.is_a?(Array)
      val.join(", ")
    else
      val == '0' ? 'No' : (val == '1' ? 'Yes' : val)
    end
  end

  def format_phone(ph)
    if ph.length == 10
      "#{ph[0..2]}-#{ph[3..5]}-#{ph[6..-1]}"
    elsif ph.length == 7
      "#{ph[0..2]}-#{ph[3..-1]}"
    else
      ph
    end
  end

end
