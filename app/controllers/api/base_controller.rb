class Api::BaseController < ApplicationController
  respond_to :json
  before_action :authenticate_user!
  rescue_from StandardError do |exception|
    Raven.capture_exception(exception)
    render json: { :error => "500 error", message: exception.message }.to_json , :status => 500
  end unless Rails.env.development?

  private

  def set_conversation
    @conversation ||= current_account.conversations.find_by(display_id: params[:conversation_id])
  end
end
