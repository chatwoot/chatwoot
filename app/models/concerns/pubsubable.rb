# frozen_string_literal: true

module Pubsubable
  extend ActiveSupport::Concern

  included do
    # Used by the actionCable/PubSub Service we use for real time communications
    has_secure_token :pubsub_token
  end

  def pubsub_token
    # backfills tokens for existing records
    regenerate_pubsub_token if self[:pubsub_token].blank?
    self[:pubsub_token]
  end
end
