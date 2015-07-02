class SchoolsController < ApplicationController
  helper_method :format_phone

  def index
    @loc = params[:loc]
    @grade = params[:grade]
    @filters = params[:filters] || []

    special_filters = []
    license_types = []
    case @grade
    when "ec"
      url = "ecs.json?limit=50&flatten_fields=true" <<
        "&includes=ec_profile,esd_el_2015" <<
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
          special_filters << "esd_el_2015_highscore"
        end
      end
    when "k8", "hs"
      url = "schools.json?limit=50&flatten_fields=true&" <<
        "&sort_by_special=school_combined_total_pts" <<
        "&sort_order_special=DESC" <<
        "&filter[field_scorecard_display]=1" <<
        "&includes=school_profile,esd_#{@grade}_2015"

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
        "&flatten_fields=true&" <<
        "includes=school_profile,esd_k8_2015," <<
        "esd_hs_2015&filter[field_scorecard_display]=1" <<
        "&sort_by_special=school_combined_total_pts" <<
        "&sort_order_special=DESC"

      ecs_url = "ecs.json?limit=25&flatten_fields=true" <<
        "&includes=ec_profile,esd_el_2015" <<
        "&filter[field_scorecard_display]=1" <<
        "&sort_by_special=ec_total_pts" <<
        "&sort_order_special=DESC"

      if @loc.andand.match /^[0-9]{5}$/
        schools_url << "&filter[field_address:postal_code]=#{@loc}"
        ecs_url << "&filter[field_address:postal_code]=#{@loc}"
      elsif @loc.present?
        schools_url << "&filter[name]=%25#{@loc}%25&filter_op[name]=LIKE"
        ecs_url << "&filter[name]=%25#{@loc}%25&filter_op[name]=LIKE"
      end
    end

    if @grade.present?
      if @loc.andand.match /^[0-9]{5}$/
        url << "&filter[field_address:postal_code]=#{@loc}"
      elsif @loc.present?
        url << "&filter[name]=%25#{@loc}%25&filter_op[name]=LIKE"
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
            select { |s| !s['field_geo'].nil? }.
            map { |s| SchoolData.new(s) }
        else
          flash[:notice] = "No results found"
          redirect_to root_path
        end
      else
        schools_response = Portal.new.fetch(schools_url)
        if schools_response != ["request error"] && schools_response["data"]
          @schools = gather_included_fields(schools_response).
            select { |s| !s['field_geo'].nil? }.
            map { |s| SchoolData.new(s) }
        end
        ecs_response = Portal.new.fetch(ecs_url)
        if ecs_response != ["request error"] && ecs_response["data"]
          @schools += gather_included_fields(ecs_response).
            select { |s| !s['field_geo'].nil? }.
            map do |s|
              school = SchoolData.new(s)
              pts = school.esd_el_2015s.total_points.to_f
              school.esd_el_2015s.total_points = pts * (100 / 15.0)
              school
            end
        end
        if @schools
          @schools.sort_by! do |s|
            if s.earlychild?
              s.esd_el_2015s.total_points.to_f
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
    rescue Net::ReadTimeout => e
      flash[:notice] = "There was an error during " <<
      "the search and we are looking into the issue " <<
      "now. Please try again later."
      ExceptionNotifier.notify_exception(e)
      redirect_to root_path and return
    end
  end

  def show
    render :text => "" and return if params[:id] == "PIE" # PIE.htc requests

    redirect_to root_path and return unless params[:id]

    id, school_type = params[:id].split("-")[0..1]

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
    rescue EOFError
      ExceptionNotifier.notify_exception(e)
      retries -= 1
      retry if retries > 0
    rescue Net::ReadTimeout => e
      flash[:notice] = "There was an error " <<
        "retrieving school data and we are looking " <<
        "into the issue now. Please try again later."
      ExceptionNotifier.notify_exception(e)
      redirect_to root_path and return
    end

    if school_type != "ecs"
      url = "schools.json?flatten_fields=true" <<
        "&include_option_labels=true" <<
        "&includes=school_profile,esd_#{school_type}_2015" <<
        "&filter[field_bcode]=88888,99999" <<
        "&filter_op[field_bcode]=IN"
      response = Portal.new.fetch(url)
      detroit_and_state = response["data"].each do |s|
        if s["field_bcode"] == "88888"
          includes = response["included"].
            select { |i| i["id"] == "88888" }
          @detroit = SchoolData.new s.merge(included: includes)
        elsif s["field_bcode"] == "99999"
          includes = response["included"].
            select { |i| i["id"] == "99999" }
          @state = SchoolData.new s.merge(included: includes)
        end
      end
    end

    (redirect_to root_path and return) if school_data.first =~ /does not exist/

    @school = SchoolData.new school_data["data"].merge(included: school_data["included"])

    if @school.earlychild?
      @school.extend(EarlyChildhood)
      render "show_ec" and return
    else
      @school.extend(School)
      if @school.high?
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
  end


  def compare
    str = params[:which] || ""
    if str == "clear"
      session[:compare] = []
      redirect_to "/compare", :notice => "Thank you, you may now choose new schools to compare." and return
    elsif str.blank?
      list = session[:compare] || []
    elsif m = str.match(/^\+([0-9,]+)$/)
      ids = m[1].split(",").collect { |i| i.to_i }
      list = (session[:compare] || []) + ids
    else
      list = str.split(",")
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
        tx["Overall Rating"]            = s.published_rating
        tx["Address"]                   = "#{s.address}<br/>#{s.address2}"
        tx["Total Points"]              = s.points_total
        tx["Staff Qualifications"]      = s.points_staff
        tx["Family/Community Partnerships"] = s.points_family
        tx["Administration"]            = s.points_admin
        tx["Environment Pts"]           = s.points_env
        tx["Curriculum"]                = s.points_curriculum
        tx["Financial Assistance"]      = format_field(s.subsidy)
        tx["Special Needs Experience"]  = format_field(s.special)
        tx["Care Setting"]              = s.setting
        tx["Environment"]               = format_field(s.environment)
        tx["Meals Provided"]            = format_field(s.meals)
        tx["Provides Transportation?"]  = format_field(s.transportation)

      else
        tx["Overall Grade"]     = g[:cumulative][:letter] || "N/A"
        tx["Academic Status"]   = g[:status][:letter]     || "N/A"
        tx["Academic Progress"] = g[:progress][:letter]   || "N/A"
        tx["School Climate"]    = g[:climate][:letter]    || "N/A"

        tx["Address"]           = "#{s.address}<br/>#{s.address2}"
        tx["Grades Served"]     = s.grades_served || "Unknown"
        tx["Governance"]        = s.basic.governance || "Unknown"
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
    types = @schools.collect { |s| s.school_type }.uniq.reject { |s| s.nil? }.sort.join("_")
    @filter = {
      "EC"    => "ec",
      "HS_K8" => "k8hs",
      "K8"    => "k8",
      "HS"    => "hs",
    }[types] || "all"
  end

  private

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
    end
  end

  def format_field(val)
    if val.is_a?(Array)
      val.join(", ")
    else
      val == "0" ? "No" : (val == "1" ? "Yes" : val)
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
