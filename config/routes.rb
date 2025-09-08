Rails.application.routes.draw do
  # AUTH STARTS
  mount_devise_token_auth_for 'User', at: 'auth', controllers: {
    confirmations: 'devise_overrides/confirmations',
    passwords: 'devise_overrides/passwords',
    sessions: 'devise_overrides/sessions',
    token_validations: 'devise_overrides/token_validations',
    omniauth_callbacks: 'devise_overrides/omniauth_callbacks'
  }, via: [:get, :post]

  ## renders the frontend paths only if its not an api only server
  if ActiveModel::Type::Boolean.new.cast(ENV.fetch('CW_API_ONLY_SERVER', false))
    root to: 'api#index'
  else
    root to: 'dashboard#index'

    get '/app', to: 'dashboard#index'
    get '/app/*params', to: 'dashboard#index'
    get '/app/accounts/:account_id/settings/inboxes/new/twitter', to: 'dashboard#index', as: 'app_new_twitter_inbox'
    get '/app/accounts/:account_id/settings/inboxes/new/microsoft', to: 'dashboard#index', as: 'app_new_microsoft_inbox'
    get '/app/accounts/:account_id/settings/inboxes/new/instagram', to: 'dashboard#index', as: 'app_new_instagram_inbox'
    get '/app/accounts/:account_id/settings/inboxes/new/:inbox_id/agents', to: 'dashboard#index', as: 'app_twitter_inbox_agents'
    get '/app/accounts/:account_id/settings/inboxes/new/:inbox_id/agents', to: 'dashboard#index', as: 'app_email_inbox_agents'
    get '/app/accounts/:account_id/settings/inboxes/new/:inbox_id/agents', to: 'dashboard#index', as: 'app_instagram_inbox_agents'
    get '/app/accounts/:account_id/settings/inboxes/:inbox_id', to: 'dashboard#index', as: 'app_instagram_inbox_settings'
    get '/app/accounts/:account_id/settings/inboxes/:inbox_id', to: 'dashboard#index', as: 'app_email_inbox_settings'

    resource :widget, only: [:show]
    namespace :survey do
      resources :responses, only: [:show]
    end
    resource :slack_uploads, only: [:show]
  end

  get '/api', to: 'api#index'
  namespace :api, defaults: { format: 'json' } do
    namespace :v1 do
      # ----------------------------------
      # start of account scoped api routes
      resources :accounts, only: [:create, :show, :update] do
        member do
          post :update_active_at
          get :cache_keys
        end

        scope module: :accounts do
          namespace :actions do
            resource :contact_merge, only: [:create]
          end
          resource :bulk_actions, only: [:create]
          resources :agents, only: [:index, :create, :update, :destroy] do
            post :bulk_create, on: :collection
          end
          namespace :captain do
            resources :assistants do
              member do
                post :playground
              end
              collection do
                get :tools
              end
              resources :inboxes, only: [:index, :create, :destroy], param: :inbox_id
              resources :scenarios
            end
            resources :assistant_responses
            resources :bulk_actions, only: [:create]
            resources :copilot_threads, only: [:index, :create] do
              resources :copilot_messages, only: [:index, :create]
            end
            resources :documents, only: [:index, :show, :create, :destroy]
          end
          resource :saml_settings, only: [:show, :create, :update, :destroy]
          resources :agent_bots, only: [:index, :create, :show, :update, :destroy] do
            delete :avatar, on: :member
            post :reset_access_token, on: :member
          end
          resources :contact_inboxes, only: [] do
            collection do
              post :filter
            end
          end
          resources :assignable_agents, only: [:index]
          resource :audit_logs, only: [:show]
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
          resources :macros, only: [:index, :create, :show, :update, :destroy] do
            post :execute, on: :member
          end
          resources :sla_policies, only: [:index, :create, :show, :update, :destroy]
          resources :custom_roles, only: [:index, :create, :show, :update, :destroy]
          resources :agent_capacity_policies, only: [:index, :create, :show, :update, :destroy] do
            scope module: :agent_capacity_policies do
              resources :users, only: [:index, :create, :destroy]
              resources :inbox_limits, only: [:create, :update, :destroy]
            end
          end
          resources :campaigns, only: [:index, :create, :show, :update, :destroy]
          resources :dashboard_apps, only: [:index, :show, :create, :update, :destroy]
          namespace :channels do
            resource :twilio_channel, only: [:create]
          end
          resources :conversations, only: [:index, :create, :show, :update, :destroy] do
            collection do
              get :meta
              get :search
              post :filter
            end
            scope module: :conversations do
              resources :messages, only: [:index, :create, :destroy, :update] do
                member do
                  post :translate
                  post :retry
                end
              end
              resources :assignments, only: [:create]
              resources :labels, only: [:create, :index]
              resource :participants, only: [:show, :create, :update, :destroy]
              resource :direct_uploads, only: [:create]
              resource :draft_messages, only: [:show, :update, :destroy]
              # Streaming endpoints for bot responses
              resources :message_streams, only: [] do
                collection do
                  post :start
                  post :append
                  post :finish
                end
              end
            end
            member do
              post :mute
              post :unmute
              post :transcript
              post :toggle_status
              post :toggle_priority
              post :toggle_typing_status
              post :update_last_seen
              post :unread
              post :custom_attributes
              get :attachments
              get :inbox_assistant
            end
          end

          resources :search, only: [:index] do
            collection do
              get :conversations
              get :messages
              get :contacts
              get :articles
            end
          end

          resources :contacts, only: [:index, :show, :update, :create, :destroy] do
            collection do
              get :active
              get :search
              post :filter
              post :import
              post :export
            end
            member do
              get :contactable_inboxes
              post :destroy_custom_attributes
              delete :avatar
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
              get :download
            end
          end
          resources :applied_slas, only: [:index] do
            collection do
              get :metrics
              get :download
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
            post :sync_templates, on: :member
          end
          resources :inbox_members, only: [:create, :show], param: :inbox_id do
            collection do
              delete :destroy
              patch :update
            end
          end
          resources :labels, only: [:index, :show, :create, :update, :destroy]

          resources :notifications, only: [:index, :update, :destroy] do
            collection do
              post :read_all
              get :unread_count
              post :destroy_all
            end
            member do
              post :snooze
              post :unread
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

          # Assignment V2 Routes
          resources :assignment_policies do
            resources :inboxes, only: [:index, :create, :destroy], module: :assignment_policies
          end

          resources :inboxes, only: [] do
            resource :assignment_policy, only: [:show, :create, :destroy], module: :inboxes
          end

          namespace :twitter do
            resource :authorization, only: [:create]
          end

          namespace :microsoft do
            resource :authorization, only: [:create]
          end

          namespace :google do
            resource :authorization, only: [:create]
          end

          namespace :instagram do
            resource :authorization, only: [:create]
          end

          namespace :notion do
            resource :authorization, only: [:create]
          end

          namespace :whatsapp do
            resource :authorization, only: [:create]
          end

          resources :webhooks, only: [:index, :create, :update, :destroy]
          namespace :integrations do
            resources :apps, only: [:index, :show]
            resources :hooks, only: [:show, :create, :update, :destroy] do
              member do
                post :process_event
              end
            end
            resource :slack, only: [:create, :update, :destroy], controller: 'slack' do
              member do
                get :list_all_channels
              end
            end
            resource :dyte, controller: 'dyte', only: [] do
              collection do
                post :create_a_meeting
                post :add_participant_to_meeting
              end
            end
            resource :shopify, controller: 'shopify', only: [:destroy] do
              collection do
                post :auth
                get :orders
              end
            end
            resource :linear, controller: 'linear', only: [] do
              collection do
                delete :destroy
                get :teams
                get :team_entities
                post :create_issue
                post :link_issue
                post :unlink_issue
                get :search_issue
                get :linked_issues
              end
            end
            resource :notion, controller: 'notion', only: [] do
              collection do
                delete :destroy
              end
            end
          end
          resources :working_hours, only: [:update]

          resources :portals do
            member do
              patch :archive
              delete :logo
              post :send_instructions
              get :ssl_status
            end
            resources :categories
            resources :articles do
              post :reorder, on: :collection
            end
          end

          resources :upload, only: [:create]
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
          post :auto_offline
          put :set_active_account
          post :resend_confirmation
          post :reset_access_token
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
            post :destroy_custom_attributes
            post :set_custom_attributes
            post :update_last_seen
            post :toggle_typing
            post :transcript
            get  :toggle_status
          end
        end
        resource :contact, only: [:show, :update] do
          collection do
            post :destroy_custom_attributes
            patch :set_user
          end
        end
        resources :inbox_members, only: [:index]
        resources :labels, only: [:create, :destroy]
        namespace :integrations do
          resource :dyte, controller: 'dyte', only: [] do
            collection do
              post :add_participant_to_meeting
            end
          end
        end
      end
    end

    namespace :v2 do
      resources :accounts, only: [:create] do
        scope module: :accounts do
          resources :summary_reports, only: [] do
            collection do
              get :agent
              get :team
              get :inbox
              get :label
            end
          end
          resources :reports, only: [:index] do
            collection do
              get :summary
              get :bot_summary
              get :agents
              get :inboxes
              get :labels
              get :teams
              get :conversations
              get :conversation_traffic
              get :bot_metrics
            end
          end
          resources :live_reports, only: [] do
            collection do
              get :account
              get :inboxes
            end
          end
          resources :csat_survey_responses, only: [] do
            collection do
              get :metrics
              get :download
            end
          end
        end
      end

      resources :accounts, only: [] do
        scope module: :accounts do
          resources :contacts, only: [:index]
          resources :contactable_inboxes, only: [:index]
          resources :conversations, only: [:index] do
            resources :messages, only: [:index]
          end
          resource :profile, only: [:show]
        end
      end
    end
  end

  mount ActionCable.server, at: '/cable'
end
