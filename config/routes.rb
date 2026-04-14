Rails.application.routes.draw do
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
    get "/email_preview/reset_password", to: proc { |_env|
      DevisePreviewMailer.reset_password_preview.deliver_now
      [302, { "Location" => "/letter_opener" }, []]
    }
  end

  devise_for :users, controllers: { passwords: "users/passwords" }

  resources :investments, only: [:index, :show] do
    member do
      post :upload_document
      get :documents
      patch :documents
    end
  end

  namespace :admin do
    get "dashboard", to: "dashboard#show"
    post "dashboard/send_welcome_emails", to: "dashboard#send_welcome_emails"
    get "site_analytics", to: "site_analytics#show"
    post "site_analytics/data", to: "site_analytics#data"
    resources :offerings, only: [:index, :show, :new, :create] do
      member do
        get :export_addresses
      end
    end
    resources :sites, only: [:index, :new, :create]
    resources :users, only: [:index, :new, :create, :update]
    resource :impersonation, only: [:create, :destroy]

    resources :investments, only: [] do
      collection do
        get :assign
        post :create_assignment
        get :import
        post :create_import
      end
    end
    resources :investment_documents, only: [:new, :create]
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
