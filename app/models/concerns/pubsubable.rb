# frozen_string_literal: true

module Pubsubable
  extend ActiveSupport::Concern

  included do
    # Used by the actionCable/PubSub Service we use for real time communications
    has_secure_token :pubsub_token
  end
end
