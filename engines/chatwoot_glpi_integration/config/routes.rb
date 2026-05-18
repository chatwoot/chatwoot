ChatwootGlpiIntegration::Engine.routes.draw do
  namespace :api, defaults: { format: 'json' } do
    namespace :v1 do
      resources :accounts, only: [] do
        scope module: :accounts do
          # Connection (one per account, singular)
          resource  :glpi_connection,  path: 'glpi/connection',
                    only: [:show, :create, :update, :destroy] do
            post :test, on: :collection
          end

          # Ticket links — list / create / sync / unlink
          resources :glpi_ticket_links, path: 'glpi/tickets', only: [:index, :show, :create, :destroy] do
            post :sync, on: :member
            post :reconcile_all, on: :collection
          end
        end
      end
    end
  end

  # Inbound webhook from GLPI — public, signed.
  scope path: 'webhooks/glpi', module: 'webhooks', as: :webhooks_glpi do
    post ':account_id', to: 'glpi_controller#receive', as: :receive
  end
end
