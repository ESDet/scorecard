ESD::Application.routes.draw do

  match 'search'            => 'home#search', :as => :search, :method => :post
  match 'resources'         => 'home#resources', :via => :get
  match 'schools'           => 'schools#index', :via => :post
  match 'schools/:id(/:type)'       => 'schools#show', as: :school
  match 'compare(/*which)'  => 'schools#compare'
  match 'robots.txt'        => 'home#robots',    :as => :robots
  match 'tips'              => 'home#tips', :via => :get
  match 'tips'              => 'home#save_tips', :via => :post

  root :to => "home#index"

end
