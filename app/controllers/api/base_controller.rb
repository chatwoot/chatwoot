class Api::BaseController < ApplicationController
  respond_to :json
  before_action :authenticate_user!

  private

  def set_conversation
    @conversation ||= current_account.conversations.find_by(display_id: params[:conversation_id])
  end

  def check_billing_enabled
    raise ActionController::RoutingError, 'Not Found' unless ENV['BILLING_ENABLED']
  end
end
