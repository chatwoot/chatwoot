# frozen_string_literal: true

class Api::V1::AgentBot::CredentialsController < ApplicationController
  before_action :authenticate_agent_bot!

  def show
    render json: {
      openai_api_key: @current_agent_bot.openai_api_key.presence,
      google_api_key: @current_agent_bot.google_api_key.presence,
      pinecone_api_key: @current_agent_bot.account&.pinecone_api_key.presence
    }
  end

  private

  def authenticate_agent_bot!
    token = request.headers['X-Bot-Token'] || params[:bot_token]
    @current_agent_bot = AgentBot.find_by(access_token: token)
    render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_agent_bot
  end
end
