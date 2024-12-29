Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root to: "today#index"
  # root to: "players#index"

  devise_for :player,
             controllers: {
               sessions: "player/sessions",
               registrations: "player/registrations"
             }

  get "/today", to: "today#index", as: "today"
  get "/rankings", to: "rankings#index", as: "rankings"
  get "/about", to: "pages#about", as: "about"
  get "/reservations", to: "pages#reservations", as: "reservations"
  get "/help", to: "pages#help", as: "help"
  get "/not_found", to: "pages#not_found", as: "not_found"

  resources :tournaments, only: [:index, :show]
  resources :matches, only: [:index, :show]
  resources :players, only: [:index, :show]
  resources :articles, only: [:index, :show]


  namespace :player do
    resources :matches, only: [:create, :edit, :update, :destroy] do
      post :accept, on: :member
      post :reject, on: :member
      get :finish_init, on: :member
      post :finish, on: :member
      post :cancel, on: :member
      post :toggle_reaction, on: :member

      resources :comments, only: [:create, :edit, :update], module: :matches do
        post :delete, on: :member
      end

      post :switch_prediction, on: :member
    end

    resources :articles, except: [:index, :create, :new, :show, :update, :destroy, :edit] do
      post :toggle_reaction, on: :member

      resources :comments, only: [:create, :edit, :update], module: :articles do
        post :delete, on: :member
      end
    end

    resources :tournaments, except: [:index, :create, :new, :show, :update, :destroy, :edit] do
      post :toggle_reaction, on: :member

      resources :comments, only: [:create, :edit, :update], module: :tournaments do
        post :delete, on: :member
      end
    end

    post "players/toggle_open_to_play"
    post "players/toggle_cant_play"
    post "players/anonymize"
  end


  # MANAGERS --------------------------------- (begin)

  devise_for :manager,
             controllers: {
               sessions: "manager/sessions",
               registrations: "manager/registrations"
             }

  namespace :manager do
    root to: "pages#dashboard"

    get "pages/dashboard"

    resources :seasons, only: [:new, :create, :edit, :update]

    resources :players, only: [:edit, :update] do
      post :toggle_access, on: :member
    end

    post "enrollments/toggle", to: "enrollments#toggle", as: "toggle_enrollment"

    resources :tournaments, except: [:show, :destroy]
    resources :articles, except: [:show]
  end

  # MANAGERS --------------------------------- (end)
end
