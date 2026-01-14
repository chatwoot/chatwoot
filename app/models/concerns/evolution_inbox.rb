# frozen_string_literal: true

# EvolutionInbox
#
# Provides predicates to detect Evolution API (Baileys) WhatsApp inboxes.
# These inboxes use Channel::Api but behave as WhatsApp channels through Evolution.
#
module EvolutionInbox
  extend ActiveSupport::Concern

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
end

