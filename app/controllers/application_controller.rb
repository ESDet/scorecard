class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :iphone?, :android?, :current_search
  
  protected
  
  def iphone?;  request.env["HTTP_USER_AGENT"] && request.env["HTTP_USER_AGENT"][/(Mobile\/.+Safari)/] end
  def android?; request.env["HTTP_USER_AGENT"] && request.env["HTTP_USER_AGENT"][/Android/] end
  
  def current_search
    s = session[:filter].blank? ? 'All Schools' : "#{session[:filter].capitalize} Schools"
    s += " in #{session[:loc]}" unless session[:loc].blank?
    return s
  end

end
