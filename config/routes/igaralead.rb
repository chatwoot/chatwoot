# frozen_string_literal: true

# IgaraLead-specific routes — kept separate so config/routes.rb stays
# identical (or nearly so) to upstream Chatwoot, reducing merge conflicts.

# Health check (ecosystem-standard)
get 'igaralead/health', to: 'igaralead/health#show'

# IgaraHub webhook
post 'webhooks/hub', to: 'igaralead/webhooks#receive'

# IgaraHub metrics endpoint
get 'igaralead/metrics/:client_slug', to: 'igaralead/metrics#show', as: :igaralead_metrics

# Cross-product integration API (called by Amplex/Entity/Hub)
scope 'igaralead/api', defaults: { format: :json } do
  post 'conversations/find_or_create', to: 'igaralead/integration#find_or_create_conversation'
  post 'messages', to: 'igaralead/integration#send_message'
  post 'contacts/import', to: 'igaralead/integration#import_contacts'
  post 'contacts/enrich', to: 'igaralead/integration#enrich_contact'
end

# Baileys WhatsApp sidecar webhooks
post 'webhooks/baileys/message', to: 'igaralead/baileys_webhooks#message'
post 'webhooks/baileys/status', to: 'igaralead/baileys_webhooks#status_update'
post 'webhooks/baileys/qr', to: 'igaralead/baileys_webhooks#qr_code'
post 'webhooks/baileys/connection', to: 'igaralead/baileys_webhooks#connection_update'
post 'webhooks/baileys/contact', to: 'igaralead/baileys_webhooks#contact_update'
post 'webhooks/baileys/group', to: 'igaralead/baileys_webhooks#group_update'
