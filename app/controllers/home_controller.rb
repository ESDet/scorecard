class HomeController < ApplicationController
  before_filter :password_protect, :only => [:refresh]
  
  def index
    session[:filter] = session[:loc] = nil
    @top = School.order('points desc').limit(10)
  end

  
  def search
    if params[:q]
      @q = params[:q]
      exact = School.find_by_name(@q)
      redirect_to school_path(:id => exact.slug) and return if exact
      redirect_to root_path, :notice => "Search isn't done yet, sorry!"
      
    else
      redirect_to root_path and return
    end
  end
  
  
  def refresh
    if request.method == 'GET'
      # Show a menu page
      @options = {
        'all'       => 'All data (profiles, MEAP, K8 and HS)',
        'profiles'  => 'School profiles',
        'meap'      => 'MEAP 2012',
        'k8'        => 'ESD K8 2013',
        'hs'        => 'ESD HS 2013',
        #'reset'     => "Erase database and reload everything",
      }.collect { |k,v| [v,k] }
      render :layout => 'noside'
      
    elsif request.method == 'POST'
      case params[:what]
      when 'reset'
        Importer.get_schema
        Importer.get_profiles
        Importer.get_scores 'meap_2012'
        Importer.get_scores 'esd_k8_2013'
        Importer.get_scores 'esd_hs_2013'

      when 'all'
        Importer.get_profiles
        Importer.get_scores 'meap_2012'
        Importer.get_scores 'esd_k8_2013'
        Importer.get_scores 'esd_hs_2013'
        
      when 'profiles'
        Importer.get_profiles
        
      when 'meap'
        Importer.get_scores 'meap_2012'

      when 'k8'
        Importer.get_scores 'esd_k8_2013'

      when 'hs'
        Importer.get_scores 'esd_hs_2013'
      end
      
      redirect_to :refresh, :notice => "Ok, we've refreshed that data!"
    end
  end
  
  protected

  def password_protect
    authenticate_or_request_with_http_basic do |user, password|
      user == 'esd' && password == 'd3tr01t'
    end
  end
  
  
end
