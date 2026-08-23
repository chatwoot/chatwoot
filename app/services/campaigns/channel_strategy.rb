# frozen_string_literal: true

# Kiraid: unified campaign channel abstraction.
#
# Every connected inbox is, conceptually, a candidate campaign channel. Whether a
# given channel can actually run an outbound campaign depends on the platform
# policy and the send tooling available for it (e.g. WhatsApp needs an approved
# template path, Email reuses the SMTP composer, Telegram/LINE have outbound APIs
# but no campaign strategy wired yet).
#
# The channel model owns its own campaign capability via `campaign_definition`
# (`{ supported:, one_off:, campaignable:, service: }`), so this strategy is a
# thin wrapper that asks the channel. Adding a new campaign channel is a change
# to the channel model alone — no edits here, in Campaign, or in controllers.
module Campaigns
  class ChannelStrategy
    attr_reader :inbox

    def initialize(inbox)
      @inbox = inbox
    end

    def self.for(inbox)
      new(inbox)
    end

    # A channel is campaignable when it advertises a campaign definition.
    # Unknown/legacy channels (nil definition) are treated as unsupported rather
    # than raising, so the dashboard can still render them as "not supported yet".
    def known?
      !definition.nil?
    end

    def campaignable?
      definition&.dig(:campaignable) || false
    end

    def supported?
      definition&.dig(:supported) || false
    end

    # Whether a one_off (outbound) campaign may target this channel.
    def one_off?
      definition&.dig(:one_off) || false
    end

    # The service class responsible for running a one_off campaign on this
    # channel, or nil when no send path exists yet.
    def service
      definition&.dig(:service)
    end

    # Instantiate and run the one_off service for the given campaign.
    # Raises CustomExceptions::Campaigns::UnsupportedInboxType when the channel
    # has no send path, so callers fail loudly instead of silently skipping.
    def execute(campaign)
      service_class = service
      raise CustomExceptions::Campaigns::UnsupportedInboxType, inbox.inbox_type unless service_class

      service_class.new(campaign: campaign).perform
    end

    private

    def definition
      inbox.channel.campaign_definition
    end
  end
end
