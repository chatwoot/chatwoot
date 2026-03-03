class Api::V1::Accounts::NautoAssistant::TasksController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def rewrite
    payload = {
      account_id: Current.account.id,
      operation: params[:operation],
      content: params[:content],
      conversation_display_id: params[:conversation_display_id]
    }
    render_result(call_nauto_assistant('rewrite', payload))
  end

  def summarize
    payload = {
      account_id: Current.account.id,
      conversation_display_id: params[:conversation_display_id]
    }
    render_result(call_nauto_assistant('summarize', payload))
  end

  def reply_suggestion
    conversation = Current.account.conversations.find_by(display_id: params[:conversation_display_id])
    payload = {
      account_id: Current.account.id,
      conversation_display_id: params[:conversation_display_id],
      channel_type: conversation&.inbox&.channel_type,
      agent_name: Current.user.name,
      agent_signature: Current.user.message_signature.presence
    }
    render_result(call_nauto_assistant('reply_suggestion', payload))
  end

  def label_suggestion
    payload = {
      account_id: Current.account.id,
      conversation_display_id: params[:conversation_display_id],
      labels: Current.account.labels.pluck(:title)
    }
    render_result(call_nauto_assistant('label_suggestion', payload))
  end

  def follow_up
    payload = {
      account_id: Current.account.id,
      conversation_display_id: params[:conversation_display_id],
      follow_up_context: params[:follow_up_context]&.to_unsafe_h,
      message: params[:message]
    }
    render_result(call_nauto_assistant('follow_up', payload))
  end

  private

  def call_nauto_assistant(action, payload)
    base_url = ENV['NAUTO_ASSISTANT_URL']
    return { error: 'NAUTO_ASSISTANT_URL is not configured' } if base_url.blank?

    response = HTTParty.post(
      "#{base_url}/copilot/#{action}",
      headers: { 'Content-Type' => 'application/json' },
      body: payload.to_json,
      timeout: 30
    )

    if response.success?
      response.parsed_response.symbolize_keys
    else
      Rails.logger.error "NautoAssistant API Error [#{action}]: #{response.code} - #{response.body}"
      { error: "NautoAssistant returned status #{response.code}" }
    end
  rescue HTTParty::Error, Timeout::Error => e
    Rails.logger.error "NautoAssistant Request Failed [#{action}]: #{e.message}"
    { error: "Failed to connect to NautoAssistant: #{e.message}" }
  end

  def render_result(result)
    if result.nil?
      render json: { message: nil }
    elsif result[:error]
      render json: { error: result[:error] }, status: :unprocessable_entity
    else
      response_data = { message: result[:message] }
      response_data[:follow_up_context] = result[:follow_up_context] if result[:follow_up_context]
      render json: response_data
    end
  end

  def check_authorization
    authorize(:'nauto_assistant/tasks')
  end
end
