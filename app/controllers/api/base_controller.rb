class Api::BaseController < ApplicationController
  include AccessTokenAuthHelper
  respond_to :json
  before_action :authenticate_access_token!
  before_action :authenticate_user!, if: :should_authenticate_user?

  private

  def should_authenticate_user?
    current_user.blank?
  end

  def set_conversation
    @conversation ||= current_account.conversations.find_by(display_id: params[:conversation_id])
  end

  def check_billing_enabled
    raise ActionController::RoutingError, 'Not Found' unless ENV['BILLING_ENABLED']
  end
end
