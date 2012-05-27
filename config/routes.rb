ESD::Application.routes.draw do

  match 'map' => 'home#map', :as => :map
  resources :schools
  root :to => "home#index"

end
