Rails.application.routes.draw do
  # Healthcheck endpoint required for Docker and Kubernetes probes
  get "up" => "rails/health#show", as: :rails_health_check

  # Make the tasks dashboard the home page
  root "tasks#index"

  # Standard CRUD routes (/tasks)
  resources :tasks
end