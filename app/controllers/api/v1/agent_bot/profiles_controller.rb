# frozen_string_literal: true

class Api::V1::AgentBot::ProfilesController < ApplicationController
  before_action :authenticate_agent_bot!

  def show
    render json: {
      id: @current_agent_bot.id,
      name: @current_agent_bot.name,
      description: @current_agent_bot.description,
      assistant_config: @current_agent_bot.assistant_config,
      agent_behavior_config: @current_agent_bot.agent_behavior_config
    }
  end

  private

  def authenticate_agent_bot!
    token = request.headers['X-Bot-Token'] || params[:bot_token]
    @current_agent_bot = AgentBot.find_by(access_token: token)
    render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_agent_bot
  end
end
