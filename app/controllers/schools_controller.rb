class SchoolsController < ApplicationController

  def index
    @schools = School.all
  end
  
  def show
    @school = School.find params[:id]
    @subtitle = @school.SCHOOL_NAME_2011
    @high = @school.id % 2 == 0 # @school.AUTHORIZED_GRADES_2011 == '9-12'
    
    @school_o = Bedrock::Overlay.from_config('schools',
      :ty       => :geojson,
      :elements => [@school])
    @map = Bedrock::Map.new({
      :base_layers    => ['street'],
      :layers         => [ @school_o ],
      :layer_control  => true,
      :center => { :lon => @school.centroid.x, :lat => @school.centroid.y },
      :min_zoom => 12,
      :max_zoom => 18,
      :zoom => 15,
    })
    
    
    respond_to do |format|
      format.html { }
      #format.pdf { render :layout => false }
    end
  end
  
end