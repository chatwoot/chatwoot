class Api::V1::Widget::DirectUploadsController < ActiveStorage::DirectUploadsController
  skip_before_action :verify_authenticity_token
  include WebsiteTokenHelper
  before_action :set_web_widget
  before_action :set_contact

  def create
    return if @contact.nil? || @current_account.nil?
    return render json: { error: I18n.t('errors.contacts.blocked', default: 'Contact is blocked') }, status: :forbidden if @contact.blocked?

    super
  end
end
