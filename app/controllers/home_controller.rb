class HomeController < ApplicationController

  def index
    @schools = School.order('SCHOOL_NAME_2011')
  end
  
  
  def map
    @schools = School.all
    @districts = District.all
    
    @school_o = Bedrock::Overlay.from_config('schools',
      :ty       => :geojson,
      :elements => @schools)
    @district_o = Bedrock::Overlay.from_config('districts',
      :ty => :geojson,
      :elements => @districts)
    @map = Bedrock::Map.new({
      #:extent         => Bedrock::city_extents(:detroit),
      :base_layers    => ['street'],
      :layers         => [ @school_o ],
      :layer_control  => true,
      :center => { :lon => -83.09577941894531, :lat => 42.364885996366525 },
      :min_zoom => 11,
      :max_zoom => 18,
      :zoom => 12,
    })
  end
  
end
