ESD::Application.routes.draw do
  root :to => "home#index"
  match 'resources'         => 'home#resources', :via => :get
  match 'schools'           => 'schools#index', :via => :post
  match 'schools/:id'       => 'schools#show', as: :school
  match 'compare(/*which)'  => 'schools#compare'
  match 'robots.txt'        => 'home#robots',    :as => :robots
end
