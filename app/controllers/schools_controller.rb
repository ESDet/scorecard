class SchoolsController < ApplicationController

  #caches_action :index, :if => proc { request.format.json? }, :cache_path => Proc.new { |controller| controller.params.merge({ :v => AppConfig.cache_key }) }
  caches_action :overview, :cache_path => Proc.new { |controller| controller.params.merge({ :v => AppConfig.cache_key }) }
  
  helper_method :format_phone
  
  def index
    filter = ['all', 'ec', 'elementary', 'middle', 'high'].include?(params[:filter]) ? params[:filter] : nil
    session[:filter]  = filter
    session[:loc]     = params[:loc]
    session[:complex] = nil
    
    if params[:complex] and params[:complex] != 'null'
      @cq = params[:complex].is_a?(String) ? JSON.parse(params[:complex]) : params[:complex]
      #session[:complex] = @cq
    #else
    #  @cq = session[:complex]
    end
    
    @title = current_search    
    @schools = scope_from_filters(filter, params[:loc], @cq)
    @schools.sort! { |a,b| b.points.to_i <=> a.points.to_i }

    respond_to do |format|
      format.html do
        @school_o = Bedrock::Overlay.from_config('schools',
          :ty         => :geojson,
          :url        => schools_path(:format => :json, :filter => session[:filter], :loc => session[:loc], :type => session[:type]),
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
    @school_o = Bedrock::Overlay.from_config('schools',
      :ty       => :geojson,
      :elements => [@school])
    @det_o = Bedrock::Overlay.from_config('districts',
      :ty => :geojson,
      :elements => [District.find(580)]
    )
    extent = Bedrock::city_extents(:detroit)
    extent = Bedrock.merge_extents(extent, @school.extent)

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
    })
    
    if @school.earlychild?
      @ec = @school.earlychild
      @el = @school.esd_el_2014
      @ech = @ec.marshal_dump
      @staff_state_avg = 3.62
      @grades = @school.grades
      @profile_fields = {
        #:gscmessage     => 'Message to Families',
        :gscspecialty   => 'Program Specialty',
        :gscschedule    => 'Schedule Type',
        :agefrom        => 'Accepts Ages from',
        :ageto          => 'Accepts Ages to',
        :gsccapacity    => 'Total Licensed Capacity',        
        :gsceligibility => 'Program Eligibility Criteria',
        :gscsubsidy     => 'Financial Assistance',
        :gscspecial     => 'Special Needs Experience',
        :gscsetting     => 'Care Setting',
        :environment    => 'Environment',
        :meals          => 'Meals Provided',
        :gscpayschedule => 'Payment Schedule',
        :gscfee         => 'Application / Registration Fee',
        :transportation => 'Provides Transportation?',
        :gsccontract    => 'Written Contract',
      }
      
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
      
      @community = {
        :clc_fairaverage => {
          :statement => 'This program does a good job of teaching children about different cultures.',
          :explanation => 'The rating is based on how well teachers showed respect to all children regardless of race, culture and ability.',
          :points => @el.andand.clc_fairaverage.to_f,
        },
        :professionalism_fairaverage => {
          :statement => 'The staff is professional.',
          :explanation => 'The rating is based on how teachers and staff treated themselves and each other while in the room with children.',
          :points => @el.andand.professionalism_fairaverage.to_f,
        },
        :safety_fairaverage => {
          :statement => 'The classroom is safe, clean and organized.',
          :explanation => 'This rating is based on the conditions of the classroom.',
          :points => @el.andand.safety_fairaverage.to_f,
        },
        :interactions_fairaverage => {
          :statement => 'The teachers respect and support children and other adults.',
          :explanation => 'The rating is based on how well teachers manage the classroom.',
          :points => @el.andand.interactions_fairaverage.to_f,
        },
        :familycommunity_fairaverage => {
          :statement => 'This program builds family and community partnerships.',
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

    ethnicities = %w(american_indian asian african_american hispanic hawaiian white two_or_more_races)
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
        eg = s.earlychild
        tx['Overall Rating']            = eg.publishedrating
        tx['Address']                   = "#{s.address}<br/>#{s.address2}"
        tx['Total Points']              = eg.gscpts
        tx['Staff Qualifications']      = eg.gscptsstaff
        tx['Family/Community Partnerships'] = eg.gscptsfamily
        tx['Administration']            = eg.gscptsadmin
        tx['Environment Pts']           = eg.gscptsenv
        tx['Curriculum']                = eg.gscptscurr
        tx['Financial Assistance']      = eg.gscsubsidy
        tx['Special Needs Experience']  = eg.gscspecial
        tx['Care Setting']              = eg.gscsetting
        tx['Environment']               = eg.environment
        tx['Meals Provided']            = eg.meals
        tx['Provides Transportation?']  = eg.transportation
        
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
  def overview
    filter = ['all', 'elementary', 'middle', 'high'].include?(params[:filter]) ? params[:filter] : nil
    type = School::TYPES.keys.include?(params[:type].andand.to_sym) ? params[:type] : nil
    session[:filter]  = filter
    session[:type]    = type
    session[:loc]     = params[:loc]
    title = current_search    
    schools = scope_from_filters(filter, params[:loc])
    title = title.gsub('All ', '')
    title = title.gsub('Schools', 'School') if schools.count == 1
    render :text => "There #{schools.count==1?'is':'are'} #{schools.count} #{title} in Detroit"
  end
  
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
    
    if complex
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
          if key.is_a?(String)
            schools = schools.select do |s|
              logger.info "  check #{s.bcode}: #{s.profile[key].inspect}" if s.profile[key]
              school_vals = (s.profile[key] || '').split(',').collect { |i| i.squish }
              intersection = vals & school_vals
              !intersection.empty?
            end
            logger.info "now down to #{schools.count}"
          
          elsif key.is_a?(Array)
            # Loopy over key and OR them together...
            
          end
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
