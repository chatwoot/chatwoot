# Answers an agent's Copilot message with the workflow tools. Each step is saved on the turn's run, so a retried or resumed
# turn continues where it stopped. Captain::Copilot::ChatService answers when the copilot_workflows flag is off, with the
# same base prompt.
class Captain::Copilot::TurnService < Llm::BaseAiService
  include Captain::ChatHelper
  include Captain::Copilot::ConversationAccess
  include Captain::Copilot::Tracing

  MAX_MODEL_CALLS = 20
  # Copilot's tools without search_conversation, which dumps full transcripts into context; get_data and review_conversations replace it.
  TOOLS = [Captain::Tools::SearchDocumentationService, Captain::Tools::Copilot::GetConversationService,
           Captain::Tools::Copilot::GetContactService, Captain::Tools::Copilot::GetArticleService,
           Captain::Tools::Copilot::SearchArticlesService, Captain::Tools::Copilot::SearchContactsService,
           Captain::Tools::Copilot::SearchLinearIssuesService, Captain::Tools::Copilot::GetReportService,
           Captain::Tools::Copilot::GetAccountDirectoryService].freeze
  WORKFLOW_TOOLS = [Captain::Tools::Copilot::GetDataService, Captain::Tools::Copilot::ReviewConversationsService,
                    Captain::Tools::Copilot::ContinueReviewService, Captain::Tools::Copilot::DisplayService,
                    Captain::Tools::Copilot::ActService].freeze
  # These tools show their own review or approval card in the panel, so the turn writes no step line for them.
  TOOLS_WITH_CARD = %w[review_conversations continue_review act].freeze

  def initialize(run, token)
    # Workflows have their own model setting, so the copilot_workflows flag leaves Copilot unchanged for other accounts.
    super(feature: 'copilot_workflows', account: run.account)
    @run = run
    @token = token
    @account = run.account
    @assistant = run.copilot_thread.assistant
    @user = @account.users.find_by(id: run.user_id)
    raise ArgumentError, 'The user is no longer a member of this account' unless @user

    @conversation = accessible_conversation(account: @account, user: @user, display_id: run.conversation_id) if run.conversation_id.present?
    @conversation_id = @conversation&.display_id
    @tools = build_tools
    @messages = [system_message, account_message, viewed_conversation_message].compact
  end

  def generate_response
    llm = build_chat.with_tool_options(calls: :one, concurrency: false)
    protocol = Captain::ResponsesConfig.options(model: @model, temperature: temperature, feature: @llm_feature)[:protocol]
    @transcript = Captain::Copilot::TurnTranscript.new(@run, llm, protocol: protocol)
    @transcript.load
    @transcript.save(@token)
    params = instrumentation_params
    with_copilot_trace(params[:span_name], params, turn: @run, input: @run.copilot_message.message['content']) do |span|
      save_trace_carrier
      outcome = complete_loop(llm)
      next wait_for_background_run if outcome == :awaiting_background_run

      # Langfuse takes a trace's output from its first span. A turn that waited on a background run finishes in a later span.
      finish(llm).tap { |response| span&.set_attribute(ATTR_LANGFUSE_TRACE_OUTPUT, response.to_json) }
    end
  end

  private

  def build_tools
    tools = TOOLS.map { |tool| tool.new(@assistant, user: @user) } +
            WORKFLOW_TOOLS.map { |tool| tool.new(@assistant, user: @user, run: @run, lease_token: @token) }
    tools.select(&:active?).each { |tool| wrap_tool(tool) }
  end

  # Copilot's base prompt and tool list, then the workflow instructions. They explain Chatwoot's fields, because without
  # them the model treats status and priority as content. The current time is the turn's own, so a retried or resumed turn
  # reads the same dates.
  def system_message
    tools = @tools.map { |tool| "- #{tool.class.name}: #{tool.class.description}" }.join("\n")
    base = Captain::Llm::SystemPromptsService.copilot_response_generator(@assistant.config['product_name'], tools, @assistant.config)
    instructions = Captain::PromptRenderer.render('copilot_workflows', conversations_per_turn: CopilotRun::CONVERSATIONS_PER_TURN,
                                                                       user_name: @user.name, user_id: @user.id,
                                                                       current_time: @run.created_at.iso8601)
    { role: 'system', content: "#{base}\n\n#{instructions}" }
  end

  def account_message
    { role: 'system', content: "The current account id is #{@account.id}. The account is using #{@account.locale_english_name} as the language." }
  end

  def viewed_conversation_message
    return if @conversation.blank?

    { role: 'system', content: "You are currently viewing the conversation with the following details:\n" \
                               "Conversation ID: #{@conversation_id}\nContact ID: #{@conversation.contact_id}" }
  end

  def feature_name
    'copilot'
  end

  def setup_event_handlers(llm)
    llm.after_message do |message|
      record_llm_generation(llm, message)
      record_generation_cost(@run, message)
      @transcript.save(@token)
    end
    llm.before_tool_call { |call| start_tool_call(call) }
    llm.after_tool_result { |result| finish_tool_call(result) }
    llm
  end

  def save_trace_carrier
    return if !ChatwootApp.otel_enabled? || @run.trace_carrier

    @run.with_lease(@token) { @run.update!(trace_carrier: current_trace_carrier) }
  end

  # At the limit the model makes one last call without tools, so the agent gets an answer from what the turn gathered
  # instead of an error. A call past the limit means that answer still asked for a tool.
  def complete_loop(llm)
    until llm.complete?
      @run.renew_lease(@token)
      model_calls = @run.transcript.fetch('messages', []).count { |message| message['role'] == 'assistant' }
      raise Captain::Copilot::LimitExceededError, 'The turn reached its model-call limit' if model_calls > MAX_MODEL_CALLS

      llm.with_tool_options(choice: :none) if model_calls == MAX_MODEL_CALLS
      @run.ensure_can_continue!

      llm.step
    end
    :complete
  rescue Captain::Copilot::BackgroundRunPending
    :awaiting_background_run
  end

  def start_tool_call(call)
    @step_message = nil
    @run.with_lease(@token) do
      @tool_call = @run.tool_calls.find_or_create_by!(call_id: call.id) do |record|
        record.assign_attributes(name: call.name, arguments: call.arguments)
      end
      next if @tool_call.completed?

      @tool_call.update!(status: :running, attempts: @tool_call.attempts + 1)
      # RubyLLM also calls this for a tool the turn does not have, then answers it with an error.
      next if TOOLS_WITH_CARD.include?(call.name) || @tools.none? { |tool| tool.name == call.name }

      @step_message = persist_message({ content: I18n.t("captain.copilot.steps.#{call.name}"), function_name: call.name }, 'assistant_thinking')
    end
  end

  def finish_tool_call(result)
    @run.with_lease(@token) do
      failure = tool_error(result)
      # The result keeps the whole error for the model; the column holds a summary within the string limit.
      @tool_call.update!(status: failure ? :failed : :completed, result: @chart_data ? result.merge(chart_data: @chart_data) : result,
                         error: failure.to_s.truncate(ApplicationRecord::MAX_STRING_COLUMN_LENGTH).presence)
      next unless failure

      # The panel marks a step done once anything follows it, so only a failure changes the step. A tool without a step
      # line gets a line of its own.
      if @step_message
        @step_message.update!(message: @step_message.message.merge('status' => 'failed'))
      else
        persist_message({ content: I18n.t('captain.copilot.step_failed'), function_name: @tool_call.name, status: 'failed' }, 'assistant_thinking')
      end
    end
  end

  # A run summary reports the run's own error, such as a review the flag stopped, so the tool call itself worked.
  def tool_error(result)
    return unless result.is_a?(Hash)

    result = result.with_indifferent_access
    result[:error] unless result.key?(:run_id)
  end

  def wrap_tool(tool)
    original = tool.method(:call)
    execution = self
    tool.define_singleton_method(:call) do |tool_call: nil, **arguments|
      execution.perform_tool(self, original, tool_call, arguments)
    end
  end

  # The pending tool call stays in the transcript without a result. When the background run finishes it saves its summary
  # on the tool call, and the resumed loop replays that call, which returns the saved result instead of running the tool again.
  def wait_for_background_run
    finished = @run.with_lease(@token) do
      done = @tool_call.reload.completed?
      @run.release!(done ? :queued : :awaiting_background_run)
      done
    end
    Captain::Copilot::TurnJob.perform_later(@run.id) if finished
    @tool_call.summary
  end

  def finish(llm)
    @run.with_lease(@token) do
      response = parse_json_response(llm.messages.last.content).slice('content', 'reply_suggestion')
      response['content'] = response['content'].to_s
      persist_message(Captain::Copilot::Chart.attach(response, @run.copilot_thread_id))
      @account.increment_response_usage
      @run.release!(:completed, error: nil)
      response
    end
  end

  def persist_message(message, message_type = 'assistant')
    @run.copilot_thread.copilot_messages.create!(message: message.merge('run_id' => @run.id), message_type: message_type)
  end

  # A started run parks the turn until it finishes: wait_for_background_run and resume_with check the tool call under the
  # turn's lock, so one of them requeues the turn. A run that already finished gives its final summary, not the tool's
  # queued one. A collection is saved before the tool returns and never resumes the turn.
  def started_run_result(result)
    background_run = @tool_call.reload.background_run
    return result if background_run.nil? || background_run.is_a?(CopilotRun::Collection)
    raise Captain::Copilot::BackgroundRunPending unless background_run.finished?

    background_run.summary
  end

  # Chart data is for the panel, not the model, so the model sees only the chart marker. finish_tool_call saves the data
  # on the tool call, where the marker in the answer finds it.
  def hide_chart_data(result)
    @chart_data = result.is_a?(Hash) ? result.with_indifferent_access[:chart_data] : nil
    @chart_data ? result.with_indifferent_access.except(:chart_data) : result
  end

  public

  def perform_tool(tool, original, tool_call, arguments)
    # A failed call keeps no chart, so the data from an earlier call is cleared first.
    @chart_data = nil
    return hide_chart_data(@tool_call.result) if @tool_call.completed?

    tool.tool_call = @tool_call if tool.respond_to?(:tool_call=)
    # Traced here because each tool defines its own execute, which shadows the Instrumentation BaseTool prepends.
    hide_chart_data(started_run_result(instrument_tool_call(@tool_call.name, arguments) { original.call(tool_call: tool_call, **arguments) }))
  rescue Captain::Copilot::LeaseLostError, Captain::Copilot::BackgroundRunPending
    raise
  rescue ArgumentError, ActiveRecord::RecordNotFound => e
    { error: e.message }
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @account).capture_exception
    { error: "Tool failed (#{e.class.name})" }
  end
end
