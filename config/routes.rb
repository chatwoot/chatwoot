# frozen_string_literal: true

Rails.application.routes.draw do
  # Health check
  get '/health', to: 'health#show'

  # Dashboard / internal UI
  root to: 'dashboard#index'

  # Devise routes for authentication
  devise_for :users, controllers: {
    registrations: 'devise_overrides/registrations',
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  devise_scope :user do
    post '/users/confirmation', to: 'devise_overrides/confirmations#create', as: :user_confirmation
  end

  # Mount Sidekiq dashboard in development/production (optional)
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  # API routes
  namespace :api do
    namespace :v1 do
      resources :accounts, param: :id do
        # Contacts
        resources :contacts do
          member do
            post :merge
          end
          resources :notes
          resources :conversations, only: [:index]
        end

        # Conversations
        resources :conversations do
          member do
            post :assign_agent
            post :toggle_status
            post :mute
            post :unmute
            post :transcript
          end
          resources :messages
        end

        # Inboxes
        resources :inboxes do
          resources :contacts, only: [:index]
        end

        # Campaigns
        resources :campaigns, only: [:index, :create, :show, :update, :destroy] do
          member do
            post :execute   # 👈 your custom member route
          end
        end

        # Agents / Users
        resources :agents, only: [:index, :create, :update, :destroy]
        resources :team_members, only: [:index, :create, :update, :destroy]

        # Other account-scoped resources
        resources :labels, only: [:index, :create, :update, :destroy]
        resources :teams, only: [:index, :create, :show, :update, :destroy]
        resources :webhooks, only: [:index, :create, :update, :destroy]
        resources :canned_responses, only: [:index, :create, :update, :destroy]

        # Settings
        resource :settings, only: [:show, :update]
      end
    end
  end

  # Fallback for SPA routes (Vue dashboard)
  get '*path', to: 'dashboard#index', constraints: ->(req) { !req.xhr? && req.format.html? }
end
