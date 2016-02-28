class HomeController < ApplicationController
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
