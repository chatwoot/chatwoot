# frozen_string_literal: true

# EvolutionInbox
#
# Provides predicates to detect Evolution API (Baileys) WhatsApp inboxes.
# These inboxes use Channel::Api but behave as WhatsApp channels through Evolution.
#
module EvolutionInbox
  extend ActiveSupport::Concern

  included do
    before_destroy :delete_evolution_instance, if: :evolution_inbox?
    after_update :sync_evolution_inbox_name, if: :should_sync_evolution_name?
  end

  # Returns true if this inbox is backed by Evolution API (Baileys)
  def evolution_inbox?
    return false unless api?
    return false unless channel.respond_to?(:additional_attributes)

    channel.additional_attributes&.dig('evolution_instance_name').present?
  end

  # Alias for clarity
  def evolution_baileys?
    return false unless evolution_inbox?

    channel.additional_attributes&.dig('evolution_channel') == 'baileys'
  end

  # Returns the Evolution instance name for this inbox
  def evolution_instance_name
    return nil unless evolution_inbox?

    channel.additional_attributes&.dig('evolution_instance_name')
  end

  private

  # Checks if we need to sync the inbox name to Evolution
  def should_sync_evolution_name?
    evolution_inbox? && saved_change_to_name?
  end

  # Syncs the inbox name to Evolution's Chatwoot integration settings
  # This is called after the inbox name is updated in Chatwoot
  def sync_evolution_inbox_name
    instance_name = evolution_instance_name
    return if instance_name.blank?

    Rails.logger.info("[Evolution] Syncing inbox name '#{name}' to instance #{instance_name}")

    client = EvolutionApi::Client.new
    current_settings = client.find_chatwoot_integration(instance_name: instance_name)
    client.set_chatwoot_integration(
      instance_name: instance_name,
      chatwoot_config: build_chatwoot_config_with_new_name(current_settings)
    )

    Rails.logger.info('[Evolution] Successfully synced inbox name to Evolution')
  rescue EvolutionApi::Client::ApiError => e
    Rails.logger.warn("[Evolution] Failed to sync inbox name to Evolution: #{e.message}")
  rescue StandardError => e
    Rails.logger.error("[Evolution] Unexpected error syncing inbox name: #{e.message}")
  end

  # Builds chatwoot config preserving existing settings but updating name_inbox
  def build_chatwoot_config_with_new_name(settings)
    {
      account_id: settings['accountId'],
      token: settings['token'],
      url: settings['url'],
      sign_msg: settings['signMsg'] != false,
      sign_delimiter: settings['signDelimiter'] || "\n",
      reopen_conversation: settings['reopenConversation'] != false,
      conversation_pending: settings['conversationPending'] == true,
      name_inbox: name,
      merge_brazil_contacts: settings['mergeBrazilContacts'] != false,
      import_contacts: settings['importContacts'] != false,
      import_messages: settings['importMessages'] != false,
      days_limit_import_messages: settings['daysLimitImportMessages'] || 3,
      auto_create: settings['autoCreate'] != false
    }
  end

  # Deletes the Evolution instance when the inbox is destroyed
  # This ensures we don't leave orphan instances in Evolution API
  def delete_evolution_instance
    instance_name = evolution_instance_name
    return if instance_name.blank?

    Rails.logger.info("Deleting Evolution instance #{instance_name} for inbox #{id}")

    client = EvolutionApi::Client.new
    client.delete_instance(instance_name: instance_name)

    Rails.logger.info("Successfully deleted Evolution instance #{instance_name}")
  rescue EvolutionApi::Client::ApiError => e
    # Log the error but don't prevent inbox deletion
    # The instance may already be deleted or Evolution may be unreachable
    Rails.logger.warn("Failed to delete Evolution instance #{instance_name}: #{e.message}")
  rescue StandardError => e
    Rails.logger.error("Unexpected error deleting Evolution instance #{instance_name}: #{e.message}")
  end
end
