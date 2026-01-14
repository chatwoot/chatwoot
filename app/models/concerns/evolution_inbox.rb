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
