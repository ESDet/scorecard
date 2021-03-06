class SchoolsController < ApplicationController
  before_action :set_filters

  def index
    school_ids = params[:school_ids]
    school_ids = school_ids.split(",") if school_ids
    @school_ids = school_ids.uniq[0..3].join(",") if school_ids
    @offset = params[:offset] || 0
    @ecs_offset = params[:ecs_offset] || 0
    @limit = params[:limit] || Rails.env.production? ? 10000 : 50

    @grade = params[:grade]
    @filters = params[:filters] || []

    if @grade.present? && !@grade.in?(["ec", "k8", "hs", "high"])
      redirect_to root_path and return
    end

    @loc = if params[:loc].present?
      CGI.escape params[:loc].strip.gsub("\u{a0}", "")
    end

    special_filters = []
    license_types = []
    case @grade
    when "ec"
      url = "ecs.json?offset=#{@ecs_offset}&flatten_fields=true&limit=#{@limit}" <<
        "&includes=most_recent_ec_state_rating,ec_profile,esd_el_2015" <<
        "&sort_by_special=ec_total_pts" <<
        "&sort_order_special=DESC" <<
        "&filter[field_scorecard_display]=1"

      special_filters << "has_esd_el_2015"
      @filters.each do |f|
        case f
        when "free_reduced"
          special_filters << "ec_profile_is_free_or_reduced_cost"
        when "transportation"
          special_filters << "ec_profile_has_transportation"
        when "special_needs"
          special_filters << "ec_profile_has_special_needs_experience"
        when "meals"
          special_filters << "ec_profile_has_meals"
        when "home_based"
          license_types << 2424
          license_types << 2419
        when "center_based"
          license_types << 2415
        when "high_rating"
          special_filters << "esd_el_highscore"
        end
      end
    when "k8", "hs", "high"
      @grade = "hs" if @grade == "high"

      url = "schools.json?offset=#{@offset}&flatten_fields=true&limit=#{@limit}" <<
        "&includes=school_profile,esd_#{@grade}_2016,esd_#{@grade}_2017" <<
        "&filter[field_scorecard_display]=1"

      if @grade == "k8"
        url << "&filter[field_school_type]=10"
      else
        url << "&filter[field_school_type]=3"
      end

      @filters.each do |f|
        @schools = case f
        when "special_education"
          special_filters << "school_profile_has_specialed"
        when "arts"
          special_filters << "school_profile_has_arts"
        when "sports"
          special_filters << "school_profile_has_sports"
        when "transportation"
          special_filters << "school_profile_has_transportation"
        when "before_after_care"
          special_filters << "school_profile_has_before_after_care"
        when "app_required"
          special_filters << "school_profile_application_required"
        when "college_readiness"
          special_filters << "school_profile_collegereadiness"
        when "high_rating"
          special_filters << "esd_k8hs_2015_highscore"
        end
      end
    else
      schools_url = "schools.json?offset=#{@offset}&limit=#{@limit}" <<
        "&flatten_fields=true" <<
        "&includes=school_profile,esd_k8_2016,esd_k8_2017," <<
        "esd_hs_2016&filter[field_scorecard_display]=1"

      ecs_url = "ecs.json?offset=#{@ecs_offset}&limit=#{@limit}&flatten_fields=true" <<
        "&includes=most_recent_ec_state_rating,ec_profile,esd_el_2015" <<
        "&filter[field_scorecard_display]=1" <<
        "&sort_by_special=ec_total_pts" <<
        "&sort_order_special=DESC"

      if is_zip_search?
        schools_url << zip_search_params
        ecs_url << zip_search_params
      elsif is_address_search?
        schools_url << address_search_params
        ecs_url << address_search_params
      elsif @loc.present?
        schools_url << school_search_params
        ecs_url << school_search_params
      end
    end

    if @grade.present?
      if is_zip_search?
        url << zip_search_params
      elsif is_address_search?
        url << address_search_params
      elsif @loc.present?
        url << school_search_params
      end

      if special_filters.present?
        url << "&filter_special=" << special_filters.join(",")
      end

      if license_types.present?
        url << "&filter[field_ec_license_type]=" <<
          license_types.join(",") <<
          "&filter_op[field_ec_license_type]=IN"
      end
    end

    retries = 2
    begin
      if @grade.present?
        response = Rails.cache.fetch(cache_key(@grade == 'ec' ? 'ec' : 'school')) do
          Portal.new.fetch(url)
        end
        if response != ["request error"] && response["data"]
          @schools = gather_included_fields(response).
            select { |s| !s["field_geo"].nil? }.
            map { |s| SchoolData.new(s) }
        else
          flash[:notice] = "No results found"
          redirect_to root_path and return
        end
      else
        schools_response = Rails.cache.fetch(cache_key('school')) do
          Portal.new.fetch(schools_url)
        end
        if schools_response != ["request error"] && schools_response["data"]
          schools_data = gather_included_fields(schools_response).
            select { |s| !s["field_geo"].nil? }.
            map { |s| SchoolData.new(s) }
        end

        ecs_response = Rails.cache.fetch(cache_key('ec')) do
          Portal.new.fetch(ecs_url)
        end
        if ecs_response != ["request error"] && ecs_response["data"]
          ecs_data = gather_included_fields(ecs_response).
            select { |s| !s["field_geo"].nil? }.
            map { |s| SchoolData.new(s) }
        end
        @schools = schools_data || []
        @schools += ecs_data if ecs_data

        if @schools.blank?
          flash[:notice] = "No results found"
          redirect_to root_path and return
        end
      end

      @schools.sort_by!(&:sort_weight).reverse!

      respond_to do |format|
        format.html
        format.js
      end
    rescue EOFError => e
      ExceptionNotifier.notify_exception(e)
      retries -= 1
      retry if retries > 0
    rescue Net::ReadTimeout, Net::OpenTimeout => e
      ExceptionNotifier.notify_exception(e)
      retries -= 1
      retry if retries > 0
      flash[:notice] = "There was an error during " <<
      "the search and we are looking into the issue " <<
      "now. Please try again later."
      redirect_to root_path and return
    end
  end

  def show
    render :text => "" and return if params[:id] == "PIE" # PIE.htc requests

    redirect_to root_path and return unless params[:id]
    id, school_type = params[:id].split("-")[0..1]
    redirect_to root_path and return unless id.to_i != 0

    if !school_type.in? ["ecs", "k8", "hs", "high"]
      redirect_to root_path and return
    end

    school_type = "hs" if school_type == "high"

    school_data = fetch_school_data(id, school_type)

    if school_type != "ecs"
      timestamp = api_timestamp

      @detroit, @state = Rails.cache.fetch("#{school_type}_detroit_state_data_#{timestamp}") do
        fetch_detroit_and_state_data(school_type)
      end

      @scatter_plot_schools = Rails.cache.fetch("#{school_type}_scatter_plot_schools_#{timestamp}") do
        response = fetch_schools_for_scatter_plot(school_type)
        gather_included_fields(response).map { |s| SchoolData.new s }
      end
    end

    if school_data.first =~ /does not exist/
      (redirect_to root_path and return)
    end

    @school = SchoolData.new school_data["data"].
      merge(included: school_data["included"])

    if @school.ec?
      @school.extend(EarlyChildhood)
      render "show_ec" and return
    else
      @school.extend(School)
      if @school.hs?
        @school.extend(HighSchool)
        @detroit.extend(HighSchool)
        @state.extend(HighSchool)
      end
      if @school.k8?
        @school.extend(K8School)
        @detroit.extend(K8School)
        @state.extend(K8School)
      end
    end

    respond_to do |format|
      format.html
      format.pdf do
        render pdf: @school.display_name,
          template: 'schools/show.pdf.haml',
          disposition: params.fetch(:disposition) { 'attachment' },
          show_as_html: (params.fetch(:debug) { "false" }) == "true",
          footer: {
            html: {
              template: 'schools/pdf_footer.html.haml'
            }
          },
          margin: { bottom: 30 }
      end
    end
  end

  def compare
    redirect_to root_path and return unless params[:school_ids]

    @schools = params[:school_ids].split(",").map do |i|
      id, school_type = i.split("-")[0..1]
      school_data = fetch_school_data(id, school_type)
      school = SchoolData.new school_data["data"].
        merge(included: school_data["included"])
      if school_type == "ecs"
        school.extend(EarlyChildhood)
      else
        school.extend(School)
        school.extend(HighSchool) if school.hs?
        school.extend(K8School) if school.k8?
      end
      school
    end
  end

  private

  def is_zip_search?
    @loc.andand.match /\A\d{5}\Z/
  end

  def is_address_search?
    @loc.andand.match /\A\d+.+\Z/
  end

  def zip_search_params
    "&filter[field_address:postal_code]=#{@loc}"
  end

  def address_search_params
    response = HTTParty.get "https://api.mapbox.com/geocoding/v5/mapbox.places/#{@loc}+Detroit+MI.json?access_token=#{ENV['MAPBOX_ACCESS_TOKEN']}"
    data = JSON.parse response
    if data['features'].present?
      lat_lon = data['features'].first['geometry']['coordinates'].reverse.join(',')
      "&near_latlon=#{lat_lon}&near_miles=2"
    end
  end

  def school_search_params
    "&filter[name]=%25#{@loc}%25&filter_op[name]=LIKE"
  end


  def api_timestamp
    if Rails.env.production?
      Portal.new.fetch("most_recent_school_timestamp.json")["most_recent_school_timestamp"]
    end
  end

  def cache_key(cache_type)
    key = "index/#{@grade || 'all'}/#{cache_type}/#{api_timestamp}"
    if @loc.present?
      key << "/#{@loc.gsub(/\s/, '_')}"
    end
    if @filters.present?
      @filters.sort.each { |f| key << "/#{f}" }
    end
    key
  end

  def fetch_school_data(id, school_type)
    if school_type == "ecs"
      url = "ecs"
      includes = "ec_profile,esd_el_2015," <<
        "most_recent_ec_state_rating"
    else
      url = "schools"
      includes = "school_profile,count_2016," <<
        "count_2017," <<
        "fiveessentials_2016," <<
        "esd_#{school_type}_2016," <<
        "esd_#{school_type}_2017," <<
        "k12_supplemental_2017"
    end

    url << "/#{id}.json?flatten_fields=true&includes=#{includes}"

    if school_type != "ecs"
      url << "&include_option_labels=true"
    end

    retries = 2
    begin
      school_data = Portal.new.fetch(url)
    rescue EOFError => e
      ExceptionNotifier.notify_exception(e)
      retries -= 1
      retry if retries > 0
      flash[:notice] = "There was an error " <<
        "retrieving school data and we are looking " <<
        "into the issue now. Please try again later."
      redirect_to root_path and return
    rescue Net::ReadTimeout, Net::OpenTimeout => e
      ExceptionNotifier.notify_exception(e)
      retries -= 1
      retry if retries > 0
      flash[:notice] = "There was an error " <<
        "retrieving school data and we are looking " <<
        "into the issue now. Please try again later."
      redirect_to root_path and return
    end
    school_data
  end

  def fetch_detroit_and_state_data(school_type)
    url = "schools.json?flatten_fields=true" <<
      "&include_option_labels=true" <<
      "&includes=school_profile,esd_#{school_type}_2016,esd_#{school_type}_2017" <<
      "&filter[field_bcode]=88888,99999" <<
      "&filter_op[field_bcode]=IN"

    retries = 2
    begin
      response = Portal.new.fetch(url)
    rescue EOFError => e
      ExceptionNotifier.notify_exception(e)
      retries -= 1
      retry if retries > 0
    rescue Net::ReadTimeout, Net::OpenTimeout => e
      flash[:notice] = "There was an error " <<
        "retrieving school data and we are looking " <<
        "into the issue now. Please try again later."
      ExceptionNotifier.notify_exception(e)
      retries -= 1
      retry if retries > 0
      redirect_to root_path and return
    end

    detroit_data, state_data = nil
    if response != ["request error"] && response["data"]
      response["data"].each do |s|
        if s["field_bcode"] == "88888"
          includes = response["included"].
            select { |i| i["id"] == "88888" }
          detroit_data = SchoolData.new s.merge(included: includes)
        elsif s["field_bcode"] == "99999"
          includes = response["included"].
            select { |i| i["id"] == "99999" }
          state_data = SchoolData.new s.merge(included: includes)
        end
      end
    end
    [detroit_data, state_data]
  end

  def fetch_schools_for_scatter_plot(school_type)
    fetch_limit = Rails.env.production? ? 500 : 10
    url = "schools.json?flatten_fields=true&limit=#{fetch_limit}&" <<
      "includes=esd_#{school_type}_2016,esd_#{school_type}_2017"
    retries = 2
    begin
      school_data = Portal.new.fetch(url)
    rescue EOFError => e
      ExceptionNotifier.notify_exception(e)
      retries -= 1
      retry if retries > 0
      flash[:notice] = "There was an error " <<
        "retrieving school data and we are looking " <<
        "into the issue now. Please try again later."
      redirect_to root_path and return
    rescue Net::ReadTimeout, Net::OpenTimeout => e
      ExceptionNotifier.notify_exception(e)
      retries -= 1
      retry if retries > 0
      flash[:notice] = "There was an error " <<
        "retrieving school data and we are looking " <<
        "into the issue now. Please try again later."
      redirect_to root_path and return
    end
    school_data
  end

  def gather_included_fields(response)
    response["data"].map do |s|
      includes = response["included"].select do |i|
        valid_includes?(i, s)
      end
      s.merge(included: includes)
    end
  end

  def valid_includes?(includes, school)
    valid_include?(includes, school, "school_profile") ||
    valid_include?(includes, school, "ec_profile") ||
    valid_include?(includes, school, "ec_state_rating", "most_recent_ec_state_rating") ||
    valid_include?(includes, school, "esd_k8_2016") ||
    valid_include?(includes, school, "esd_k8_2017") ||
    valid_include?(includes, school, "esd_hs_2016") ||
    valid_include?(includes, school, "esd_el_2016") ||
    valid_include?(includes, school, "k12_supplemental_2017")
  end

  def valid_include?(includes, school, include_key, secondary_include_key = nil)
    include_link = if secondary_include_key.present?
      secondary_include_key
    else
      include_key
    end
    includes["type"] == "#{include_key}s" &&
    school.try(:[], "links").try(:[], include_link).present? &&
    includes["id"] == school["links"][include_link]["linkage"]["id"]
  end

  def set_filters
    @school_type_filters = [
      { name: 'All', id: 0 },
      { name: 'Early Childhood', id: 'ecs' },
      { name: 'K8 and HS', id: 'k8-hs' },
    ]

    @grade_filters = []
    if params[:grade] == 'k8'
      @grade_filters << { name: 'Elementary (K-5)', id: 'K,1,2,3,4,5', type: 'checkbox' }
      @grade_filters << { name: 'Middle (6-8)', id: '6,7,8', type: 'checkbox' }
    else
      @grade_filters << { name: 'Elementary (K-5)', id: 'K,1,2,3,4,5', type: 'checkbox' }
      @grade_filters << { name: 'Middle (6-8)', id: '6,7,8', type: 'checkbox' }
      @grade_filters << { name: 'High (9-12)', id: '9,10,11,12', type: 'checkbox' }
    end

    @age_group_filters = [
      { name: 'Infant', id: 'Infant', type: 'checkbox' },
      { name: 'Toddler', id: 'Toddler', type: 'checkbox' },
      { name: 'Preschool', id: 'Preschool', type: 'checkbox' },
      { name: 'School-age', id: 'School-age', type: 'checkbox' }
    ]

    @special_ed_filters = [
      { name: 'Autism', id: 'autism', type: 'checkbox' },
      { name: 'Cognitive Disability', id: 'cognitive', type: 'checkbox' },
      { name: 'Visual Impairments', id: 'blindness', type: 'checkbox' },
      { name: 'Emotional Behavioral Disabilities', id: 'emotional', type: 'checkbox' },
      { name: 'Hearing Impairments', id: 'deafness', type: 'checkbox' },
      { name: 'Orthopedic Impairments', id: 'orthopedic', type: 'checkbox' },
      { name: 'Significant Developmental Delay', id: 'developmental_delay', type: 'checkbox' },
      { name: 'Specific Learning Disabilities', id: 'ld', type: 'checkbox' },
      { name: 'Speech and Language Impairments', id: 'speech', type: 'checkbox' },
      { name: 'Multiple Disabilities', id: 'multiple', type: 'checkbox' },
      { name: 'Other Health Impairments', id: 'other', type: 'checkbox' }
    ]

    @ec_special_filters = [
      { name: 'ADD/ADHD', id: 5123, type: 'checkbox' },
      { name: 'Allergies', id: 5124, type: 'checkbox' },
      { name: 'Asthma', id: 5125, type: 'checkbox' },
      { name: 'Cerebral Palsy', id: 5138, type: 'checkbox' },
      { name: 'Cognitively Impaired', id: 5127, type: 'checkbox' },
      { name: 'Cystic Fibrosis', id: 5142, type: 'checkbox' },
      { name: 'Developmental Delay', id: 5134, type: 'checkbox' },
      { name: 'Down Syndrome', id: 5135, type: 'checkbox' },
      { name: 'Emotionally Impaired', id: 5129, type: 'checkbox' },
      { name: 'Epilepsy', id: 5143, type: 'checkbox' },
      { name: 'Feeding Tube', id: 5130, type: 'checkbox' },
      { name: 'Hearing Impaired', id: 5131, type: 'checkbox' },
      { name: 'Learning Disability', id: 5132, type: 'checkbox' },
      { name: 'Physical Impairment', id: 5144, type: 'checkbox' },
      { name: 'Seizure Disorder', id: 5139, type: 'checkbox' },
      { name: 'Speech Impairment', id: 5133, type: 'checkbox' },
      { name: 'Spina Bifida', id: 5152, type: 'checkbox' },
      { name: 'Visually Impaired', id: 5149, type: 'checkbox' }
    ]

    @ec_specialty_filters = [
      { name: 'Early Head Start', id: 5158, type: 'checkbox' },
      { name: 'Head Start', id: 5155, type: 'checkbox' },
      { name: 'Great Start Readiness Program', id: 5154, type: 'checkbox' },
      { name: 'Preschool', id: 5153, type: 'checkbox' },
      { name: 'Faith-based', id: 5157, type: 'checkbox' },
      { name: 'Montessori', id: 5257, type: 'checkbox' },
      { name: 'Reggio Inspired', id: 5156, type: 'checkbox' }
    ]

    @governance_filters = [
      { name: 'All', id: 0 },
      { name: 'Charter', id: "904,906,1974" },
      { name: 'DPS', id: 905 },
      { name: 'EAA', id: 908 },
      { name: 'Independent', id: 914 }
    ]

    @operator_filters = [
      { name: 'All', id: 0 },
      { name: 'C.S. Partners', id: 1286 },
      { name: 'Cornerstone Charter Schools', id: 1090 },
      { name: 'Detroit 90/90', id: 1172 },
      { name: 'Education Management and Networks', id: 1041 },
      { name: 'Equity Education Management Solutions', id: 1017 },
      { name: 'Global Educational Excellence', id: 974 },
      { name: 'Leona Group', id: 956 },
      { name: 'National Heritage Academies', id: 1013 },
      { name: 'New Paradigm for Education', id: 1123 }
    ]
  end
end
