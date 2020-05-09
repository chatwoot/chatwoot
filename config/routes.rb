Rails.application.routes.draw do
  # AUTH STARTS
  match 'auth/:provider/callback', to: 'home#callback', via: [:get, :post]
  mount_devise_token_auth_for 'User', at: 'auth', controllers: {
    confirmations: 'devise_overrides/confirmations',
    passwords: 'devise_overrides/passwords',
    sessions: 'devise_overrides/sessions',
    token_validations: 'devise_overrides/token_validations'
  }, via: [:get, :post]

  root to: 'dashboard#index'

  get '/app', to: 'dashboard#index'
  get '/app/*params', to: 'dashboard#index'
  get '/app/accounts/:account_id/settings/inboxes/new/twitter', to: 'dashboard#index', as: 'app_new_twitter_inbox'
  get '/app/accounts/:account_id/settings/inboxes/new/:inbox_id/agents', to: 'dashboard#index', as: 'app_twitter_inbox_agents'

  resource :widget, only: [:show]

  get '/api', to: 'api#index'
  namespace :api, defaults: { format: 'json' } do
    namespace :v1 do
      # ----------------------------------
      # start of account scoped api routes
      resources :accounts, only: [:create, :show, :update], module: :accounts do
        namespace :actions do
          resource :contact_merge, only: [:create]
        end

        resources :agents, except: [:show, :edit, :new]
        resources :callbacks, only: [] do
          collection do
            post :register_facebook_page
            get :register_facebook_page
            post :facebook_pages
            post :reauthorize_page
          end
        end
        resources :canned_responses, except: [:show, :edit, :new]
        namespace :channels do
          resource :twilio_channel, only: [:create]
        end
        resources :conversations, only: [:index, :create, :show] do
          get 'meta', on: :collection
          scope module: :conversations do
            resources :messages, only: [:index, :create]
            resources :assignments, only: [:create]
            resources :labels, only: [:create, :index]
          end
          member do
            post :toggle_status
            post :toggle_typing_status
            post :update_last_seen
          end
        end

        resources :contacts, only: [:index, :show, :update, :create] do
          scope module: :contacts do
            resources :conversations, only: [:index]
          end
        end

        resources :facebook_indicators, only: [] do
          collection do
            post :mark_seen
            post :typing_on
            post :typing_off
          end
        end

        resources :inboxes, only: [:index, :create, :update, :destroy] do
          post :set_agent_bot, on: :member
        end
        resources :inbox_members, only: [:create, :show], param: :inbox_id
        resources :labels, only: [:index] do
          collection do
            get :most_used
          end
        end

        resources :notifications, only: [:index, :update]
        resource :notification_settings, only: [:show, :update]

        # this block is only required if subscription via chargebee is enabled
        resources :subscriptions, only: [:index] do
          collection do
            get :summary
          end
        end

        resources :webhooks, except: [:show]
      end

      # end of account scoped api routes
      # ----------------------------------

      resource :profile, only: [:show, :update]
      resource :notification_subscriptions, only: [:create]

      resources :agent_bots, only: [:index]

      namespace :widget do
        resources :events, only: [:create]
        resources :messages, only: [:index, :create, :update]
        resources :conversations do
          collection do
            post :toggle_typing
          end
        end
        resource :contact, only: [:update]
        resources :inbox_members, only: [:index]
        resources :labels, only: [:create, :destroy]
      end

      resources :webhooks, only: [] do
        collection do
          post :chargebee
        end
      end
    end

    namespace :v2 do
      resources :accounts, only: [], module: :accounts do
        resources :reports, only: [] do
          collection do
            get :account
          end
          member do
            get :account_summary
          end
        end
      end
    end
  end

  namespace :twitter do
    resource :authorization, only: [:create]
    resource :callback, only: [:show]
  end

  namespace :twilio do
    resources :callback, only: [:create]
  end

  # ----------------------------------------------------------------------
  # Used in mailer templates
  resource :app, only: [:index] do
    resources :accounts do
      resources :conversations, only: [:show]
    end
  end

  # ----------------------------------------------------------------------
  # Routes for social integrations
  mount Facebook::Messenger::Server, at: 'bot'
  get 'webhooks/twitter', to: 'api/v1/webhooks#twitter_crc'
  post 'webhooks/twitter', to: 'api/v1/webhooks#twitter_events'

  # ----------------------------------------------------------------------
  # Routes for testing
  resources :widget_tests, only: [:index] unless Rails.env.production?

  # ----------------------------------------------------------------------
  # Routes for external service verifications
  get 'apple-app-site-association' => 'apple_app#site_association'

  # ----------------------------------------------------------------------
  # Internal Monitoring Routes
  require 'sidekiq/web'

  scope :monitoring do
    # Sidekiq should use basic auth in production environment
    if Rails.env.production?
      Sidekiq::Web.use Rack::Auth::Basic do |username, password|
        ENV['SIDEKIQ_AUTH_USERNAME'] &&
          ENV['SIDEKIQ_AUTH_PASSWORD'] &&
          ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(username),
                                                      ::Digest::SHA256.hexdigest(ENV['SIDEKIQ_AUTH_USERNAME'])) &&
          ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(password),
                                                      ::Digest::SHA256.hexdigest(ENV['SIDEKIQ_AUTH_PASSWORD']))
      end
    end

    mount Sidekiq::Web, at: '/sidekiq'
  end

  # ---------------------------------------------------------------------
  # Routes for swagger docs
  get '/swagger/*path', to: 'swagger#respond'
  get '/swagger', to: 'swagger#respond'
end
