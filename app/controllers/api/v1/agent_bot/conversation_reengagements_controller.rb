# frozen_string_literal: true

class Api::V1::AgentBot::ConversationReengagementsController < ApplicationController
  before_action :authenticate_agent_bot!
  before_action :conversation
  before_action :reengagement

  def destroy
    @reengagement.cancel!(reason: 'cancelled_api')
    render json: {
      message: 'Reengagement cancelled',
      conversation_id: @conversation.id,
      attempt_reached: @reengagement.current_attempt,
      cancelled_at: Time.current.iso8601
    }
  end

  private

  def authenticate_agent_bot!
    token = request.headers['X-Bot-Token'] || params[:bot_token]
    @current_agent_bot = AgentBot.find_by(access_token: token)
    render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_agent_bot
  end

  def conversation
    @conversation = Conversation.find_by(id: params[:conversation_id])

    unless @conversation
      render json: { error: 'Conversation not found' }, status: :not_found
      return
    end

    unless bot_can_access_conversation?
      render json: { error: 'This bot does not have access to this conversation' }, status: :forbidden
    end
  end

  def reengagement
    @reengagement = @conversation&.conversation_reengagement
    return if @reengagement && %w[active suppressed].include?(@reengagement.status)

    render json: { error: 'No active reengagement found for this conversation' }, status: :not_found
  end

  def bot_can_access_conversation?
    return true if @current_agent_bot == @conversation.assignee_agent_bot

    inbox_bot = @conversation.inbox.agent_bot_inbox&.active? && @conversation.inbox.agent_bot
    inbox_bot == @current_agent_bot
  end
end
