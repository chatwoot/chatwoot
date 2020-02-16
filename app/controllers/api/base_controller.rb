class Api::BaseController < ApplicationController
  respond_to :json
  before_action :authenticate_user!
  unless Rails.env.development?
    rescue_from StandardError do |exception|
      Raven.capture_exception(exception)
      render json: { error: '500 error', message: exception.message }.to_json, status: 500
    end
  end

  private

  def set_conversation
    @conversation ||= current_account.conversations.find_by(display_id: params[:conversation_id])
  end

  def check_billing_enabled
    raise ActionController::RoutingError, 'Not Found' unless ENV['BILLING_ENABLED']
  end
end
