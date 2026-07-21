class Api::V1::Accounts::Captain::AssistantsController < Api::V1::Accounts::BaseController
  before_action -> { check_authorization(Captain::Assistant) }

  before_action :set_assistant, only: [:show, :update, :destroy, :playground, :stats, :summary, :drilldown]

  def index
    @assistants = account_assistants.ordered
  end

  def show; end

  def create
    @assistant = account_assistants.create!(assistant_params)
  end

  def update
    @assistant.update!(assistant_params)
  end

  def destroy
    @assistant.destroy
    head :no_content
  end

  def playground
    response = if captain_v2_enabled?
                 Captain::Assistant::AgentRunnerService.new(assistant: @assistant, source: 'playground').generate_response(
                   message_history: playground_message_history
                 )
               else
                 Captain::Llm::AssistantChatService.new(assistant: @assistant, source: 'playground').generate_response(
                   additional_message: playground_params[:message_content],
                   message_history: message_history
                 )
               end

    render json: response
  end

  def tools
    assistant = Captain::Assistant.new(account: Current.account)
    @tools = assistant.available_agent_tools
  end

  def stats
    render json: Captain::AssistantStatsBuilder.new(@assistant, params[:range], params[:timezone_offset]).metrics
  end

  def summary
    result = cached_or_generated_summary(Captain::AssistantStatsBuilder.new(@assistant, params[:range], params[:timezone_offset]))

    if result[:error]
      render json: { error: result[:error] }, status: :unprocessable_content
    else
      render json: { message: result[:message] }
    end
  end

  def drilldown
    return head :unprocessable_entity unless Captain::AssistantDrilldownBuilder.supported_metric?(params[:metric])

    render json: Captain::AssistantDrilldownBuilder.new(@assistant, drilldown_params).build
  end

  private

  def drilldown_params
    params.permit(:metric, :range, :timezone_offset, :page, :per_page)
  end

  def cached_or_generated_summary(builder)
    cache_key = summary_cache_key(builder.range)
    cached = Rails.cache.read(cache_key)
    return cached if cached

    result = Captain::OverviewSummaryService.new(
      account: Current.account,
      assistant: @assistant,
      first_name: Current.user.name.to_s.split.first,
      stats: builder.metrics,
      period: builder.period
    ).perform
    # Don't cache transient LLM/config failures, otherwise every reload returns 422 for the next hour.
    Rails.cache.write(cache_key, result, expires_in: 1.hour) unless result[:error]
    result
  end

  def summary_cache_key(range)
    "captain_overview_summary/#{@assistant.id}/#{Current.user.id}/#{range}/#{Date.current}"
  end

  def set_assistant
    @assistant = account_assistants.find(params[:id])
  end

  def account_assistants
    @account_assistants ||= Captain::Assistant.for_account(Current.account.id)
  end

  def assistant_params
    permitted = params.require(:assistant).permit(:name, :description,
                                                  config: [
                                                    :product_name, :feature_faq, :feature_memory, :feature_citation,
                                                    :feature_contact_attributes,
                                                    :welcome_message, :handoff_message, :resolution_message,
                                                    :instructions, :temperature
                                                  ])

    # Handle array parameters separately to allow partial updates
    permitted[:response_guidelines] = params[:assistant][:response_guidelines] if params[:assistant].key?(:response_guidelines)

    permitted[:guardrails] = params[:assistant][:guardrails] if params[:assistant].key?(:guardrails)

    permitted
  end

  def playground_params
    params.require(:assistant).permit(:message_content, message_history: [:role, :content, :agent_name])
  end

  def message_history
    (playground_params[:message_history] || []).map do |message|
      {
        role: message[:role],
        content: message[:content],
        agent_name: message[:agent_name]
      }.compact
    end
  end

  def playground_message_history
    history = message_history
    current_message = playground_params[:message_content]
    return history if current_message.blank?

    current_user_message = { role: 'user', content: current_message }
    return history if history.last == current_user_message

    history + [current_user_message]
  end

  def captain_v2_enabled?
    @assistant.account.feature_enabled?('captain_integration_v2')
  end
end
