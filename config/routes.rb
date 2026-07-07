Rails.application.routes.draw do
  get '/auth/autonomia', to: 'autonomia/auth#start'
  get '/auth/autonomia/callback', to: 'autonomia/auth#callback'
  get '/app/auth/callback', to: 'autonomia/auth#callback'
  get '/register/callback', to: 'autonomia/registration_callbacks#show'

  # AUTH STARTS
  mount_devise_token_auth_for 'User', at: 'auth', controllers: {
    confirmations: 'devise_overrides/confirmations',
    passwords: 'devise_overrides/passwords',
    sessions: 'devise_overrides/sessions',
    token_validations: 'devise_overrides/token_validations',
    omniauth_callbacks: 'devise_overrides/omniauth_callbacks'
  }, via: [:get, :post]

  post 'resend_confirmation', to: 'auth/resend_confirmations#create'

  ## renders the frontend paths only if its not an api only server
  if ActiveModel::Type::Boolean.new.cast(ENV.fetch('CW_API_ONLY_SERVER', false))
    root to: 'api#index'
  else
    root to: 'dashboard#index'

    get '/accept-invitation', to: 'dashboard#index'
    get '/login', to: redirect('/auth/autonomia?prompt=login')
    get '/app', to: 'dashboard#index'
    get '/app/*params', to: 'dashboard#index'
    get '/app/accounts/:account_id/settings/inboxes/new/twitter', to: 'dashboard#index', as: 'app_new_twitter_inbox'
    get '/app/accounts/:account_id/settings/inboxes/new/microsoft', to: 'dashboard#index', as: 'app_new_microsoft_inbox'
    get '/app/accounts/:account_id/settings/inboxes/new/instagram', to: 'dashboard#index', as: 'app_new_instagram_inbox'
    get '/app/accounts/:account_id/settings/inboxes/new/tiktok', to: 'dashboard#index', as: 'app_new_tiktok_inbox'
    get '/app/accounts/:account_id/settings/inboxes/new/:inbox_id/agents', to: 'dashboard#index', as: 'app_twitter_inbox_agents'
    get '/app/accounts/:account_id/settings/inboxes/new/:inbox_id/agents', to: 'dashboard#index', as: 'app_email_inbox_agents'
    get '/app/accounts/:account_id/settings/inboxes/new/:inbox_id/agents', to: 'dashboard#index', as: 'app_instagram_inbox_agents'
    get '/app/accounts/:account_id/settings/inboxes/new/:inbox_id/agents', to: 'dashboard#index', as: 'app_tiktok_inbox_agents'
    get '/app/accounts/:account_id/settings/inboxes/:inbox_id', to: 'dashboard#index', as: 'app_instagram_inbox_settings'
    get '/app/accounts/:account_id/settings/inboxes/:inbox_id', to: 'dashboard#index', as: 'app_tiktok_inbox_settings'
    get '/app/accounts/:account_id/settings/inboxes/:inbox_id', to: 'dashboard#index', as: 'app_email_inbox_settings'
    get '/app/accounts/:account_id/onboarding/inbox-setup', to: 'dashboard#index', as: 'app_onboarding_inbox_setup'

    resource :widget, only: [:show]
    namespace :survey do
      resources :responses, only: [:show]
    end
    resource :slack_uploads, only: [:show]

    # Public, unauthenticated Calendly-style booking page (CRM S6). The opaque
    # slug is the only identifier; the Vue app fetches data over the
    # Public::Api::V1 JSON endpoints below. The /confirm variant renders the same
    # page; the Vue app detects the /confirm path + token query and confirms the
    # email-verified booking.
    get '/book/:slug', to: 'public_booking/pages#show', as: :public_booking_page
    get '/book/:slug/confirm', to: 'public_booking/pages#show', as: :public_booking_confirm_page
  end

  get '/health', to: 'health#show'
  get '/api', to: 'api#index'
  get '/api/v1/autonomia/product-invitations/validate', to: 'public/api/v1/autonomia/product_invitations#validate'
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
          resource :onboarding, only: [:update] do
            get :help_center_generation
          end
          resources :agents, only: [:index, :create, :update, :destroy] do
            post :bulk_create, on: :collection
          end
          namespace :captain do
            resource :preferences, only: [:show, :update]
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
            resources :custom_tools do
              post :test, on: :collection
            end
            resources :documents, only: [:index, :show, :create, :destroy] do
              post :sync, on: :member
            end
            resource :tasks, only: [], controller: 'tasks' do
              post :rewrite
              post :summarize
              post :reply_suggestion
              post :label_suggestion
              post :follow_up
            end
          end
          resource :saml_settings, only: [:show, :create, :update, :destroy]
          resources :agent_bots, only: [:index, :create, :show, :update, :destroy] do
            delete :avatar, on: :member
            post :reset_access_token, on: :member
            post :reset_secret, on: :member
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
          resources :whatsapp_api_campaigns, only: [:index, :create, :show] do
            member do
              post :pause
              post :resume
              post :cancel
            end
          end
          resources :campaign_imports, only: [:index, :create, :show, :destroy] do
            member do
              post :confirm
              post :undo_labels
              get :download
            end
          end
          namespace :crm do
            resources :pipelines, only: [:index, :create, :show, :update, :destroy] do
              resources :stages, only: [:index, :create]
              resources :inboxes, controller: 'pipeline_inboxes', only: [:index, :create, :destroy], param: :inbox_id
              resource :ai_settings, only: [:show, :update], controller: 'ai_settings'
            end
            resources :stages, only: [:update, :destroy] do
              post :reorder, on: :collection
              resources :stage_automations, only: [:index, :create]
            end
            resources :stage_automations, only: [:show, :update, :destroy] do
              resources :steps, controller: 'stage_automation_steps', only: [:create, :update, :destroy]
            end
            post 'cards/bulk', to: 'cards/bulk#create'
            get 'cards/summaries', to: 'cards/summaries#index'
            resources :cards, only: [:index, :create, :show, :update, :destroy] do
              post :from_conversation, on: :collection
              member do
                post :move
                post :close
                post :link_conversation
                post :unlink_conversation
                post :link_contact
                post :unlink_contact
                get :current_ai_suggestion
                post :evaluate_ai
                post :summarize
                post :reset_auto_followup
              end
            end
            resources :ai_suggestions, only: [] do
              member do
                post :accept
                post :dismiss
              end
            end
            resources :follow_ups, only: [:index, :create, :show, :update, :destroy] do
              collection do
                get :messaging_window
                get :reminders
              end
              member do
                post :complete
                post :cancel
                post :dismiss_reminder
                post :reschedule
              end
            end
            resources :meetings, only: [:index, :create, :show, :update, :destroy] do
              member do
                post :sync
                post :record_outcome
                post :summarize
              end
              collection do
                post :suggest_times
                post :draft_invite
              end
            end
            resources :service_schedules, only: [:index, :create, :update, :destroy]
            get 'conversations/card_stages', to: 'cards#card_stages'
            get 'conversations/:conversation_id/card', to: 'cards#by_conversation'
            get :kanban, to: 'kanban#index'
            scope :reports, controller: :reports do
              get :pipelines, action: :pipelines, as: :crm_report_pipelines
              get :summary, action: :summary, as: :crm_report_summary
              get :funnel, action: :funnel, as: :crm_report_funnel
              get :ai_vs_human, action: :ai_vs_human, as: :crm_report_ai_vs_human
              get :throughput, action: :throughput, as: :crm_report_throughput
              get :follow_ups, action: :follow_ups, as: :crm_report_follow_ups
              get :workload, action: :workload, as: :crm_report_workload
              get :meetings, action: :meetings, as: :crm_report_meetings
            end
            scope :ai_usage, controller: :ai_usage do
              get '/', action: :index
              get :export
            end
            get 'calendar/events', to: 'calendar#events'
            get 'calendar/available_slots', to: 'calendar#available_slots'
            get :inbox_settings, to: 'inbox_settings#index'
            patch 'inbox_settings/:inbox_id', to: 'inbox_settings#update'
            resources :integration_tokens, only: [:index, :create, :destroy] do
              member do
                post :rotate
              end
            end
            resources :saved_views, only: [:index, :create, :update, :destroy]
            resources :booking_profiles, only: [:index, :create, :update, :destroy] do
              member do
                get :agent_links
                post :agent_links, action: :upsert_agent_link
                delete 'agent_links/:link_id', action: :destroy_agent_link
              end
            end
          end
          namespace :autonomia do
            resources :agents, only: [:index, :show, :create, :update, :destroy] do
              member do
                post :test,    to: 'agents/playground#test'
                post :suggest, to: 'agents/playground#suggest'
                get  :analytics, to: 'agents/analytics#index'   # Fase F
                patch :avatar
                delete :avatar
              end
              resources :sources, only: [:index, :create, :destroy], controller: 'agents/sources' do
                member { post :resync }
              end
              resources :channels, only: [:index, :create, :destroy],
                                   controller: 'agents/channels', param: :inbox_id
              # G2 — histórico de versões da instrução + rollback atômico.
              resources :instruction_versions, only: [:index], controller: 'agents/instruction_versions'
              post 'instruction_versions/:version_id/restore',
                   to: 'agents/instruction_versions#restore'
            end
            resources :build_threads, only: [:create, :show], controller: 'agents/build_threads' do
              member do
                post :messages
                # E2 — reexecuta a geração de uma thread failed/presa (novo build_token + SubmitJob).
                # Action retry_build porque `retry` é palavra reservada do Ruby.
                post :retry, action: :retry_build
              end
            end
            # MULTIMODAL (Construtor/Ajustar): upload de imagem do builder (image-only, retorna signed_id;
            # não cria conhecimento). O turno referencia o signed_id; o Builder a lê inline no job.
            post 'builder_images', to: 'agents/builder_images#create'
            # Agent-facing copilot for a live conversation (V1, gated by the kanban key).
            post 'conversations/:conversation_id/copilot', to: 'conversation_copilot#create'
            # Guia da Plataforma — onboarding/suporte read-only, global/auto-on por conta elegível.
            post 'guide/chat', to: 'guide#chat'
            resource :invite_connection, only: [:show] do
              get ':inbox_id/connection', action: :connection
              post ':inbox_id/reconnect', action: :reconnect
            end
            # V2.3 — "Copiloto Autonom.ia" chat widget: list selectable internal/both agents + chat.
            get  'conversations/:conversation_id/copilot/agents', to: 'conversation_copilot#agents'
            post 'conversations/:conversation_id/copilot/chat',   to: 'conversation_copilot#chat'
            scope :financial, controller: :financial do
              get :subscription
              get :billing_preview
              get :invoices
              get :payments
            end
            namespace :prospecting do
              resources :searches, only: [:index, :show, :create, :update, :destroy] do
                get :location_suggestions, on: :collection
                get :location_details, on: :collection
              end
              resources :leads, only: [:index, :show, :update] do
                post :contact, on: :member, action: :create_contact
                post :crm_card, on: :member, action: :create_crm_card
              end
              resources :lists, only: [:index, :show, :create] do
                post 'leads', on: :member, action: :add_lead
                delete 'leads/:lead_id', on: :member, action: :remove_lead
                post :campaign_segment, on: :member
              end
              resource :settings, only: [:show, :update]
            end
          end
          namespace :email_campaigns do
            resources :sender_identities, only: [:index, :create, :show, :destroy] do
              member do
                post :verify
                post :dns_check
              end
            end
            resources :campaigns, only: [:index, :create, :show, :update, :destroy] do
              member do
                post :send_now
                post :schedule
                post :pause
                post :resume
                post :cancel
                post :duplicate
                post :resolve_video, to: 'videos#resolve'
              end
              resources :recipients, only: [:index, :create]
            end
            get  'campaigns/:id/placeholders', to: 'template_tools#placeholders'
            get  'campaigns/:id/validate',     to: 'template_tools#validate'
            post 'campaigns/:id/test_send',    to: 'test_sends#create'
            post 'campaigns/:id/assets',       to: 'assets#create'
            post 'ai/generate',                to: 'ai#generate'
            post 'ai/rewrite',                 to: 'ai#rewrite'
            get  'ai/campaigns/:id/status',    to: 'ai#status'
            resources :templates, only: [:index, :show, :create, :destroy]
            resources :reports, only: [:index, :show] do
              member do
                get :clicks
                get :timeline
                get :recipients
                get :export
              end
            end
          end
          resources :dashboard_apps, only: [:index, :show, :create, :update, :destroy]
          namespace :channels do
            resource :twilio_channel, only: [:create]
          end
          resources :conversations, only: [:index, :create, :show, :update, :destroy] do
            collection do
              get :meta
              get :search
              get :unread_counts, to: 'conversations/unread_counts#index'
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
              get :reporting_events if ChatwootApp.enterprise?
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

          resources :companies, only: [:index, :show, :create, :update, :destroy] do
            collection do
              get :search
            end
            member do
              post :destroy_custom_attributes
              delete :avatar
            end
            scope module: :companies do
              resources :contacts, only: [:index, :create, :destroy] do
                collection do
                  get :search
                end
              end
              resources :conversations, only: [:index]
              resources :notes, only: [:index]
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
              get :attachments, to: 'attachments#index'
              post :call, on: :member, to: 'calls#create' if ChatwootApp.enterprise?
            end
          end
          resources :csat_survey_responses, only: [:index] do
            collection do
              get :metrics
              get :download
            end
            member do
              patch :update if ChatwootApp.enterprise?
            end
          end
          resources :applied_slas, only: [:index] do
            collection do
              get :metrics
              get :download
            end
          end
          resources :reporting_events, only: [:index] if ChatwootApp.enterprise?

          if ChatwootApp.enterprise?
            resources :whatsapp_calls, only: [:show] do
              member do
                post :accept
                post :reject
                post :terminate
                post :upload_recording
              end
              collection do
                post :initiate
              end
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
            get :health, on: :member
            post :register_webhook, on: :member
            post :reset_secret, on: :member
            post :enable_whatsapp_api_campaigns, on: :member
            delete :disable_whatsapp_api_campaigns, on: :member
            resources :whatsapp_api_message_templates, only: [:index, :create, :update, :destroy]
            if ChatwootApp.enterprise?
              resource :conference, only: %i[create destroy], controller: 'conference' do
                get :token, on: :member
              end
              post :enable_whatsapp_calling, on: :member
              post :disable_whatsapp_calling, on: :member
              post :set_inbound_calls, on: :member
            end

            resource :csat_template, only: [:show, :create], controller: 'inbox_csat_templates' do
              post :analyze, on: :collection
            end
          end

          resources :inbox_members, only: [:create, :show], param: :inbox_id do
            collection do
              delete :destroy
              patch :update
            end
          end
          resources :waha_inboxes, only: [:create], param: :inbox_id do
            member do
              get :connection
              post :reconnect
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

          # Cadastro POR CONTA das credenciais do app OAuth de e-mail (Azure/Google).
          resources :email_oauth_apps, only: [:show, :update, :destroy], param: :provider


          namespace :instagram do
            resource :authorization, only: [:create]
          end

          namespace :tiktok do
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
          resources :portals do
            member do
              patch :archive
              delete :logo
              post :send_instructions
              get :ssl_status
            end
            resources :categories do
              post :reorder, on: :collection
            end
            namespace :articles do
              resource :bulk_actions, only: [] do
                post :translate
                patch :update_status
                patch :update_category
                delete :delete_articles
              end
            end
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

      # Frontend API endpoint to trigger SAML authentication flow
      post 'auth/saml_login', to: 'auth#saml_login'

      resource :profile, only: [:show, :update] do
        delete :avatar, on: :collection
        member do
          post :availability
          post :auto_offline
          put :set_active_account
          post :resend_confirmation
          post :reset_access_token
        end

        # MFA routes
        scope module: 'profile' do
          resource :mfa, controller: 'mfa', only: [:show, :create, :destroy] do
            post :verify
            post :backup_codes
          end
          resources :sessions, only: [:index, :destroy]
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
              get :channel
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
              get :conversations_summary
              get :conversation_traffic
              get :bot_metrics
              get :inbox_label_matrix
              get :first_response_time_distribution
              get :outgoing_messages_count
            end
          end
          resource :year_in_review, only: [:show]
          resources :live_reports, only: [] do
            collection do
              get :conversation_metrics
              get :grouped_conversation_metrics
            end
          end
        end
      end
    end
  end

  if ChatwootApp.enterprise?
    namespace :enterprise, defaults: { format: 'json' } do
      namespace :api do
        namespace :v1 do
          resources :accounts do
            member do
              post :checkout
              post :subscription
              get :limits
              post :toggle_deletion
              post :topup_checkout
            end
          end
        end
      end

      post 'webhooks/stripe', to: 'webhooks/stripe#process_payload'
      post 'webhooks/firecrawl', to: 'webhooks/firecrawl#process_payload'
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
            post :token
          end
        end
        resources :agent_bots, only: [:index, :create, :show, :update, :destroy] do
          delete :avatar, on: :member
        end
        resources :accounts, only: [:index, :create, :show, :update, :destroy] do
          resources :account_users, only: [:index, :create] do
            collection do
              delete :destroy
            end
          end
          resources :email_channel_migrations, only: [:create]
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
              resources :conversations, only: [:index, :create, :show] do
                member do
                  post :toggle_status
                  post :toggle_typing
                  post :update_last_seen
                end

                resources :messages, only: [:index, :create, :update]
              end
            end
          end
        end

        resources :csat_survey, only: [:show, :update]

        # Public booking (CRM S6) — unauthenticated. Authorized purely by the
        # opaque slug. slots=availability (declared first, more specific),
        # show=profile, create=book.
        get 'booking/:slug/slots', to: 'booking#slots'
        post 'booking/:slug/confirm', to: 'booking#confirm'
        get 'booking/:slug', to: 'booking#show'
        post 'booking/:slug', to: 'booking#create'
      end
    end
  end

  get 'hc/:slug', to: 'public/api/v1/portals#show'
  get 'hc/:slug/sitemap.xml', to: 'public/api/v1/portals#sitemap'
  get 'hc/:slug/:locale', to: 'public/api/v1/portals#show', as: :public_portal_locale
  get 'hc/:slug/:locale/search', to: 'public/api/v1/portals/search#index', as: :portal_search
  get 'hc/:slug/:locale/articles', to: 'public/api/v1/portals/articles#index'
  get 'hc/:slug/:locale/categories', to: 'public/api/v1/portals/categories#index'
  get 'hc/:slug/:locale/categories/:category_slug', to: 'public/api/v1/portals/categories#show', as: :public_portal_category
  get 'hc/:slug/:locale/categories/:category_slug/articles', to: 'public/api/v1/portals/articles#index'
  get 'hc/:slug/articles/:article_slug.png', to: 'public/api/v1/portals/articles#tracking_pixel'
  get 'hc/:slug/articles/:article_slug.md', to: 'public/api/v1/portals/articles#show_markdown', as: :public_portal_article_markdown,
                                            defaults: { format: :md }
  get 'hc/:slug/articles/:article_slug', to: 'public/api/v1/portals/articles#show', as: :public_portal_article

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
  # CRM 2-way calendar sync (S7-B) push receivers.
  post 'webhooks/crm_calendar/google', to: 'webhooks/crm_calendar#google'
  post 'webhooks/crm_calendar/microsoft', to: 'webhooks/crm_calendar#microsoft'
  post 'webhooks/line/:line_channel_id', to: 'webhooks/line#process_payload'
  post 'webhooks/telegram/:bot_token', to: 'webhooks/telegram#process_payload'
  post 'webhooks/sms/:phone_number', to: 'webhooks/sms#process_payload'
  get 'webhooks/whatsapp/:phone_number', to: 'webhooks/whatsapp#verify'
  post 'webhooks/whatsapp/:phone_number', to: 'webhooks/whatsapp#process_payload'
  get 'webhooks/instagram', to: 'webhooks/instagram#verify'
  post 'webhooks/instagram', to: 'webhooks/instagram#events'
  post 'webhooks/tiktok', to: 'webhooks/tiktok#events'
  post 'webhooks/shopify', to: 'webhooks/shopify#events'

  # ----------------------------------------------------------------------
  # Email Campaign (Onda 3) PUBLIC endpoints — signed-token / SNS-signature protected; feature-gated
  # inside the controllers (EmailCampaigns::Config.enabled?). NOT behind the authenticated api scope.
  get 'email_campaigns/t/o/:token', to: 'email_campaigns/tracking#open', defaults: { format: 'gif' }, as: :email_campaign_track_open
  get 'email_campaigns/t/c/:token', to: 'email_campaigns/tracking#click', as: :email_campaign_track_click
  post 'email_campaigns/sns', to: 'email_campaigns/sns#create', as: :email_campaign_sns
  get 'email_campaigns/u/:token', to: 'email_campaigns/unsubscribe#show', as: :email_campaign_unsubscribe
  post 'email_campaigns/u/:token', to: 'email_campaigns/unsubscribe#create'

  namespace :twitter do
    resource :callback, only: [:show]
  end

  namespace :linear do
    resource :callback, only: [:show]
  end

  namespace :shopify do
    resource :callback, only: [:show]
  end

  namespace :twilio do
    resources :callback, only: [:create]
    resources :delivery_status, only: [:create]

    if ChatwootApp.enterprise?
      post 'voice/call/:phone', to: 'voice#call_twiml', as: :voice_call
      post 'voice/status/:phone', to: 'voice#status', as: :voice_status
      post 'voice/conference_status/:phone', to: 'voice#conference_status', as: :voice_conference_status
      post 'voice/recording_status/:phone', to: 'voice#recording_status', as: :voice_recording_status
    end
  end

  get 'microsoft/callback', to: 'microsoft/callbacks#show'
  get 'google/callback', to: 'google/callbacks#show'
  get 'instagram/callback', to: 'instagram/callbacks#show'
  get 'tiktok/callback', to: 'tiktok/callbacks#show'
  get 'notion/callback', to: 'notion/callbacks#show'
  # ----------------------------------------------------------------------
  # Routes for external service verifications
  get '.well-known/assetlinks.json' => 'android_app#assetlinks'
  get '.well-known/apple-app-site-association' => 'apple_app#site_association'
  get '.well-known/microsoft-identity-association.json' => 'microsoft#identity_association'
  get '.well-known/cf-custom-hostname-challenge/:id', to: 'custom_domains#verify'

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
      resource :push_diagnostics, only: [:show, :create] do
        post :destroy_subscriptions, on: :collection
      end

      # order of resources affect the order of sidebar navigation in super admin
      resources :accounts, only: [:index, :new, :create, :show, :edit, :update, :destroy] do
        post :seed, on: :member
        post :reset_cache, on: :member
        post :toggle_prospecting, on: :member
      end
      resources :users, only: [:index, :new, :create, :show, :edit, :update, :destroy] do
        delete :avatar, on: :member, action: :destroy_avatar
      end

      resources :access_tokens, only: [:index, :show]
      resources :installation_configs, only: [:index, :new, :create, :show, :edit, :update]
      resources :agent_bots, only: [:index, :new, :create, :show, :edit, :update, :destroy] do
        delete :avatar, on: :member, action: :destroy_avatar
      end
      resources :platform_apps, only: [:index, :new, :create, :show, :edit, :update, :destroy]
      resources :platform_banners
      resource :instance_status, only: [:show]

      resource :settings, only: [:show] do
        get :refresh, on: :collection
      end

      # resources that doesn't appear in primary navigation in super admin
      resources :account_users, only: [:new, :create, :show, :destroy]
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
