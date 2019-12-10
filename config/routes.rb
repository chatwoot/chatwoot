Rails.application.routes.draw do
  # AUTH STARTS
  match 'auth/:provider/callback', to: 'home#callback', via: [:get, :post]
  mount_devise_token_auth_for 'User', at: 'auth', controllers: { confirmations: 'confirmations', passwords: 'passwords',
                                                                 sessions: 'sessions' }, via: [:get, :post]

  root to: 'dashboard#index'

  get '/app', to: 'dashboard#index'
  get '/app/*params', to: 'dashboard#index'

  match '/status', to: 'home#status', via: [:get]

  resources :widgets, only: [:index]

  namespace :api, :defaults => { :format => 'json' } do
    namespace :v1 do
      resources :callbacks, only: [] do
        collection do
          post :register_facebook_page
          get :register_facebook_page
          post :get_facebook_pages
          post :reauthorize_page
        end
      end

      namespace :widget do
        resources :messages, only: [:index, :create]
        resources :inboxes, only: [:create]
      end

      resource :profile, only: [:show, :update]
      resources :accounts, only: [:create]
      resources :inboxes, only: [:index, :destroy]
      resources :agents, except: [:show, :edit, :new]
      resources :contacts, only: [:index, :show, :update, :create]
      resources :labels, only: [:index]
      resources :canned_responses, except: [:show, :edit, :new]
      resources :inbox_members, only: [:create, :show], param: :inbox_id
      resources :facebook_indicators, only: [] do
        collection do
          post :mark_seen
          post :typing_on
          post :typing_off
        end
      end

      resources :reports, only: [] do
        collection do
          get :account
          get :agent
        end
        member do
          get :account_summary
          get :agent_summary
        end
      end

      resources :conversations, only: [:index, :show] do
        scope module: :conversations do # for nested controller
          resources :messages, only: [:create]
          resources :assignments, only: [:create]
          resources :labels, only: [:create, :index]
        end
        member do
          post :toggle_status
          post :update_last_seen
          get :get_messages
        end
      end

      # this block is only required if subscription via chargebee is enabled
      if ENV['BILLING_ENABLED']
        resources :subscriptions, only: [:index] do
          collection do
            get :summary
          end
        end
      
        resources :webhooks, only: [] do
          collection do
            post :chargebee
          end
        end
      end

    end
  end

  scope module: 'mailer' do
    resources :conversations, only: [:show]
  end

  mount Facebook::Messenger::Server, at: 'bot'
  post '/webhooks/telegram/:account_id/:inbox_id' => 'home#telegram'

  # Routes for testing
  resources :widget_tests, only: [:index] unless Rails.env.production?
end
