require 'sidekiq/web'

Rails.application.routes.draw do
  mount RailsEventStore::Browser => '/res' if Rails.env.development?
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  post "tasks" => "tasks#create"
  patch "tasks/:id/complete" => "tasks#complete"
  patch "tasks/:id/reopen" => "tasks#reopen"
  delete "tasks/:id" => "tasks#delete"
  patch "tasks/:id/assign_date" => "tasks#assign_date"
  patch "tasks/:id/change_name" => "tasks#change_name"

  resources :projects do
    member do
      patch :start
      patch :complete
    end
  end

  get "kanban" => "projects#kanban"

  # Defines the root path route ("/")
  # root "posts#index"
  mount Sidekiq::Web => '/sidekiq'
end
