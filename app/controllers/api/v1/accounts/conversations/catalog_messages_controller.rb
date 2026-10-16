class Api::V1::Accounts::Conversations::CatalogMessagesController < Api::V1::Accounts::Conversations::BaseController
  before_action :ensure_whatsapp_cloud_inbox
  before_action :ensure_products_list

  rescue_from Whatsapp::CatalogMessagePayloadBuilder::Error do |error|
    render_could_not_create_error(error.message)
  end

  def create
    @message = Whatsapp::CatalogMessageService.new(conversation: @conversation, sender: Current.user, params: permitted_params).perform
    render 'api/v1/accounts/conversations/messages/create'
  end

  private

  def ensure_whatsapp_cloud_inbox
    channel = @conversation.inbox.channel
    return if channel.is_a?(Channel::Whatsapp) && channel.provider == 'whatsapp_cloud'

    render_could_not_create_error(I18n.t('errors.whatsapp.catalog.cloud_inbox_required'))
  end

  def ensure_products_list
    products = params[:products]
    return if products.nil? || (products.is_a?(Array) && products.all?(ActionController::Parameters))

    render_could_not_create_error(I18n.t('errors.whatsapp.catalog.invalid_products'))
  end

  def permitted_params
    params.permit(:kind, :content, :header, :footer, :catalog_id,
                  products: [:retailer_id, :name, :price, :description, :url, :section, { image_urls: [] }]).to_h
  end
end
