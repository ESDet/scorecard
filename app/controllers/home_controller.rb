class HomeController < ApplicationController
  before_filter :password_protect, :only => [:tips]

  def index
    @school_names = []
    request.format = :html
    respond_to do |format|
      format.html
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
