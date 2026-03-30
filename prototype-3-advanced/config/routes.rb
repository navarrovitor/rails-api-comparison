Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  get "up" => "rails/health#show", as: :rails_health_check

  post '/api/v1/login', to: 'api/v1/auth#login'

  namespace :api do
    namespace :v1 do
      resources :articles, only: [:index, :show, :create, :update, :destroy]
    end
  end
end
