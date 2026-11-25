module Whatsapp::BaileysHandlers::MessageCappingUpdate
  private

  # New-chat message cap (quota) snapshot pushed by the provider. Persisted on provider_connection
  # so the dashboard can warn before the account hits its new-conversation limit, mirroring the
  # reach-out banner. The payload carries no lease epoch; update_new_chat_cap! merges under a row
  # lock so it can't clobber a concurrent connection.update.
  def process_message_capping_update
    inbox.channel.update_new_chat_cap!(processed_params[:data])
  end
end
