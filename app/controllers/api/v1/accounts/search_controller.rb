class Api::V1::Accounts::SearchController < Api::V1::Accounts::BaseController
  before_action :validate_page_size
  before_action :validate_count_types, only: :counts

  def counts
    service = search_service('all')
    render json: { payload: { counts: service.counts(params[:types]) }, meta: { message_backend: service.message_backend } }
  end

  def index
    @result = search('all')
  end

  def conversations
    @result = search('Conversation')
  end

  def contacts
    @result = search('Contact')
  end

  def messages
    @result = search('Message')
  end

  def articles
    @result = search('Article')
  end

  private

  def search(search_type)
    service = search_service(search_type)
    validate_message_cursor(service) if params.key?(:cursor)
    result = service.perform
    @message_backend = service.message_backend
    @message_pagination = service.message_pagination
    result
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue CustomExceptions::MessageSearchUnavailable => e
    render json: { error: e.message }, status: :service_unavailable
  end

  def validate_message_cursor(service)
    cursor = params[:cursor]
    return if cursor.is_a?(String) && cursor.present? && cursor.bytesize <= 2048 && service.supports_message_cursor?

    raise ArgumentError, 'Invalid message search cursor'
  end

  def search_service(search_type)
    SearchService.new(
      current_user: Current.user,
      current_account: Current.account,
      search_type: search_type,
      params: params
    )
  end

  def validate_page_size
    return unless params.key?(:per_page)
    return if SearchService::PAGE_SIZES.map(&:to_s).include?(params[:per_page].to_s)

    render json: { error: 'per_page must be 5 or 15' }, status: :unprocessable_entity
  end

  def validate_count_types
    return if params[:types].is_a?(Array) && params[:types].any? && (params[:types] - SearchService::SEARCH_TYPES.keys).empty?

    render json: { error: 'types must be an array of search entity names' }, status: :unprocessable_entity
  end
end
