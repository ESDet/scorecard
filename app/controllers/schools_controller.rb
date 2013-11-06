class SchoolsController < ApplicationController

  caches_action :index, :if => proc { request.format.json? }, :cache_path => Proc.new { |controller| controller.params.merge({ :v => AppConfig.cache_key }) }
  caches_action :overview, :cache_path => Proc.new { |controller| controller.params.merge({ :v => AppConfig.cache_key }) }
  
  helper_method :format_phone
  
  def index
    filter = ['all', 'k8', 'high', 'ec'].include?(params[:filter]) ? params[:filter] : nil
    type = School::TYPES.keys.include?(params[:type].andand.to_sym) ? params[:type] : nil
    session[:filter]  = filter
    session[:type]    = type
    session[:loc]     = params[:loc]
    
    @title = current_search    
    @schools = scope_from_filters(filter, type, params[:loc])
    @schools.sort! { |a,b| b.points.to_i <=> a.points.to_i }
    #@schools = @schools.all if @schools.is_a?(Class)
    #@schools = @schools.sort { |a,b| b.points.to_i <=> a.points.to_i }

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
            '#bbffbb' => 'Preschools',
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
      @ech = @ec.marshal_dump
      @grades = @school.grades
      @profile_fields = {
        :gscmessage => 'Message to Families',
        :gscspecialty => 'Program Specialty',
        :gscschedule => 'Schedule Type',
        :agefrom => 'Accepts Ages from',
        :ageto => 'Accepts Ages to',
        :gsccapacity => 'Total Licensed Capacity',        
        :gsceligibility => 'Program Eligibility Criteria',
        :gscsubsidy => 'Financial Assistance',
        :gscspecial => 'Special Needs Experience',
        :gscsetting => 'Care Setting',
        :environment => 'Environment',
        :meals => 'Meals Provided',
        :gscpayschedule => 'Payment Schedule',
        :gscfee => 'Application / Registration Fee',
        :transportation => 'Provides Transportation?',
        :gsccontract => 'Written Contract',
      }
      render 'show_ec', layout: 'noside'
      return
    end
    
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
      [ "#{e.titleize}: #{num} students", num]
    end
    
    @enrollment = %w(kindergarten 1 2 3 4 5 6 7 8 9 10 11 12).collect do |g|
      num = @school.meap_2012.send("grade_#{g}_enrollment").to_s.gsub(/[^0-9]/, '').to_i
      num = 0 if num == 9
      num
    end
    @enroll_ticks = %w(K 1 2 3 4 5 6 7 8 9 10 11 12)
    

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
        render layout: 'noside'
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
      list = session[:compare]
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

        
    @schools = School.find(list)
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
        tx['Overall Grade']     = g[:cumulative][:letter] || 'NG'
        tx['Academic Status']   = g[:status][:letter]     || 'NG'
        tx['Academic Progress'] = g[:progress][:letter]   || 'NG'
        tx['School Climate']    = g[:climate][:letter]    || 'NG'
        
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
    
    render layout: 'noside'
  end
  
  def increment
    s = scope_from_filters(session[:filter], session[:type], session[:loc])
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
    schools = scope_from_filters(filter, type, params[:loc])
    title = title.gsub('All ', '')
    title = title.gsub('Schools', 'School') if schools.count == 1
    render :text => "There #{schools.count==1?'is':'are'} #{schools.count} #{title} in Detroit"
  end
  
  private
  
  def format_phone(ph)
    if ph.length == 10
      "#{ph[0..2]}-#{ph[2..4]}-#{ph[4..-1]}"
    elsif ph.length == 7
      "#{ph[0..2]}-#{ph[2..-1]}"
    else
      ph
    end
  end
  
  def scope_from_filters(filter, type, loc)
    logger.info "scope from filters: #{filter}, #{type}, #{loc}"
    schools = (filter.nil? or filter == 'all') ? School : School.send(filter)
    #schools = schools.send(type) if type
    if loc.andand.match /^[0-9]{5}$/
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
        env = p.buffer(1609 * miles).envelope
        schools = schools.inside(Bedrock::extent(env))
      end
    end
    schools = schools.all if schools.is_a?(Class)
    return schools
  end
  
end
