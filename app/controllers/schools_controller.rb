class SchoolsController < ApplicationController

  caches_action :index, :if => proc { request.format.json? }, :cache_path => Proc.new { |controller| controller.params.merge({ :v => AppConfig.cache_key }) }
  caches_action :overview, :cache_path => Proc.new { |controller| controller.params.merge({ :v => AppConfig.cache_key }) }

  helper_method :format_phone

  def index
    filter = ['all', 'ec', 'elementary', 'middle', 'high'].include?(params[:filter]) ? params[:filter] : nil
    loc    = params[:loc]
    #session[:filter]  = filter
    #session[:loc]     = params[:loc]
    #session[:complex] = nil

    @complex = nil
    @grade_filter = filter
    @loc = loc

    if params[:complex] and params[:complex] != 'null'
      begin
        @complex = (params[:complex].is_a?(String) and !params[:complex].blank?) ? JSON.parse(params[:complex]) : params[:complex]
      rescue => e
        logger.info e.inspect
        @complex = nil
      end
      logger.ap @complex
      #session[:complex] = @cq
    #else
    #  @cq = session[:complex]
    end

    @title = current_search
    @schools = if @grade_filter.blank? && @loc.blank? && @complex.blank?
      School.ec.where('esd_el_2015 is not null').
        order('points desc').limit(50)
    else
      scope_from_filters(@grade_filter, @loc, @complex)
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
          :center => { :lon => -83.09577941894531, :lat => 42.364885996366525 },
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
    begin
      @school = School.find_by_slug(params[:id]) || School.find(params[:id])
      if !@school.earlychild? and @school.basic.scorecard_display == '0'
        redirect_to next_path(@school.id) and return if params[:from] == '1'
        redirect_to previous_path(@school.id) and return if params[:from] == '-1'
        redirect_to root_path and return
      end
      redirect_to root_path and return if @school.nil?
    rescue
      render :text => '' and return if params[:id] == 'PIE' # PIE.htc requests
      redirect_to root_path and return
    end

    @subtitle = @school.name
    level = @school.type_s
    @subtitle += " - #{level}" if level

    @school_o = Bedrock::Overlay.from_config('schools',
      :ty       => :geojson,
      :elements => [@school])
    @det_o = Bedrock::Overlay.from_config('districts',
      :ty => :geojson,
      :elements => [District.find(580)]
    )
    extent = Bedrock::city_extents(:detroit)
    extent = Bedrock.merge_extents(extent, @school.extent) if @school.geometry

    @tips = Hash[Tip.all.collect { |t| [t.name.to_sym, t] }]

    @map = Bedrock::Map.new({
      :base_layers    => ['street'],
      :layers         => [ @det_o, @school_o ],
      :layer_control  => true,
      :min_zoom       => 10,
      :max_zoom       => 18,
      :zoom           => 10,
      #:extent         => extent,
      :center         => { :lat => @school.centroid.y, :lon => @school.centroid.x },
      :layer_control  => false,
    }) if @school.geometry

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
      @ech = @school.early_child.marshal_dump
      @staff_state_avg = 3.62
      @grades = @school.grades

      age_format = lambda { |months|
        if months > 11
          "#{months / 12} years, #{months % 12} months"
        else
          "#{months % 12} months"
        end
      }

      format_field = lambda { |val|
        val == '0' ? 'No' : (val == '1' ? 'Yes' : val)
      }

      @profile_fields = [
        {
          label: 'Program Specialty',
          value: format_field.call(@school.ec_specialty)
        },
        {
          label: 'Schedule Type',
          value: format_field.call(@school.ec_schedule)
        },
        {
          label: 'Accepts Ages from',
          value: age_format.call(@school.ec_age_from)
        },
        {
          label: 'Accepts Ages to',
          value: age_format.call(@school.ec_age_to)
        },
        {
          label: 'Total Licensed Capacity',
          value: format_field.call(@school.ec_capacity)
        },
        {
          label: 'Program Eligibility Criteria',
          value: format_field.call(@school.ec_eligibility)
        },
        {
          label: 'Financial Assistance',
          value: format_field.call(@school.ec_subsidy)
        },
        {
          label: 'Special Needs Experience',
          value: format_field.call(@school.ec_special)
        },
        {
          label: 'Care Setting',
          value: format_field.call(@school.ec_setting)
        },
        {
          label: 'Environment',
          value: format_field.call(@school.ec_environment)
        },
        {
          label: 'Meals Provided',
          value: format_field.call(@school.ec_meals)
        },
        {
          label: 'Payment Schedule',
          value: format_field.call(@school.ec_pay_schedule)
        },
        {
          label: 'Application / Registration Fee',
          value: sprintf("$%.2f", @school.ec_fee)
        },
        {
          label: 'Provides Transportation?',
          value: format_field.call(@school.ec_transportation)
        },
        {
          label: 'Written Contract',
          value: format_field.call(@school.ec_contract)
        },
        {
          label: 'Additional program information',
          value: format_field.call(@school.ec_additional_info)
        },
        {
          label: 'Age Groups',
          value: format_field.call(@school.ec_age_groups)
        },
        {
          label: 'Enrichment opportunities',
          value: format_field.call(@school.ec_enrichment)
        },
        {
          label: 'Teacher Evaluations',
          value: format_field.call(@school.ec_evaluation)
        },
        {
          label: 'Field trips and other extended programming',
          value: format_field.call(@school.ec_extended)
        },
        {
          label: 'Facilities Available',
          value: format_field.call(@school.ec_facilities)
        },
        {
          label: 'Frequency of feedback provided to parents on child’s progress',
          value: format_field.call(@school.ec_feedback_freq)
        },
        {
          label: 'Type of feedback provided to parents on child\'s progress',
          value: format_field.call(@school.ec_feedback_type)
        },
        {
          label: 'Languages spoken by program staff',
          value: format_field.call(@school.ec_language)
        },
        {
          label: 'Health/Dental/Vision Care',
          value: format_field.call(@school.ec_medical)
        },
        {
          label: 'Access to mental health services',
          value: format_field.call(@school.ec_mental)
        },
        {
          label: 'Partner name - 1',
          value: format_field.call(@school.ec_partner_one)
        },
        {
          label: 'Details of partnership - 1',
          value: format_field.call(@school.ec_partner_one_detail)
        },
        {
          label: 'Partner name - 2',
          value: format_field.call(@school.ec_partner_two)
        },
        {
          label: 'Details of partnership - 2',
          value: format_field.call(@school.ec_partner_two_detail)
        },
        {
          label: 'Partner name - 3',
          value: format_field.call(@school.ec_partner_three)
        },
        {
          label: 'Details of partnership - 3',
          value: format_field.call(@school.ec_partner_three_detail)
        },
        {
          label: 'Playground and/or physical activity space on site',
          value: format_field.call(@school.ec_physical_activity)
        },
        {
          label: 'Family and community support',
          value: format_field.call(@school.ec_support)
        },
        {
          label: 'Actual Enrollment',
          value: format_field.call(@school.ec_actual_enrollment)
        },
        {
          label: 'Licensed Enrollment',
          value: format_field.call(@school.ec_licensed_enrollment)
        },
        {
          label: 'Number of children with special needs',
          value: format_field.call(@school.ec_special_enrollment)
        },
        {
          label: 'Number of children receiving subsidy',
          value: format_field.call(@school.ec_subsidy_enrollment)
        }

      ]

      @legend = {
        'Gold'          => ['Gold', 'Superior Quality Program'],
        'Silver'        => ['Silver', 'High Quality Program'],
        'Bronze'        => ['Bronze', 'Quality Program'],
        'Below Bronze'  => ['Did not medal', 'On the path to medal-level quality'],
        'Not Rated'     => ['Incomplete', 'Not enough information to designate a rating'],
        'None'          => ['No Rating', 'This program did not participate'],
      }
      @legend_sub = @legend.dup
      @legend_sub.delete 'None'
      @legend_sub['Not Rated'] = ['No Rating', 'Not enough information to designate a rating or this program did not participate']

      @staff_average_2015 = [
        {
          :title => 'Program Environment',
          :explanation => 'Program Environment is  the overall feel for all persons, including children, families, and staff, in the program environment. It measures the “it” factor that is often hard to define,  but is necessary for any learning to begin. It measures attributes like an inviting and safe place for children as well as a supportive place for staff to work. It make children, family, and staff feel welcome and respected regardless of differences.',
          :points => @el.andand.physicalenviron_staff_average.to_f
        },
        {
          :title => 'Collaboration',
          :explanation => 'Family and Community Partnerships is the extent to which programs facilitate relationships between families in their program and the community. It includes the extent in which programs invite parents to bring what they know from the community to the program while also building connections to other families and resources in the community.',
          :points => @el.andand.familycommunity_staff_average.to_f,
        },
        {
          :title => 'Cultural Awareness',
          :explanation => 'Cultural and Linguistic Competence is the extent to which a program understands and implements cultural and linguistic practice. This includes programs that provide staff with opportunities to learn more about their own backgrounds, teachers who learn more about practices and materials for parents in their home language.',
          :points => @el.andand.culturallinguistic_staff_average.to_f,
        },
        {
          :title => 'General Culture and Climate',
          :explanation => "General Climate and Culture measures parts of the early learning environment that are supportive, safe, and facilitate children’s learning. It includes caring relationships between educators and children, educators' expectations for children's learning, and to what extent educators believe in children's ability to succeed.",
          :points => @el.andand.cultureclimate_staff_average.to_f
        }
      ]

      @community = {
        :clc_fairaverage => {
          :statement => 'Cultural Awareness',
          :explanation => 'The rating is based on how well teachers showed respect to all children regardless of race, culture and ability.',
          :points => @el.andand.clc_fairaverage.to_f,
        },
        :professionalism_fairaverage => {
          :statement => 'Professionalism',
          :explanation => 'The rating is based on how teachers and staff treated themselves and each other while in the room with children.',
          :points => @el.andand.professionalism_fairaverage.to_f,
        },
        :safety_fairaverage => {
          :statement => 'Program Environment',
          :explanation => 'This rating is based on the conditions of the classroom.',
          :points => @el.andand.safety_fairaverage.to_f,
        },
        :interactions_fairaverage => {
          :statement => 'Relationships & Interactions',
          :explanation => 'The rating is based on how well teachers manage the classroom.',
          :points => @el.andand.interactions_fairaverage.to_f,
        },
        :familycommunity_fairaverage => {
          :statement => 'Collaboration',
          :explanation => 'The rating is based on how the family, community and school work together.',
          :points => @el.andand.familycommunity_fairaverage.to_f,
        },
      }
      @stars = {
        0 => 'Program meets state licensing requirements',
        1 => 'Program meets state licensing requirements and is participating in Great Start to Quality',
        2 => 'Program demonstrates quality across some standards',
        3 => 'Program demonstrates quality across several standards',
        4 => 'Program demonstrates quality across almost all standards',
        5 => 'Program demonstrates highest quality',
      }
      render 'show_ec'
      return
    end

    @grades = @school.grades

    @profile_fields = School::PROFILE_FIELDS
    #@profile_fields_flat = @profile_fields.values.collect { |h| h.to_a }.flatten(1)

    ethnicities = %w(total female male american_indian asian african_american hispanic hawaiian white two_or_more_races)
    if @school.meap_2013
      @demographics = ethnicities.collect do |e|
        num = @school.meap_2013.send("#{e}_enrollment").to_s.gsub(/[^0-9]/, '').to_i
        num = 0 if num == 9
        num == 0 ? nil : [ "#{e.titleize}: #{num} students", num]
      end
      @demographics.reject! { |a| a.nil? }

      @enrollment = %w(kindergarten 1 2 3 4 5 6 7 8 9 10 11 12).collect do |g|
        num = @school.meap_2013.send("grade_#{g}_enrollment").to_s.gsub(/[^0-9]/, '').to_i
        num = 0 if num == 9
        num
      end
    else
      @demographics = []
      @enrollment = []
    end
    @enroll_ticks = %w(K 1 2 3 4 5 6 7 8 9 10 11 12)

    @sitevisit = {
      :overall_rating       => [0, 'Overall Rating', 'average of domain scores'],
      :domain_community     => [1, 'Welcoming Community Score', 'welcoming community score - overall_score'],
      :visitor_resources    => [2, 'Visitor resources score', 'visitor resources score - domain_community'],
      :welcoming_culture    => [2, 'Welcoming culture score', 'welcoming culture score 0- domain_community'],
      :domain_environment   => [1, 'Safe and Caring Environment Score', 'safe and caring environment score - overall_score'],
      :caring_environment   => [2, 'Caring environment score', 'caring environment score - domain_environment'],
      :safe_environment     => [2, 'Safe environment score', 'safe environment score - domain_environment'],
      :domain_expectations  => [1, 'High Expectations Score', 'high expectations score - overall_score'],
      :academic_displays    => [2, 'Academic displays score', 'academic displays score - domain_expectations'],
      :college_promoted     => [2, 'College emphasis score', 'college emphasis score - domain_expectations'],
    }
    @sitevisit_values = @school.esd_site_visit_2014.andand.marshal_dump

    @extra_credit = {}
    if e = @school.esd
      @extra_credit['Overall Student Characteristics Points'] = e.studchrs_pts
      if old = (@school.k8? ? @school.esd_k8_2014 : e)
        @extra_credit.merge!({
          'Socio-economic Status' => "#{(old.econdis_pct.to_f*100).to_i}%",
          'Special Education' => "#{(old.sped_pct.to_f*100).to_i}%",
          'English Language Learners' => "#{(old.ell_pct.to_f*100).to_i}%",
        })
      end
      if @school.high?
        @extra_credit['FAFSA Completion Rate'] = "#{(@school.esd_hs_2014.andand.fafsa_rate.to_f*100).to_i}%"
      end
    end


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
        tx['Overall Rating']            = s.ec_published_rating
        tx['Address']                   = "#{s.address}<br/>#{s.address2}"
        tx['Total Points']              = s.ec_points_total
        tx['Staff Qualifications']      = s.ec_points_staff
        tx['Family/Community Partnerships'] = s.ec_points_family
        tx['Administration']            = s.ec_points_admin
        tx['Environment Pts']           = s.ec_points_env
        tx['Curriculum']                = s.ec_points_curriculum
        tx['Financial Assistance']      = s.ec_subsidy
        tx['Special Needs Experience']  = s.ec_special
        tx['Care Setting']              = s.ec_setting
        tx['Environment']               = s.ec_environment
        tx['Meals Provided']            = s.ec_meals
        tx['Provides Transportation?']  = s.ec_transportation

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

  def increment
    s = scope_from_filters(session[:filter], session[:loc])
    if params[:by] == 1
      if s.is_a? Array
        avail = s.select { |i| i.id > params[:id].to_i }
        s = (avail.empty? ? s : avail).first
      else
        s = s.first(:conditions => ["id > ?", params[:id].to_i]) || s.first
      end
    elsif params[:by] == -1
      if s.is_a? Array
        avail = s.select { |i| i.id < params[:id].to_i }
        s = (avail.empty? ? s : avail).last
      else
        s = s.last(:conditions => ["id < ?", params[:id].to_i]) || s.last
      end
    end
    redirect_to (s.nil? ? schools_path : school_path(s.slug)+"?from=#{params[:by]}")
  end

  # Ajax update the count of schools matching a filter set
  #def overview
  #  filter = ['all', 'elementary', 'middle', 'high'].include?(params[:filter]) ? params[:filter] : nil
  #  type = School::TYPES.keys.include?(params[:type].andand.to_sym) ? params[:type] : nil
  #  session[:filter]  = filter
  #  session[:type]    = type
  #  session[:loc]     = params[:loc]
  #  title = current_search
  #  schools = scope_from_filters(filter, params[:loc])
  #  title = title.gsub('All ', '')
  #  title = title.gsub('Schools', 'School') if schools.count == 1
  #  render :text => "There #{schools.count==1?'is':'are'} #{schools.count} #{title} in Detroit"
  #end

  private

  def format_phone(ph)
    if ph.length == 10
      "#{ph[0..2]}-#{ph[3..5]}-#{ph[6..-1]}"
    elsif ph.length == 7
      "#{ph[0..2]}-#{ph[3..-1]}"
    else
      ph
    end
  end

  def scope_from_filters(filter, loc, complex=nil)
    logger.info "scope from filters: #{filter}, #{loc}"
    logger.ap complex if complex
    schools = (filter.nil? or filter == 'all') ? School : School.send(filter)

    if !complex.blank?
      grades = complex['grades_served']
      schools = schools.send(grades) if grades

      others = complex.reject { |k,v| k == 'grades_served' }
      logger.ap "others: #{others}"
      unless others.empty?
        schools = schools.where('profile is not null')
        others.each do |key, value|
          vals = [value].flatten
          logger.ap "searching profiles where #{key} == #{vals}"
          logger.info "started with #{schools.count} schools"
          keys = key.split(',').collect { |i| i.squish }
          schools = schools.select do |s|
            intersections = keys.collect do |key|
              val = s.profile.send(key)
              logger.info "  check #{s.bcode}: #{key} = #{val.inspect}" if val
              school_vals = (val || '').split(',').collect { |i| i.squish }
              intersection = vals & school_vals
            end.flatten
            !intersections.empty?
          end
          logger.info "now down to #{schools.count}"
        end
      end


    elsif loc.andand.match /^[0-9]{5}$/
      schools = schools.where(:zip => loc)
    elsif !loc.blank?
      loc = loc.gsub("&", " and ")
      geo = Bedrock::Geocoder.bing_geocode({
        :address => loc,
        :city => 'Detroit',
        :state => 'MI',
      })
      if geo
        #f = School.rgeo_factory_for_column :centroid
        miles = AppConfig.radius_mi
        f = RGeo::Geographic.projected_factory(:projection_proj4 => AppConfig.detroit_proj)
        p = f.point(geo[:location][:lon], geo[:location][:lat])
        schools = schools.inside(p.buffer(1609 * miles))
      end
    end
    schools = schools.all if schools.is_a?(Class)
    return schools
  end

end
