Rails.application.routes.draw do
  devise_for :users

  resources :investments, only: [:index, :show] do
    member do
      post :upload_document
      get :documents
      patch :documents
    end
  end

  namespace :admin do
    get "site_analytics", to: "site_analytics#show"
    resources :projects, only: [:index, :show]
    resources :sites, only: [:index, :new, :create]

    resources :investments, only: [] do
      collection do
        get :assign
        post :create_assignment
      end
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "investments#index"
end
