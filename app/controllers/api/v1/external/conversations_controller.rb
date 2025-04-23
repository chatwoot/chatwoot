class Api::V1::External::ConversationsController < Api::BaseController
  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE = 100
  EXTERNAL_API_AUTH_TOKEN = ENV.fetch('EXTERNAL_API_AUTH_TOKEN', nil)
  skip_before_action :authenticate_user!
  before_action :authenticate_token
  before_action :find_conversation

  def messages
    @messages = fetch_paginated_messages(@conversation)
    render json: success_response, status: :ok
  rescue StandardError => e
    render_error(e.message, :unprocessable_entity)
  end

  def authenticate_token
    token = request.headers['Authorization']&.split(' ')&.last
    return if token == EXTERNAL_API_AUTH_TOKEN

    render_error('Unauthorized', :unauthorized)
  end

  private

  def find_conversation
    @conversation = Conversation.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error('Conversation not found', :not_found)
  end

  def fetch_paginated_messages(conversation)
    conversation.messages
                .select(:id, :conversation_id, :message_type, :content)
                .order(sort_params)
                .page(params[:page])
                .per(per_page_param)
  end

  def sort_params
    direction = params[:sort_order]&.downcase == 'desc' ? :desc : :asc
    { created_at: direction }
  end

  def build_meta
    {
      total_count: @messages.total_count,
      current_page: @messages.current_page,
      per_page: @messages.limit_value,
      total_pages: @messages.total_pages
    }
  end

  def success_response
    {
      success: true,
      status_code: 200,
      data: {
        messages: @messages.map { |msg| serialize_message(msg) },
        meta: build_meta
      }
    }
  end

  def render_error(message, status)
    render json: {
      success: false,
      status_code: Rack::Utils.status_code(status),
      error: message
    }, status: status
  end

  def per_page_param
    (params[:per_page] || DEFAULT_PER_PAGE).to_i.clamp(1, MAX_PER_PAGE)
  end

  def serialize_message(msg)
    {
      conversation_id: msg.conversation_id,
      message_type: msg.message_type,
      content: msg.content
    }
  end
end
