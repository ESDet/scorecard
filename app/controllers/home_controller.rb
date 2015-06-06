class HomeController < ApplicationController
  before_filter :password_protect, :only => [:tips]

  def index
    @school_names = Portal.new("")
    @resources = Tip.find_by_name('resources')
  end

  def resources
    @page = Tip.find_by_name('resources')
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
