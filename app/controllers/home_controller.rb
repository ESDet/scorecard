class HomeController < ApplicationController
  before_filter :password_protect, :only => [:refresh, :tips]
  
  def index
    session[:filter] = session[:loc] = nil
    @top = School.not_ec.order('points desc').limit(10)
    @top_ec = School.ec.order('points desc').limit(10)
  end

  
  def search
    redirect_to root_path and return if params[:q].blank?
    @q = params[:q]
    exact = School.find_by_name(@q)
    redirect_to school_path(:id => exact.slug) and return if exact
    redirect_to root_path, :notice => "Search isn't done yet, sorry!"
  end
  
  def robots
    response = (Rails.env == 'production') ? '' : "User-Agent: *\nDisallow: /"
    render :text => response
  end


  
  def refresh
    if request.method == 'GET'
      # Show a menu page
      @options = {
        'all'       => 'All data (profiles, MEAP, K8 and HS, ACT)',
        'profiles'  => 'School profiles',
        'k8'        => 'ESD K8 2013',
        'hs'        => 'ESD HS 2013',
        'meap_2012' => 'MEAP 2012',
        'meap_all'  => 'MEAP 2009-12',
        'act'       => 'ACT 2013',
        '5e'        => '5Essentials 2013',
        'ec'        => 'Early Childhood',
        #'reset'     => "Erase database and reload everything",
      }.collect { |k,v| [v,k] }
      render :layout => 'noside'
      
    elsif request.method == 'POST'
      case params[:what]
      when 'reset'
        Importer.get_schema
        Importer.get_profiles
        Importer.get_scores 'esd_k8_2013'
        Importer.get_scores 'esd_hs_2013'
        Importer.get_scores 'act_2013'
        Importer.get_scores 'meap_2012'
        Importer.get_scores 'meap_2011'
        Importer.get_scores 'meap_2010'
        Importer.get_scores 'meap_2009'
        Importer.get_scores 'fiveessentials_2013'
        Importer.get_earlychild

      when 'all'
        Importer.get_profiles
        Importer.get_scores 'esd_k8_2013'
        Importer.get_scores 'esd_hs_2013'
        Importer.get_scores 'meap_2012'
        Importer.get_scores 'meap_2011'
        Importer.get_scores 'meap_2010'
        Importer.get_scores 'meap_2009'
        Importer.get_scores 'act_2013'
        Importer.get_scores 'fiveessentials_2013'
        Importer.get_earlychild
        
      when 'profiles'
        Importer.get_profiles
        
      when 'meap_2012'
        Importer.get_scores 'meap_2012'

      when 'meap_all'
        Importer.get_scores 'meap_2012'
        Importer.get_scores 'meap_2011'
        Importer.get_scores 'meap_2010'
        Importer.get_scores 'meap_2009'
        
      when 'act'
        Importer.get_scores 'act_2013'
      
      when 'k8'
        Importer.get_scores 'esd_k8_2013'

      when 'hs'
        Importer.get_scores 'esd_hs_2013'
        
      when '5e'
        Importer.get_scores 'fiveessentials_2013'
      
      when 'ec'
        Importer.get_earlychild
      end
      
      redirect_to :refresh, :notice => "Ok, we've refreshed that data!"
    end
  end
  

  def tips
    @tips = Tip.all
    render :layout => 'noside'
  end  
  
  def save_tips
    tips = params[:tips]
    
    tips.each do |t|
      tip = Tip.find(t[:id])
      tip.update_attributes(t)
    end
    
    flash[:notice] = 'Saved your changes.'
    redirect_to '/tips'
  end
  
  protected

  def password_protect
    authenticate_or_request_with_http_basic do |user, password|
      user == 'esd' && password == 'd3tr01t'
    end
  end
  
  
end
