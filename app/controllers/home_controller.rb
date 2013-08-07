class HomeController < ApplicationController

  
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
  
end
