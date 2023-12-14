class Api::V1::Accounts::Conversations::ReplyActionController < Api::V1::Accounts::Conversations::BaseController
  # def show
  #   render json: { action_type: 'default' } and return unless Redis::Alfred.exists?(action_redis_key)

  #   action_type = Redis::Alfred.get(action_redis_key)
  #   render json: { action_type: action_type }
  # end

  def show
    puts ' ---------------- default action show -------------'
    render json: { action_type: 'default_reply_action'}
  end

  # def update
  #   # Redis::Alfred.set(action_redis_key, action_type_params)
  #   puts ' ---------------- default action updated -------------'
  #   head :ok
  # end

  # def destroy
  #   Redis::Alfred.delete(action_redis_key)
  #   head :ok
  # end

  # private

  # def action_redis_key
  #   format(Redis::Alfred::CONVERSATION_DRAFT_MESSAGE, conversation_id: conversation_id, account_id: current_account.id)
  # end

  # def conversation_id
  #   params[:conversation_id]
  # end

  # def action_type_params
  #   params.dig(:reply_action, :type) || ''
  # end
end
