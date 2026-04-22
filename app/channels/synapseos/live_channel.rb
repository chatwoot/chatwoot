module Synapseos
  # Real-time channel for the C-Level Dashboard. Clients subscribe using
  # `pubsub_token` + `account_id` (mirror of RoomChannel's auth). Only
  # administrators of the account are allowed to stream events.
  #
  # Broadcast stream name: `synapseos_live_<account_id>`.
  #
  # Event shapes (broadcast by SynapseosListener):
  #   { type: 'agent_activity',    agent_slug:, action:, conversation_id:, at: }
  #   { type: 'label_event',       conversation_id:, label:, at: }
  #   { type: 'deal_stage_changed', deal_id:, from:, to:, at: }
  class LiveChannel < ApplicationCable::Channel
    def subscribed
      return reject unless account && authorized_user?

      stream_from self.class.stream_name_for(account.id)
    end

    def self.stream_name_for(account_id)
      "synapseos_live_#{account_id}"
    end

    def self.broadcast(account_id, payload)
      ActionCable.server.broadcast(stream_name_for(account_id), payload)
    end

    private

    def account
      @account ||= Account.find_by(id: params[:account_id])
    end

    def current_user
      @current_user ||= User.find_by(pubsub_token: params[:pubsub_token])
    end

    def authorized_user?
      return false if current_user.blank?

      account_user = account.account_users.find_by(user_id: current_user.id)
      account_user&.administrator?
    end
  end
end
