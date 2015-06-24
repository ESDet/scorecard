class HomeController < ApplicationController
  before_filter :password_protect, :only => [:tips]

  def index
    @school_names = []
  end

  def resources
    render 'shared/_resources'
  end

  def robots
    response = (Rails.env == 'production') ? '' : "User-Agent: *\nDisallow: /"
    render :text => response
  end
end
