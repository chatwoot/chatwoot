# frozen_string_literal: true
module Campaigns
  class ExecuteJob < ApplicationJob
    queue_as :default
    # keep requested_by_id available for auditing later; mark as unused so Rubocop is happy
    def perform(account_id:, campaign_id:, requested_by_id: nil) # rubocop:disable Lint/UnusedMethodArgument
      campaign = Campaign.find_by(id: campaign_id, account_id: account_id)
      return unless campaign

      campaign.trigger! # delegates to Twilio/Sms/Whatsapp services per your model
    end
  end
end
