class HomeController < ApplicationController
  before_filter :password_protect, :only => [:tips]

  def index
    session[:filter] = session[:loc] = nil
    @school_names = School.pluck(:name)
    @resources = Tip.find_by_name('resources')
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
