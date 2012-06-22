class HomeController < ApplicationController

  def index
  end
  
  
  def map
    #@schools = School.all
    #@districts = District.all
    
    @school_o = Bedrock::Overlay.from_config('schools',
      :ty       => :geojson,
     #:elements => @schools)
      :url      => schools_path(:format => :json),
      :mouseover => true)
    @district_o = Bedrock::Overlay.from_config('districts',
      :ty => :geojson,
      :elements => [District.find(580)])
    @map = Bedrock::Map.new({
      #:extent         => Bedrock::city_extents(:detroit),
      :base_layers    => ['street'],
      :layers         => [ @district_o, @school_o ],
      :layer_control  => true,
      :center => { :lon => -83.09577941894531, :lat => 42.364885996366525 },
      :min_zoom => 11,
      :max_zoom => 18,
      :zoom => 12,
      :layer_control => false,
    })
  end
  
  def search
    
    if params[:zip]
      @zip = params[:zip]
      redirect_to schools_path(:zip => @zip)
      
    elsif params[:q]
      @q = params[:q]
      exact = School.find_by_SCHOOL_NAME_2011(@q)
      redirect_to exact and return if exact
      redirect_to root_path, :notice => "Search isn't done yet, sorry!"
      
    else
      redirect_to root_path and return
    end
    
  end
  
end
