class HomeController < ApplicationController
  def index
    @schools = School.all
    @others = Other.all
    
    @school_overlay = Bedrock::Overlay.from_config('schools',
      :ty       => :geojson,
      :elements => @schools,
      :key      => { '#22aa66' => 'DPS Schools' } )
    @other_overlay = Bedrock::Overlay.from_config('others',
      :ty       => :geojson,
      :elements => @others,
      :key      => { '#446699' => 'Other Schools' } )
    @map = Bedrock::Map.new({
      #:extent         => Bedrock::city_extents(:detroit),
      :base_layers    => ['street'],
      :layers         => [ @school_overlay, @other_overlay ],
      :layer_control  => true,
      :center => { :lon => -83.09577941894531, :lat => 42.364885996366525 },
      :min_zoom => 11,
      :max_zoom => 18,
      :zoom => 12,
    })
  end
end
