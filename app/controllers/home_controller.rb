class HomeController < ApplicationController
  def index
    @schools = School.all
    
    @overlay = Bedrock::Overlay.from_config('schools',
      :ty => :geojson,
      :elements => @schools)
    @map = Bedrock::Map.new({
      :extent         => Bedrock::city_extents(:detroit),
      :base_layers    => ['street'],
      :layers         => [ @overlay ],
      :layer_control  => true,
      :min_zoom => 10,
      :max_zoom => 18,
    })

  end
end
