ESD::Application.routes.draw do

  match 'map' => 'home#map', :as => :map
  match 'search' => 'home#search', :as => :search, :method => :post
  resources :schools
  root :to => "home#index"

end
