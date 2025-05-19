Rails.application.routes.draw do
  # Route for the welcome page
  get "welcome/index"

  # Root route — this will be shown when you browse http://<publicip>:3000/
  root "welcome#index"

  # Health check endpoint (useful for uptime monitoring)
  get "up" => "rails/health#show", as: :rails_health_check

  # You can add more routes below this as your app grows
end

