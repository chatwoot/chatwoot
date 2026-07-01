class Captain::Llm::AiAnalyticsService < Llm::BaseAiService
  include Integrations::LlmInstrumentation

  def initialize(account, query)
    super()
    @account = account
    @query = query
  end

  def process
    return 'Please provide a question.' if @query.blank?

    generate_analytics_response
  end

  private

  def generate_analytics_response
    response = instrument_llm_call(instrumentation_params) do
      chat
        .with_instructions(system_prompt)
        .ask(@query)
    end
    response.content
  rescue RubyLLM::Error => e
    ChatwootExceptionTracker.new(e, account: @account).capture_exception
    'Sorry, I could not process your request at this time.'
  end

  def instrumentation_params
    {
      span_name: 'llm.captain.ai_analytics',
      model: @model,
      temperature: @temperature,
      account_id: @account.id,
      feature_name: 'ai_analytics',
      messages: [
        { role: 'system', content: system_prompt },
        { role: 'user', content: @query }
      ],
      metadata: {}
    }
  end

  def system_prompt
    metrics = fetch_account_metrics
    <<~PROMPT
      You are an AI Analytics assistant for a customer support team.
      You are provided with the following metrics for the account in the last 7 days:
      - Total conversations: #{metrics[:total_conversations_last_7_days]}
      - Currently open: #{metrics[:open_conversations]}
      - Unassigned: #{metrics[:unassigned_conversations]}
      - Average CSAT (out of 5): #{metrics[:avg_csat]}

      The manager asks a question. Give a professional, concise, and analytical response based on the metrics. Do not invent metrics that are not provided.
    PROMPT
  end

  def fetch_account_metrics
    conversations = @account.conversations.where('created_at > ?', 7.days.ago)
    {
      total_conversations_last_7_days: conversations.count,
      open_conversations: @account.conversations.open.count,
      unassigned_conversations: @account.conversations.unassigned.count,
      avg_csat: @account.csat_survey_responses.where('created_at > ?', 7.days.ago).average(:rating).to_f.round(2)
    }
  end
end
