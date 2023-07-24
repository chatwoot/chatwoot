# frozen_string_literal: true

module Pubsubable
  extend ActiveSupport::Concern

  included do
    # Used by the actionCable/PubSub Service we use for real time communications
    has_secure_token :pubsub_token
    before_save :rotate_pubsub_token
  end

  def rotate_pubsub_token
    # ATM we are only rotating the token if the user is changing their password
    return unless is_a?(User)

    # Using the class method to avoid the extra Save
    # TODO: Should we do this on signin ?
    self.pubsub_token = self.class.generate_unique_secure_token if will_save_change_to_encrypted_password?
  end

  def pubsub_token
    # backfills tokens for existing records
    regenerate_pubsub_token if self[:pubsub_token].blank? && persisted?
    self[:pubsub_token]
  end
end
