class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :iphone?, :android?
  
  protected
  
  def iphone?;  request.env["HTTP_USER_AGENT"] && request.env["HTTP_USER_AGENT"][/(Mobile\/.+Safari)/] end
  def android?; request.env["HTTP_USER_AGENT"] && request.env["HTTP_USER_AGENT"][/Android/] end

end
