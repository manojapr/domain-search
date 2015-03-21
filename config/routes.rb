Rails.application.routes.draw do
  resources :domains 
  	post "/domains/search", to: "domains#search"

  root to: 'domains#index'

end
