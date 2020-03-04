class Api::V1::AgentBot::MessagesController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :set_current_user
  skip_before_action :check_subscription

  before_action :set_current_bot
  before_action :authorize_bot
  before_action :set_conversation

  def create
    mb = Messages::Outgoing::NormalBuilder.new(@current_bot, @conversation, params)
    @message = mb.perform
    head :ok
  rescue StandardError => e
    Raven.capture_exception(e)
    head :ok
  end

  private

  def set_current_bot
    @current_bot = AgentBot.find_by!(auth_token: params[:auth_token])
  end

  def authorize_bot
    @current_bot_inbox = @current_bot.agent_bot_inboxes.find_by!(inbox_id: params[:inbox_id], status: :active)
  end

  def set_conversation
    @conversation = @current_bot_inbox.inbox.conversations.find_by!(display_id: params[:conversation_id])
  end
end
