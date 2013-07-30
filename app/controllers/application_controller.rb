class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :iphone?, :android?, :current_search, :school_type_options
  layout 'workdept'
  
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
  
end
