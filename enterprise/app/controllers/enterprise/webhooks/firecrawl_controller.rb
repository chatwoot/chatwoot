class Enterprise::Webhooks::FirecrawlController < ActionController::API
  before_action :validate_token

  def process_payload
    Aiagent::Tools::FirecrawlParserJob.perform_later(topic_id: topic.id, payload: payload) if crawl_page_event?

    head :ok
  end

  private

  include Aiagent::FirecrawlHelper

  def payload
    permitted_params[:data]&.first&.to_h
  end

  def validate_token
    render json: { error: 'Invalid access_token' }, status: :unauthorized if topic_token != permitted_params[:token]
  end

  def topic
    @topic ||= Aiagent::Topic.find(permitted_params[:topic_id])
  end

  def topic_token
    generate_firecrawl_token(topic.id, topic.account_id)
  end

  def crawl_page_event?
    permitted_params[:type] == 'crawl.page'
  end

  def permitted_params
    params.permit(
      :type,
      :topic_id,
      :token,
      :success,
      :id,
      :metadata,
      :format,
      :firecrawl,
      data: [:markdown, { metadata: {} }]
    )
  end
end
