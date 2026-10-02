class Enterprise::Webhooks::ContextDevController < ActionController::API
  before_action :validate_signature

  def process_payload
    return head :bad_request unless valid_payload?

    Captain::Tools::ContextDevParserJob.perform_later(
      document_id: document.id,
      batch_id: payload.dig('data', 'batch', 'id'),
      event: payload['event']
    )

    head :ok
  end

  private

  def validate_signature
    return if document && WebCrawling::ContextDev::WebhookVerifier.new(
      payload: raw_payload,
      signature: request.headers['X-Context-Signature'],
      secret: document.web_crawling_webhook_secret
    ).valid?

    head :unauthorized
  end

  def valid_payload?
    request.headers['X-Context-Event'] == payload['event'] &&
      request.headers['X-Context-Id'] == payload['id'] &&
      document.web_crawling_external_id == payload.dig('data', 'batch', 'id')
  end

  def document
    @document ||= Captain::Document.find_by(id: params[:document_id])
  end

  def payload
    @payload ||= JSON.parse(raw_payload)
  rescue JSON::ParserError
    {}
  end

  def raw_payload
    @raw_payload ||= request.raw_post
  end
end
