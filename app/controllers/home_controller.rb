class HomeController < ApplicationController
  before_filter :password_protect, :only => [:refresh, :tips]
  
  def index
    session[:filter] = session[:loc] = nil
    @top = {
      :all        => School.not_ec.where("grade <> 'Promising'").order('points desc').limit(10),
      :ec         => School.ec.where('esd_el_2014 is not null').where("address2 like 'Detroit%'").order('points desc').limit(10),
      :elementary => School.elementary.where("grade <> 'Promising'").order('points desc').limit(10),
      :middle     => School.middle.where("grade <> 'Promising'").order('points desc').limit(10),
      :high       => School.high.where("grade <> 'Promising'").order('points desc').limit(10),
    }
    @top_labels = {
      :all        => "Top 10 Graded Schools",
      :ec         => "Highest Rated Pre-schools",
      :elementary => "Highest Rated Elementary Schools",
      :middle     => "Highest Rated Middle Schools",
      :high       => "Highest Rated High Schools",
    }
    @tips   = Tip.find_by_name('tips_tricks')
    @guides = Tip.find_by_name('parent_guides')
  end

  def resources
    @page = Tip.find_by_name('resources')
  end
  
  def search
    redirect_to root_path and return if params[:q].blank?
    if @q = params[:q]
      exact = School.find_by_name(@q)
      redirect_to school_path(:id => exact.slug) and return if exact
      redirect_to root_path, :notice => "Search isn't done yet, sorry!"
    end
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
        'k8'        => 'ESD K8 2014',
        'hs'        => 'ESD HS 2014',
        'meap_2013' => 'MEAP 2013',
        'meap_all'  => 'MEAP 2009-13',
        'act'       => 'ACT 2014',
        '5e'        => '5Essentials 2014',
        'sitevisit' => 'ESD Site Visit 2014',
        'ec'        => 'Early Childhood',
        #'reset'     => "Erase database and reload everything",
      }.collect { |k,v| [v,k] }
      
    elsif request.method == 'POST'
      case params[:what]
      when 'reset'
        Importer.get_schema
        Importer.get_profiles
        Importer.get_scores 'esd_k8_2014'
        Importer.get_scores 'esd_hs_2014'
        Importer.get_scores 'act_2014'
        Importer.get_scores 'meap_2013'
        Importer.get_scores 'meap_2012'
        Importer.get_scores 'meap_2011'
        Importer.get_scores 'meap_2010'
        Importer.get_scores 'meap_2009'
        Importer.get_scores 'fiveessentials_2014'
        Importer.get_earlychild

      when 'all'
        Importer.get_profiles
        Importer.get_scores 'esd_k8_2014'
        Importer.get_scores 'esd_hs_2014'
        Importer.get_scores 'meap_2013'
        Importer.get_scores 'meap_2012'
        Importer.get_scores 'meap_2011'
        Importer.get_scores 'meap_2010'
        Importer.get_scores 'meap_2009'
        Importer.get_scores 'act_2014'
        Importer.get_scores 'fiveessentials_2014'
        Importer.get_earlychild
        
      when 'profiles'
        Importer.get_profiles
        
      when 'meap_2013'
        Importer.get_scores 'meap_2013'

      when 'meap_all'
        Importer.get_scores 'meap_2013'
        Importer.get_scores 'meap_2012'
        Importer.get_scores 'meap_2011'
        Importer.get_scores 'meap_2010'
        Importer.get_scores 'meap_2009'
        
      when 'act'
        Importer.get_scores 'act_2014'
      
      when 'k8'
        Importer.get_scores 'esd_k8_2014'

      when 'hs'
        Importer.get_scores 'esd_hs_2013'
        
      when '5e'
        Importer.get_scores 'fiveessentials_2014'
        
      when 'sitevisit'
        Importer.get_scores 'esd_site_visit_2014'
      
      when 'ec'
        Importer.get_earlychild
        Importer.get_el_2014
      end
      
      redirect_to :refresh, :notice => "Ok, we've refreshed that data!"
    end
  end
  

  def tips
    @tips = Tip.all
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
