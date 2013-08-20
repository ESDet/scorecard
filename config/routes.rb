ESD::Application.routes.draw do

  match 'map'               => 'home#map', :as => :map
  match 'search'            => 'home#search', :as => :search, :method => :post
  match 'schools/overview'  => 'schools#overview'
  match 'compare(/*which)'    => 'schools#compare'
  resources :schools
  
  match 'next/:id'          => 'schools#increment', :by => 1, :as => :next
  match 'previous/:id'      => 'schools#increment', :by => -1, :as => :previous
  
  match 'refresh'           => 'home#refresh'
  
  root :to => "home#index"

end
