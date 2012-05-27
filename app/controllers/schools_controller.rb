class SchoolsController < ApplicationController

  def index
    @schools = School.all
  end
  
  def show
    @school = School.find params[:id]
    respond_to do |format|
      format.html { }
      format.pdf { render :layout => false }
    end
  end
  
end
