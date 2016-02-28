class SchoolsController < ApplicationController
  before_action :set_filters

  def index
    school_ids = params[:school_ids]
    school_ids = school_ids.split(",") if school_ids
    @school_ids = school_ids.uniq[0..3].join(",") if school_ids

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
      url = "ecs.json?limit=50&flatten_fields=true" <<
        "&includes=most_recent_ec_state_rating,ec_profile,esd_el_2015" <<
        "&sort_by_special=ec_state_ratings.total_points" <<
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

      url = "schools.json?limit=50&flatten_fields=true" <<
        "&includes=school_profile,esd_#{@grade}_2015" <<
        "&sort_by_special=school_combined_total_pts" <<
        "&sort_order_special=DESC" <<
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
      schools_url = "schools.json?limit=25" <<
        "&flatten_fields=true" <<
        "&includes=school_profile,esd_k8_2015," <<
        "esd_hs_2015&filter[field_scorecard_display]=1" <<
        "&sort_by_special=school_combined_total_pts" <<
        "&sort_order_special=DESC"

      ecs_url = "ecs.json?limit=25&flatten_fields=true" <<
        "&includes=most_recent_ec_state_rating,ec_profile,esd_el_2015" <<
        "&filter[field_scorecard_display]=1" <<
        "&sort_by_special=ec_state_ratings.total_points" <<
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
        response = Portal.new.fetch(url)
        if response != ["request error"] && response["data"]
          @schools = gather_included_fields(response).
            map { |s| SchoolData.new(s) }
        else
          flash[:notice] = "No results found"
          redirect_to root_path
        end
      else
        schools_response = Portal.new.fetch(schools_url)
        if schools_response != ["request error"] && schools_response["data"]
          schools_data = gather_included_fields(schools_response).
            select { |s| !s["field_geo"].nil? }.
            map { |s| SchoolData.new(s) }
        end

        ecs_response = Portal.new.fetch(ecs_url)
        if ecs_response != ["request error"] && ecs_response["data"]
          ecs_data = gather_included_fields(ecs_response).
            select { |s| !s["field_geo"].nil? }.
            map do |s|
              school = SchoolData.new(s)
              pts = if school.ec_state_ratings
                pts = school.ec_state_ratings.total_points.to_f
                school.ec_state_ratings.total_points = pts * (100 / 15.0)
              else
                def school.ec_state_ratings
                  o = Object.new
                  def o.total_points; 0 end
                  def o.overall_rating; 'Incomplete' end
                  o
                end
              end
              school
            end
        end
        @schools = schools_data || []
        @schools += ecs_data if ecs_data
        if @schools.present?
          @schools.sort_by! do |s|
            if s.ec?
              s.ec_state_ratings.total_points.to_f
            elsif s.k8?
              if s.esd_k8_2015s.total_pts.to_f < 1
                s.esd_k8_2015s.total_pts.to_f * 100
              else
                s.esd_k8_2015s.total_pts.to_f
              end
            else
              s.esd_hs_2015s.total_pts.to_f
            end
          end.reverse!
        else
          flash[:notice] = "No results found"
          redirect_to root_path
        end
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
      @detroit, @state = fetch_detroit_and_state_data(school_type)
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
    lat_lon = Portal.new.fetch("geocoder/google.json?data=#{@loc}+Detroit+MI")['coordinates'].reverse.join(",")
    "&near_latlon=#{lat_lon}&near_miles=1"
  end

  def school_search_params
    "&filter[name]=%25#{@loc}%25&filter_op[name]=LIKE"
  end

  def fetch_school_data(id, school_type)
    if school_type == "ecs"
      url = "ecs"
      includes = "ec_profile,esd_el_2015," <<
        "most_recent_ec_state_rating"
    else
      url = "schools"
      includes = "school_profile,meap_2014," <<
        "fiveessentials_2015,esd_#{school_type}_2015," <<
        "k12_supplemental_2015"
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
      "&includes=school_profile,esd_#{school_type}_2015" <<
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

  def gather_included_fields(response)
    response["data"].map do |s|
      includes = response["included"].select do |i|
        valid_includes?(i, s)
      end
      s.merge(included: includes)
    end
  end

  def valid_includes?(includes, school)
    if includes["type"] == "school_profiles"
      if school["links"]["school_profile"]
        includes["id"] == school["links"]["school_profile"]["linkage"]["id"]
      end
    elsif includes["type"] == "ec_profiles"
      if school["links"]["ec_profile"]
        includes["id"] == school["links"]["ec_profile"]["linkage"]["id"]
      end
    elsif includes["type"] == "ec_state_ratings"
      if school["links"]["most_recent_ec_state_rating"]
        if school["links"]["most_recent_ec_state_rating"].present?
          includes["id"] == school["links"]["most_recent_ec_state_rating"]["linkage"]["id"]
        end
      end
    elsif includes["type"] == "esd_k8_2015s"
      if school["links"]["esd_k8_2015"]
        includes["id"] == school["links"]["esd_k8_2015"]["linkage"]["id"]
      end
    elsif includes["type"] == "esd_hs_2015s"
      if school["links"]["esd_hs_2015"]
        includes["id"] == school["links"]["esd_hs_2015"]["linkage"]["id"]
      end
    elsif includes["type"] == "esd_el_2015s"
      if school["links"]["esd_el_2015"]
        includes["id"] == school["links"]["esd_el_2015"]["linkage"]["id"]
      end
    elsif includes["type"] == "k12_supplemental_2015s"
      if school["links"]["k12_supplemental_2015"]
        includes["id"] == school["links"]["k12_supplemental_2015"]["linkage"]["id"]
      end
    end
  end

  def set_filters
    @school_type_filters = [
      { name: 'All', id: 0 },
      { name: 'Early Childhood', id: 'ecs' },
      { name: 'K8 and HS', id: 'k8-hs' },
    ]

    @grade_filters = [
      { name: 'All', id: 0, type: 'checkbox' },
      { name: 'Elementary (K-5)', id: 'K,1,2,3,4,5', type: 'checkbox' },
      { name: 'Middle (6-8)', id: '6,7,8', type: 'checkbox' },
      { name: 'High (9-12)', id: '9,10,11,12', type: 'checkbox' }
    ]

    @age_group_filters = [
      { name: 'All', id: 0, type: 'checkbox'},
      { name: 'Infant', id: 'Infant', type: 'checkbox' },
      { name: 'Toddler', id: 'Toddler', type: 'checkbox' },
      { name: 'Preschool', id: 'Preschool', type: 'checkbox' },
      { name: 'School-age', id: 'School-age', type: 'checkbox' }
    ]

    #@special_ed_filters = [
    #  { name: 'Autism', id: 0},
    #  { name: 'Visual Impairments', id: 0},
    #  { name: 'Hearing Impairments', id: 0},
    #  { name: 'Emotional Behavioral Disabilities', id: 0},
    #  { name: 'Speech and Language Impairments', id: 0},
    #  { name: 'Specific Learning Disabilities', id: 0},
    #  { name: 'Significant Developmental Delay', id: 0},
    #  { name: 'Orthopedic Impairments', id: 0},
    #  { name: 'Multiple Disabilities', id: 0},
    #  { name: 'Cognitive Disability', id: 0},
    #  { name: 'Other Health Impairments', id: 0}
    #]

    #@transportation_filters = [
    #]

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
