class Api::V1::Accounts::Conversations::DraftMessagesController < Api::V1::Accounts::Conversations::BaseController
  def show
    render json: { has_draft: false } and return unless Redis::Alfred.exists?(draft_redis_key)

    draft_message = Redis::Alfred.get(draft_redis_key)
    render json: { has_draft: true, message: draft_message }
  end

  def update
    Redis::Alfred.set(draft_redis_key, draft_message_params)
    head :ok
  end

  def destroy
    Redis::Alfred.delete(draft_redis_key)
    head :ok
  end

  private

  def draft_redis_key
    format(Redis::Alfred::CONVERSATION_DRAFT_MESSAGE, id: @conversation.id)
  end

  def draft_message_params
    params.dig(:draft_message, :message) || ''
  end
end
