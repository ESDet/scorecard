ESD::Application.routes.draw do
  root "home#index"
  get 'resources',         to: 'home#resources'
  get 'schools',           to: 'schools#index'
  get 'schools/:id',       to: 'schools#show', as: :school
  #get 'compare(/*which)',  to: 'schools#compare'
  get 'robots.txt',        to: 'home#robots',:as => :robots
  get '*path',             to: 'home#index', via: :all
end
