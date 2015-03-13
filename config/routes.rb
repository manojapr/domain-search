Rails.application.routes.draw do
  resources :domains

  root to: 'visitors#index'
end
