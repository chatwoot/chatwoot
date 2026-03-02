# frozen_string_literal: true

# ActionCable channel for streaming LLM responses to the frontend via SSE.
#
# Client subscribes with:
#   { channel: "LlmChannel", pubsub_token: "...", account_id: 123 }
#
# Server broadcasts events:
#   { event: "llm.chunk",    data: { request_id: "...", delta: "..." } }
#   { event: "llm.complete", data: { request_id: "...", usage: { ... } } }
#   { event: "llm.error",    data: { request_id: "...", error: "..." } }
#
class LlmChannel < ApplicationCable::Channel
  def subscribed
    @account = Account.find_by(id: params[:account_id])
    reject unless @account && authorized?

    stream_from llm_stream_key
  end

  def unsubscribed
    stop_all_streams
  end

  # Broadcast helpers — called from LlmStreamJob or services
  class << self
    def broadcast_chunk(account_id:, request_id:, delta:)
      ActionCable.server.broadcast(
        stream_key(account_id),
        { event: 'llm.chunk', data: { request_id: request_id, delta: delta } }
      )
    end

    def broadcast_complete(account_id:, request_id:, usage: {})
      ActionCable.server.broadcast(
        stream_key(account_id),
        { event: 'llm.complete', data: { request_id: request_id, usage: usage } }
      )
    end

    def broadcast_error(account_id:, request_id:, error:)
      ActionCable.server.broadcast(
        stream_key(account_id),
        { event: 'llm.error', data: { request_id: request_id, error: error } }
      )
    end

    def stream_key(account_id)
      "llm_stream_account_#{account_id}"
    end
  end

  private

  def llm_stream_key
    self.class.stream_key(@account.id)
  end

  def authorized?
    return false unless @current_user.is_a?(User)

    @current_user.account_ids.include?(@account.id)
  end

  def current_user
    @current_user ||= User.find_by!(pubsub_token: params[:pubsub_token])
  rescue ActiveRecord::RecordNotFound
    reject
  end
end
