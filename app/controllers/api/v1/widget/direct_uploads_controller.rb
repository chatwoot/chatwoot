class Api::V1::Widget::DirectUploadsController < ActiveStorage::DirectUploadsController
  include WebsiteTokenHelper
  before_action :set_web_widget
  before_action :ensure_inbox_active
  before_action :set_contact

  def create
    return if @contact.nil? || @current_account.nil?

    super
  end

  private

  def ensure_inbox_active
    return if @web_widget.inbox.active?

    render json: {
      error: 'inbox_disabled',
      message: 'This inbox is currently disabled'
    }, status: :forbidden
  end
end
