class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :iphone?, :android?, :current_search, :school_type_options
  helper_method :meta_keywords, :og_image, :og_title, :og_description, :twitter_link, :facebook_link

  protected

  def iphone?;  request.env["HTTP_USER_AGENT"] && request.env["HTTP_USER_AGENT"][/(Mobile\/.+Safari)/] end
  def android?; request.env["HTTP_USER_AGENT"] && request.env["HTTP_USER_AGENT"][/Android/] end

  def current_search
    logger.ap session
    if session[:filter].blank? and session[:type].blank?
      s = 'All Schools'
    else
      s = session[:type].blank? ? '' : (School::TYPES[session[:type].to_sym] + ' ')
      s += (session[:filter].capitalize + ' ') unless session[:filter].blank? or session[:filter] == 'all'
      s += 'Schools'
    end
    s += " in #{session[:loc]}" unless session[:loc].blank?
    return s
  end

  def school_type_options
    [['All Types', 'all']] + School::TYPES.collect { |k,v| [v, k.to_s] }
  end

  def og_image
    img = if @school.andand.earlychild?
      School.el_image(:overall, @school.esd_el_2015.andand.overall_rating)
    elsif @school
      School.k12_image(@school.overall_grade)
    else
      "icon.png"
    end
    "/images/#{img}"
  end

  def og_title
    @school.andand.name || @subtitle
  end

  def og_description
    if @school
      "Get more information about #{@school.display_name}. Includes overall rating, test scores, student growth data, school climate info and more."
    else
      "Use this Scorecard to find schools that fit your needs. Be sure to check out the resources below as they were designed with parents for parents."
    end
  end

  def meta_keywords
    words = ''
    if @school
      words = "#{@school.display_name}, #{@school.type_s}, #{@school.address2}, #{@school.basic.andand.governance}, "
    end
    words += "excellent schools, excellent schools detroit, scorecard, report card, school overview"
    words
  end


  def twitter_link
    opts = {
      :text => @subtitle,
      :url => request.url,
    }
    "http://twitter.com/share?#{opts.to_query}"
  end

  def facebook_link
    opts = {
      :u => request.url,
    }
    "https://www.facebook.com/sharer.php?#{opts.to_query}"
  end

end
