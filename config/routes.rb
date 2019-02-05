Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'main#index'
  resources :placements, only: [:index, :show, :update] do
    member do
      post 'duplicate'
    end
  end

  resources :classrooms do
    resources :placements, only: [:index, :create]

    member do
      get 'export-feedback'
    end
  end

  resources :interviews, only: [:index, :show] do
    collection do
      # Webhook for receiving feedback forms
      post 'feedback'
    end
  end

  resources :students, only: [] do
    collection do
      get 'feedback'
    end

    member do
      get 'companies'
      post 'rankings'
    end
  end

  # Authentication
  get '/login', to: 'users#login', as: 'login'
  get '/auth/:provider/callback', to: 'users#auth_callback', as: 'auth_callback'
  get '/logout', to: 'users#logout', as: 'logout'

  get '/sheets', to: 'sheets#index', as: 'sheets'
end
