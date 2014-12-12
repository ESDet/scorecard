Rails.application.routes.draw do
  match 'geocode' => 'bedrock/geo#geocode'
  match 'autocomplete/:address' => 'bedrock/geo#autocomplete'
  match 'disable_gps' => 'bedrock/geo#disable_gps'
  match 'enable_gps' => 'bedrock/geo#enable_gps'
end
