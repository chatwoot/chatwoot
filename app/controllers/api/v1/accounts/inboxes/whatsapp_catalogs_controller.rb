class Api::V1::Accounts::Inboxes::WhatsappCatalogsController < Api::V1::Accounts::BaseController
  DEFAULT_PRODUCTS_LIMIT = 24
  MAX_PRODUCTS_LIMIT = 50

  before_action :fetch_inbox
  before_action :ensure_whatsapp_cloud_inbox
  before_action :validate_products_limit, only: [:products]
  before_action :validate_products_filters, only: [:products]

  def show
    render json: catalog_service.perform
  end

  def products
    result = catalog_service.products(limit: products_limit, after: params[:after], query: params[:q]&.strip,
                                      collection_id: params[:collection_id].presence)
    return render_could_not_create_error(I18n.t('errors.whatsapp.catalog_read.invalid_collection')) if result[:status] == 'invalid_collection'

    render json: result
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize @inbox, :show?
  end

  def ensure_whatsapp_cloud_inbox
    channel = @inbox.channel
    return if channel.is_a?(Channel::Whatsapp) && channel.provider == 'whatsapp_cloud'

    render_could_not_create_error(I18n.t('errors.whatsapp.catalog_read.cloud_inbox_required'))
  end

  def products_limit
    Integer(params.fetch(:limit, DEFAULT_PRODUCTS_LIMIT), exception: false)
  end

  def validate_products_limit
    return if products_limit&.between?(1, MAX_PRODUCTS_LIMIT)

    render_could_not_create_error(I18n.t('errors.whatsapp.catalog_read.invalid_limit', max: MAX_PRODUCTS_LIMIT))
  end

  def validate_products_filters
    return if %i[q after collection_id].all? { |key| params[key].nil? || params[key].is_a?(String) }

    render_could_not_create_error(I18n.t('errors.whatsapp.catalog_read.invalid_filters'))
  end

  def catalog_service
    Whatsapp::CatalogService.new(channel: @inbox.channel, refresh: params[:refresh])
  end
end
