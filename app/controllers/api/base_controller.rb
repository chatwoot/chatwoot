class Api::BaseController < ApplicationController
  include AccessTokenAuthHelper
  respond_to :json
  before_action :authenticate_access_token!, if: :authenticate_by_access_token?
  before_action :validate_bot_access_token!, if: :authenticate_by_access_token?
  before_action :authenticate_user!, unless: :authenticate_by_access_token?

  private

  def authenticate_by_access_token?
    request.headers[:api_access_token].present? || request.headers[:HTTP_API_ACCESS_TOKEN].present?
  end

  def set_conversation
    @conversation ||= current_account.conversations.find_by(display_id: params[:conversation_id])
  end

  def check_billing_enabled
    raise ActionController::RoutingError, 'Not Found' unless ENV['BILLING_ENABLED']
  end
end
