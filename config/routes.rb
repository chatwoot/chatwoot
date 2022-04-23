Rails.application.routes.draw do
  # AUTH STARTS
  match 'auth/:provider/callback', to: 'home#callback', via: [:get, :post]
  mount_devise_token_auth_for 'User', at: 'auth', controllers: {
    confirmations: 'devise_overrides/confirmations',
    passwords: 'devise_overrides/passwords',
    sessions: 'devise_overrides/sessions',
    token_validations: 'devise_overrides/token_validations'
  }, via: [:get, :post]

  ## renders the frontend paths only if its not an api only server
  if ActiveModel::Type::Boolean.new.cast(ENV.fetch('CW_API_ONLY_SERVER', false))
    root to: 'api#index'
  else
    root to: 'dashboard#index'

    get '/app', to: 'dashboard#index'
    get '/app/*params', to: 'dashboard#index'
    get '/app/accounts/:account_id/settings/inboxes/new/twitter', to: 'dashboard#index', as: 'app_new_twitter_inbox'
    get '/app/accounts/:account_id/settings/inboxes/new/:inbox_id/agents', to: 'dashboard#index', as: 'app_twitter_inbox_agents'

    resource :widget, only: [:show]
    namespace :survey do
      resources :responses, only: [:show]
    end
  end

  get '/api', to: 'api#index'
  namespace :api, defaults: { format: 'json' } do
    namespace :v1 do
      # ----------------------------------
      # start of account scoped api routes
      resources :accounts, only: [:create, :show, :update] do
        member do
          post :update_active_at
        end

        scope module: :accounts do
          namespace :actions do
            resource :contact_merge, only: [:create]
          end

          resource :bulk_actions, only: [:create]
          resources :agents, only: [:index, :create, :update, :destroy]
          resources :agent_bots, only: [:index, :create, :show, :update, :destroy]

          resources :callbacks, only: [] do
            collection do
              post :register_facebook_page
              get :register_facebook_page
              post :facebook_pages
              post :reauthorize_page
            end
          end
          resources :canned_responses, only: [:index, :create, :update, :destroy]
          resources :automation_rules, only: [:index, :create, :show, :update, :destroy] do
            post :clone
          end
          resources :campaigns, only: [:index, :create, :show, :update, :destroy]

          namespace :channels do
            resource :twilio_channel, only: [:create]
          end
          resources :conversations, only: [:index, :create, :show] do
            collection do
              get :meta
              get :search
              post :filter
            end
            scope module: :conversations do
              resources :messages, only: [:index, :create, :destroy]
              resources :assignments, only: [:create]
              resources :labels, only: [:create, :index]
              resource :direct_uploads, only: [:create]
            end
            member do
              post :mute
              post :unmute
              post :transcript
              post :toggle_status
              post :toggle_typing_status
              post :update_last_seen
              post :custom_attributes
            end
          end

          resources :contacts, only: [:index, :show, :update, :create, :destroy] do
            collection do
              get :active
              get :search
              post :filter
              post :import
            end
            member do
              get :contactable_inboxes
              post :destroy_custom_attributes
            end
            scope module: :contacts do
              resources :conversations, only: [:index]
              resources :contact_inboxes, only: [:create]
              resources :labels, only: [:create, :index]
              resources :notes
            end
          end
          resources :csat_survey_responses, only: [:index] do
            collection do
              get :metrics
            end
          end
          resources :custom_attribute_definitions, only: [:index, :show, :create, :update, :destroy]
          resources :custom_filters, only: [:index, :show, :create, :update, :destroy]
          resources :inboxes, only: [:index, :show, :create, :update, :destroy] do
            get :assignable_agents, on: :member
            get :campaigns, on: :member
            get :agent_bot, on: :member
            post :set_agent_bot, on: :member
            delete :avatar, on: :member
          end
          resources :inbox_members, only: [:create, :show], param: :inbox_id do
            collection do
              delete :destroy
              patch :update
            end
          end
          resources :labels, only: [:index, :show, :create, :update, :destroy]

          resources :notifications, only: [:index, :update] do
            collection do
              post :read_all
              get :unread_count
            end
          end
          resource :notification_settings, only: [:show, :update]

          resources :teams do
            resources :team_members, only: [:index, :create] do
              collection do
                delete :destroy
                patch :update
              end
            end
          end

          namespace :twitter do
            resource :authorization, only: [:create]
          end

          resources :webhooks, only: [:index, :create, :update, :destroy]
          namespace :integrations do
            resources :apps, only: [:index, :show]
            resources :hooks, only: [:create, :update, :destroy]
            resource :slack, only: [:create, :update, :destroy], controller: 'slack'
          end
          resources :working_hours, only: [:update]

          namespace :kbase do
            resources :portals do
              resources :categories do
                resources :folders
              end
              resources :articles
            end
          end
        end
      end
      # end of account scoped api routes
      # ----------------------------------

      namespace :integrations do
        resources :webhooks, only: [:create]
      end

      resource :profile, only: [:show, :update] do
        delete :avatar, on: :collection
        member do
          post :availability
        end
      end

      resource :notification_subscriptions, only: [:create, :destroy]

      namespace :widget do
        resource :direct_uploads, only: [:create]
        resource :config, only: [:create]
        resources :campaigns, only: [:index]
        resources :events, only: [:create]
        resources :messages, only: [:index, :create, :update]
        resources :conversations, only: [:index, :create] do
          collection do
            post :update_last_seen
            post :toggle_typing
            post :transcript
            get  :toggle_status
          end
        end
        resource :contact, only: [:show, :update] do
          collection do
            post :destroy_custom_attributes
          end
        end
        resources :inbox_members, only: [:index]
        resources :labels, only: [:create, :destroy]
      end
    end

    namespace :v2 do
      resources :accounts, only: [], module: :accounts do
        resources :reports, only: [:index] do
          collection do
            get :summary
            get :agents
            get :inboxes
            get :labels
            get :teams
            get :conversations
          end
        end
      end
    end
  end

  # ----------------------------------------------------------------------
  # Routes for platform APIs
  namespace :platform, defaults: { format: 'json' } do
    namespace :api do
      namespace :v1 do
        resources :users, only: [:create, :show, :update, :destroy] do
          member do
            get :login
          end
        end
        resources :agent_bots, only: [:index, :create, :show, :update, :destroy]
        resources :accounts, only: [:create, :show, :update, :destroy] do
          resources :account_users, only: [:index, :create] do
            collection do
              delete :destroy
            end
          end
        end
      end
    end
  end

  # ----------------------------------------------------------------------
  # Routes for inbox APIs Exposed to contacts
  namespace :public, defaults: { format: 'json' } do
    namespace :api do
      namespace :v1 do
        resources :inboxes do
          scope module: :inboxes do
            resources :contacts, only: [:create, :show, :update] do
              resources :conversations, only: [:index, :create] do
                resources :messages, only: [:index, :create, :update]
              end
            end
          end
        end
        resources :csat_survey, only: [:show, :update]
      end
    end
  end

  # ----------------------------------------------------------------------
  # Used in mailer templates
  resource :app, only: [:index] do
    resources :accounts do
      resources :conversations, only: [:show]
    end
  end

  # ----------------------------------------------------------------------
  # Routes for channel integrations
  mount Facebook::Messenger::Server, at: 'bot'
  get 'webhooks/twitter', to: 'api/v1/webhooks#twitter_crc'
  post 'webhooks/twitter', to: 'api/v1/webhooks#twitter_events'
  post 'webhooks/line/:line_channel_id', to: 'webhooks/line#process_payload'
  post 'webhooks/telegram/:bot_token', to: 'webhooks/telegram#process_payload'
  post 'webhooks/whatsapp/:phone_number', to: 'webhooks/whatsapp#process_payload'
  post 'webhooks/sms/:phone_number', to: 'webhooks/sms#process_payload'
  get 'webhooks/instagram', to: 'webhooks/instagram#verify'
  post 'webhooks/instagram', to: 'webhooks/instagram#events'

  namespace :twitter do
    resource :callback, only: [:show]
  end

  namespace :twilio do
    resources :callback, only: [:create]
  end

  # ----------------------------------------------------------------------
  # Routes for external service verifications
  get 'apple-app-site-association' => 'apple_app#site_association'
  get '.well-known/assetlinks.json' => 'android_app#assetlinks'

  # ----------------------------------------------------------------------
  # Internal Monitoring Routes
  require 'sidekiq/web'
  require 'sidekiq/cron/web'

  devise_for :super_admins, path: 'super_admin', controllers: { sessions: 'super_admin/devise/sessions' }
  devise_scope :super_admin do
    get 'super_admin/logout', to: 'super_admin/devise/sessions#destroy'
    namespace :super_admin do
      root to: 'dashboard#index'

      resource :app_config, only: [:show, :create]

      # order of resources affect the order of sidebar navigation in super admin
      resources :accounts
      resources :users, only: [:index, :new, :create, :show, :edit, :update]
      resources :access_tokens, only: [:index, :show]
      resources :installation_configs, only: [:index, :new, :create, :show, :edit, :update]
      resources :agent_bots, only: [:index, :new, :create, :show, :edit, :update]
      resources :platform_apps, only: [:index, :new, :create, :show, :edit, :update]

      # resources that doesn't appear in primary navigation in super admin
      resources :account_users, only: [:new, :create, :destroy]
    end
    authenticated :super_admin do
      mount Sidekiq::Web => '/monitoring/sidekiq'
    end
  end

  namespace :installation do
    get 'onboarding', to: 'onboarding#index'
    post 'onboarding', to: 'onboarding#create'
  end

  # ---------------------------------------------------------------------
  # Routes for swagger docs
  get '/swagger/*path', to: 'swagger#respond'
  get '/swagger', to: 'swagger#respond'

  # ----------------------------------------------------------------------
  # Routes for testing
  resources :widget_tests, only: [:index] unless Rails.env.production?
end
