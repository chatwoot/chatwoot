# frozen_string_literal: true

# Run with:
#   bundle exec rake chatwoot:message_reactions:resubscribe_webhooks

namespace :chatwoot do
  namespace :message_reactions do
    desc 'Re-subscribe provider webhooks required for incoming message reactions'
    task resubscribe_webhooks: :environment do
      Migration::ResubscribeMessageReactionWebhooksJob.perform_now
    end
  end
end
