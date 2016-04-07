class HomeController < ApplicationController
  def index
    @school_names = []
    if request.format != Mime::HTML
      redirect_to root_path and return
    end
  end

  def resources
    render 'shared/_resources'
  end

  def robots
    response = (Rails.env == 'production') ? '' : "User-Agent: *\nDisallow: /"
    render :text => response
  end
end
