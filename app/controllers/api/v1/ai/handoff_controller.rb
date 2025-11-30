class Api::V1::Ai::HandoffController < ApplicationController
  before_action :authenticate_ai_request

  # POST /api/v1/ai/handoff
  # Assigns a conversation to a human agent (AI handoff)
  #
  # Parameters:
  #   - conversation_id: ID of the conversation to hand off
  #   - assignee_id: ID of the agent to assign the conversation to
  #
  # Headers:
  #   - X-Api-Token: ALOOSTUDIO_API_TOKEN for authentication
  def create
    Rails.logger.info "[AI_HANDOFF] 🤝 Handoff request received for conversation #{params[:conversation_id]} to agent #{params[:assignee_id]}"

    conversation = Conversation.find_by(id: params[:conversation_id])

    unless conversation
      Rails.logger.error "[AI_HANDOFF] ❌ Conversation #{params[:conversation_id]} not found"
      return render json: { error: 'Conversation not found' }, status: :not_found
    end

    agent = conversation.account.users.find_by(id: params[:assignee_id])

    unless agent
      Rails.logger.error "[AI_HANDOFF] ❌ Agent #{params[:assignee_id]} not found in account #{conversation.account.id}"
      return render json: { error: 'Agent not found' }, status: :not_found
    end

    # Assign conversation to human agent
    conversation.assignee = agent
    conversation.save!

    Rails.logger.info "[AI_HANDOFF] ✅ Conversation #{conversation.id} successfully handed off to agent #{agent.id} (#{agent.name})"

    render json: {
      success: true,
      conversation_id: conversation.id,
      conversation_display_id: conversation.display_id,
      assignee: {
        id: agent.id,
        name: agent.name,
        email: agent.email,
        available_name: agent.available_name
      },
      message: "Conversation successfully assigned to #{agent.name}"
    }, status: :ok
  rescue StandardError => e
    Rails.logger.error "[AI_HANDOFF] ❌ Error during handoff: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: 'Internal server error', details: e.message }, status: :internal_server_error
  end

  private

  def authenticate_ai_request
    api_token = request.headers['X-Api-Token']
    expected_token = ENV.fetch('ALOOSTUDIO_API_TOKEN', nil)

    Rails.logger.info "[AI_HANDOFF] 🔐 Authenticating AI request with token: #{api_token&.truncate(20)}"

    if expected_token.blank?
      Rails.logger.error '[AI_HANDOFF] ❌ ALOOSTUDIO_API_TOKEN not configured'
      render json: { error: 'API token not configured' }, status: :internal_server_error
      return
    end

    return if api_token == expected_token

    Rails.logger.error '[AI_HANDOFF] ❌ Invalid API token provided'
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end
end
