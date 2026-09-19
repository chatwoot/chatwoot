class Captain::LabelClassifierService
  include Llm::ExceptionTrackable

  DECISIONS_URL = 'https://openrouter.ai/api/alpha/decisions'.freeze
  MODEL = 'typesafe/jev-1.13'.freeze
  MATCH_THRESHOLD = 0.7
  # Jev accepts ~32k tokens of state; ~4 chars per token leaves room for the label questions
  TRANSCRIPT_CHAR_LIMIT = 100_000
  API_KEY_CONFIG = 'CAPTAIN_OPEN_ROUTER_API_KEY'.freeze

  pattr_initialize [:account!, :conversation_display_id!]

  def perform
    return { error: I18n.t('captain.disabled'), error_code: 403 } unless account.feature_enabled?('captain_label_classifier')
    return { error: I18n.t('captain.api_key_missing'), error_code: 401 } if api_key.blank?
    return nil unless valid_conversation?

    cached_response = read_from_cache
    return cached_response if cached_response.present?

    classify_labels
  rescue StandardError => e
    capture_llm_exception(e, credential: { source: :system })
    { error: e.message }
  end

  private

  def classify_labels
    labels = account.labels.pluck(:title, :description)
    transcript = format_transcript
    return if labels.blank? || transcript.blank?

    response = HTTParty.post(
      DECISIONS_URL,
      headers: { 'Authorization' => "Bearer #{api_key}", 'Content-Type' => 'application/json' },
      body: { model: MODEL, state: { transcript: transcript }, questions: label_questions(labels) }.to_json,
      timeout: 10
    )
    return { error: response.parsed_response.to_s, error_code: response.code } unless response.success?

    result = { message: matched_labels(response.parsed_response['answers']).join(', ') }
    write_to_cache(result)
    result
  end

  def label_questions(labels)
    labels.to_h do |title, description|
      instructions = "Does the support conversation in `transcript` belong under the label \"#{title}\"? #{description}".strip
      [title, { type: 'noul', instructions: instructions }]
    end
  end

  def matched_labels(answers)
    answers.select { |_title, answer| answer['noul'] >= MATCH_THRESHOLD }
           .sort_by { |_title, answer| -answer['noul'] }
           .map(&:first)
  end

  def format_transcript
    lines = []
    character_count = 0

    conversation.messages.where(message_type: [:incoming, :outgoing], private: false).reorder(id: :desc).each do |message|
      content = message.content_for_llm
      next if content.blank?
      break if character_count + content.length > TRANSCRIPT_CHAR_LIMIT

      lines.prepend("#{message.incoming? ? 'Customer' : 'Agent'}: #{content}")
      character_count += content.length
    end

    lines.join("\n")
  end

  def conversation
    @conversation ||= account.conversations.find_by(display_id: conversation_display_id)
  end

  def valid_conversation?
    return false if conversation.nil?
    return false if conversation.messages.count > 100
    return false if conversation.messages.count > 20 && !conversation.messages.last.incoming?

    true
  end

  def cache_key
    format(
      ::Redis::Alfred::OPENAI_CONVERSATION_KEY,
      event_name: 'label_classifier',
      conversation_id: conversation.id,
      updated_at: conversation.last_activity_at.to_i
    )
  end

  def read_from_cache
    cached = Redis::Alfred.get(cache_key)
    JSON.parse(cached, symbolize_names: true) if cached.present?
  end

  def write_to_cache(response)
    Redis::Alfred.setex(cache_key, response.to_json)
  end

  def api_key
    @api_key ||= GlobalConfig.get_value(API_KEY_CONFIG)
  end

  def exception_tracking_account
    account
  end
end
