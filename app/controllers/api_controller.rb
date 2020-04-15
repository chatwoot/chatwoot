class ApiController < ApplicationController
  skip_before_action :set_current_user, only: [:index]
  skip_before_action :check_subscription, only: [:index]

  def index
    render json: { version: Chatwoot.config[:version], timestamp: Time.now.utc.to_formatted_s(:db) }
  end
end
