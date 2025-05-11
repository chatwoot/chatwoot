class CopilotChannel < ApplicationCable::Channel
  def subscribed
    current_user
    current_account
    ensure_stream
  end

  def message(data)
    return if @current_account.blank?

    Captain::ProcessCopilotMessageJob.perform_later(
      assistant_id: data['assistant_id'],
      message: data['message'],
      options: {
        user_id: @current_user.id,
        conversation_id: data['conversation_id'],
        previous_history: data['previous_history']
      }
    )
  end

  def ensure_stream
    stream_from "copilot_#{@current_account.id}_#{@current_user.id}"
  end

  def current_user
    @current_user ||= User.find(params[:user_id])
  end

  def current_account
    return if current_user.blank?

    @current_account ||= @current_user.accounts.find(params[:account_id])
  end
end
