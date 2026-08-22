# frozen_string_literal: true

# Kiraid: unified campaign channel abstraction.
#
# Every connected inbox is, conceptually, a candidate campaign channel. Whether a
# given channel can actually run an outbound campaign depends on the platform
# policy and the send tooling available for it (e.g. WhatsApp needs an approved
# template path, Email reuses the SMTP composer, Telegram/LINE have outbound APIs
# but no campaign strategy wired yet).
#
# This registry is the single source of truth that maps an inbox's `inbox_type`
# (the friendly channel name, e.g. 'Whatsapp', 'Email') to its campaign strategy.
# The Campaign model validates and dispatches entirely through this registry, so
# supporting a new channel later is a one-line addition here plus a service
# object — no model/controller changes.
#
# === REMOVE THIS ABSTRACTION ===
# Delete this file, then in app/models/campaign.rb revert
# `validate_campaign_inbox` and `execute_campaign` to their original
# allow-list + `case inbox.inbox_type` form, and drop the i18n key
# CAMPAIGN.FORM.INBOX.UNSUPPORTED_CHANNEL.
module Campaigns
  class ChannelStrategy
    # Each entry: inbox_type => strategy.
    #   :service    - one-off campaign service class (responds to #perform), or nil
    #   :supported? - whether an outbound one-off campaign can run on this channel
    #   :one_off    - whether this channel is eligible for one_off campaigns
    #                 (vs. only the ongoing/website trigger model)
    REGISTRY = {
      # Website only supports the ongoing (on-page trigger) model, never one_off.
      'Website' => { service: nil, supported?: false, one_off: false, campaignable: true },
      'Twilio SMS' => { service: Twilio::OneoffSmsCampaignService, supported?: true, one_off: true, campaignable: true },
      'Sms' => { service: Sms::OneoffSmsCampaignService, supported?: true, one_off: true, campaignable: true },
      'Whatsapp' => { service: Whatsapp::OneoffCampaignService, supported?: true, one_off: true, campaignable: true },
      'Email' => { service: Email::OneoffCampaignService, supported?: true, one_off: true, campaignable: true },
      # Connected inboxes with no campaign send path yet. They are surfaced in the
      # dashboard as "coming soon" so the channel list stays complete; they cannot
      # be selected for a campaign until a strategy is wired here.
      'Facebook' => { service: nil, supported?: false, one_off: false, campaignable: false },
      'Instagram' => { service: nil, supported?: false, one_off: false, campaignable: false },
      'Twitter' => { service: nil, supported?: false, one_off: false, campaignable: false },
      'Telegram' => { service: nil, supported?: false, one_off: false, campaignable: false },
      'LINE' => { service: nil, supported?: false, one_off: false, campaignable: false },
      'API' => { service: nil, supported?: false, one_off: false, campaignable: false },
      'Tiktok' => { service: nil, supported?: false, one_off: false, campaignable: false },
    }.freeze

    # The set of inbox types that can host a one_off (cold-outreach) campaign.
    # Website is intentionally excluded: it only supports the ongoing trigger model.
    ONE_OFF_INBOX_TYPES = REGISTRY.filter_map { |type, s| type if s[:one_off] }.freeze

    # All inbox types the campaign feature knows about (ongoing + one_off), so the
    # dashboard can list every connected channel even when it has no send path yet.
    CAMPAIGNABLE_INBOX_TYPES = REGISTRY.filter_map { |type, s| type if s[:campaignable] }.freeze

    attr_reader :inbox_type

    def initialize(inbox_type)
      @inbox_type = inbox_type
    end

    def self.for(inbox_type)
      new(inbox_type)
    end

    # A channel is campaignable when the registry knows about it. Unknown
    # inbox types (future channels) are treated as unsupported rather than
    # raising, so the dashboard can still render them as "not supported yet".
    def known?
      REGISTRY.key?(inbox_type)
    end

    def campaignable?
      REGISTRY.dig(inbox_type, :campaignable) || false
    end

    def supported?
      REGISTRY.dig(inbox_type, :supported?) || false
    end

    # Whether a one_off (outbound) campaign may target this channel.
    def one_off?
      REGISTRY.dig(inbox_type, :one_off) || false
    end

    # The service class responsible for running a one_off campaign on this
    # channel, or nil when no send path exists yet.
    def service
      REGISTRY.dig(inbox_type, :service)
    end

    # Instantiate and run the one_off service for the given campaign.
    # Raises CustomExceptions::Campaigns::UnsupportedInboxType when the channel
    # has no send path, so callers fail loudly instead of silently skipping.
    def execute(campaign)
      service_class = service
      raise CustomExceptions::Campaigns::UnsupportedInboxType, inbox_type unless service_class

      service_class.new(campaign: campaign).perform
    end
  end
end
