ESD::Application.routes.draw do

  match 'map'               => 'home#map', :as => :map
  match 'search'            => 'home#search', :as => :search, :method => :post
  match 'schools/overview'  => 'schools#overview'
  match 'compare(/*which)'  => 'schools#compare'
  match 'schools'           => 'schools#index', :via => :post
  resources :schools
  
  match 'next/:id'          => 'schools#increment', :by => 1, :as => :next
  match 'previous/:id'      => 'schools#increment', :by => -1, :as => :previous
  
  match 'robots.txt'        => 'home#robots',    :as => :robots
  match 'refresh'           => 'home#refresh'
  match 'tips'              => 'home#tips', :via => :get
  match 'tips'              => 'home#save_tips', :via => :post
  
  root :to => "home#index"

end
