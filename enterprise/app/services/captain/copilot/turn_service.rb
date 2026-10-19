class Captain::Copilot::TurnService < Captain::Copilot::ChatService
  include Captain::Copilot::Tracing

  MAX_MODEL_CALLS = 12
  MAX_LISTED_AGENTS = 100

  # search_conversation dumps full transcripts into context; get_data and review_conversations replace it here.
  def self.tool_inventory(assistant:, user:)
    workflow_tools = [Captain::Tools::Copilot::GetDataService, Captain::Tools::Copilot::ReviewConversationsService,
                      Captain::Tools::Copilot::ContinueReviewService, Captain::Tools::Copilot::DisplayService, Captain::Tools::Copilot::ActService]
    super.grep_v(Captain::Tools::Copilot::SearchConversationsService) + workflow_tools.map { |tool| tool.new(assistant, user: user) }
  end

  def initialize(run, token)
    # Checked before super, which builds the instructions from the user's name.
    raise ArgumentError, 'The user is no longer a member of this account' unless run.account.users.exists?(run.user_id)

    @run = run
    @token = token
    super(run.copilot_thread.assistant, user_id: run.user_id, copilot_thread_id: run.copilot_thread_id,
                                        conversation_id: run.context['conversation_id'])
    @tools.each { |tool| wrap_tool(tool) }
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

  # Workflows have their own model setting, so the copilot_workflows flag leaves Copilot unchanged for other accounts.
  def llm_feature
    'copilot_workflows'
  end

  def setup_message_history(_config)
    @copilot_thread = @run.copilot_thread
    @previous_history = []
  end

  def system_message
    message = super
    # The prompt explains Chatwoot's fields, because without them the model treats status and priority as content. Agents
    # refer to each other by name, but assignee filters and assign_agent take user IDs. The current time is the turn's own,
    # so a retried or resumed turn reads the same dates.
    agents = @run.account.users.order(:name).limit(MAX_LISTED_AGENTS).map { |agent| { name: agent.name, id: agent.id } }
    instructions = Captain::PromptRenderer.render('copilot_workflows', conversations_per_turn: CopilotRun::CONVERSATIONS_PER_TURN,
                                                                       user_name: @user.name, user_id: @user.id, agents: agents,
                                                                       current_time: @run.created_at.iso8601)
    message[:content] += "\n\n#{instructions}"
    message
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
    return if !ChatwootApp.otel_enabled? || @run.context.key?('trace_carrier')

    @run.with_lease(@token) { @run.update!(context: @run.context.merge('trace_carrier' => current_trace_carrier)) }
  end

  def complete_loop(llm)
    until llm.complete?
      @run.renew_lease(@token)
      model_calls = @run.transcript.fetch('messages', []).count { |message| message['role'] == 'assistant' }
      raise Captain::Copilot::LimitExceededError, 'The turn reached its model-call limit' if model_calls >= MAX_MODEL_CALLS

      @run.ensure_can_continue!

      llm.step
    end
    :complete
  rescue Captain::Copilot::BackgroundRunPending
    :awaiting_background_run
  end

  def start_tool_call(call)
    @run.with_lease(@token) do
      @tool_call = @run.tool_calls.find_or_create_by!(call_id: call.id) do |record|
        record.assign_attributes(name: call.name, arguments: call.arguments)
      end
      next if @tool_call.completed?

      @tool_call.update!(status: :running, attempts: @tool_call.attempts + 1)
      persist_message({ content: "Using #{call.name}", function_name: call.name }, 'assistant_thinking')
    end
  end

  def finish_tool_call(result)
    @run.with_lease(@token) do
      failure = tool_error(result)
      # The result keeps the whole error for the model; the column holds a summary within the string limit.
      @tool_call.update!(status: failure ? :failed : :completed, result: result,
                         error: failure.to_s.truncate(ApplicationRecord::MAX_STRING_COLUMN_LENGTH).presence)
      # The result is already on the tool call; the panel shows only the step.
      persist_message({ content: "#{failure ? 'Failed' : 'Completed'} #{@tool_call.name}", function_name: @tool_call.name }, 'assistant_thinking')
    end
  end

  # A run summary reports the run's own error, such as a review the flag stopped, so the tool call itself worked.
  def tool_error(result)
    return unless result.is_a?(Hash)

    result = result.with_indifferent_access
    result[:error] unless result.key?(:run_id)
  end

  def wrap_tool(tool)
    tool.run = @run if tool.respond_to?(:run=)
    tool.lease_token = @token if tool.respond_to?(:lease_token=)
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
      @run.update!(status: done ? :queued : :awaiting_background_run, lease_token: nil, lease_until: nil)
      persist_message({ content: "Waiting for #{@tool_call.name} to finish" }, 'assistant_thinking') unless done
      done
    end
    Captain::Copilot::TurnJob.perform_later(@run.id) if finished
    @tool_call.summary
  end

  def finish(llm)
    @run.with_lease(@token) do
      response = parse_json_response(llm.messages.last.content).slice('content', 'reply_suggestion')
      response['content'] = response['content'].to_s
      persist_message(response)
      @account.increment_response_usage
      @run.update!(status: :completed, lease_token: nil, lease_until: nil, error: nil)
      response
    end
  end

  def persist_message(message, message_type = 'assistant')
    super(message.merge('run_id' => @run.id), message_type)
  end

  # A started run parks the turn until it finishes: wait_for_background_run and resume_with check the tool call under the
  # turn's lock, so one of them requeues the turn. A run that already finished gives its final summary, not the tool's
  # queued one. A collection is saved before the tool returns and never resumes the turn.
  def started_run_result(result)
    background_run = @tool_call.reload.background_run
    return result if background_run.nil? || background_run.collection?
    raise Captain::Copilot::BackgroundRunPending unless background_run.finished?

    background_run.summary
  end

  public

  def perform_tool(tool, original, tool_call, arguments)
    return @tool_call.result if @tool_call.completed?

    tool.tool_call = @tool_call if tool.respond_to?(:tool_call=)
    started_run_result(instrument_tool_call(@tool_call.name, arguments) { original.call(tool_call: tool_call, **arguments) })
  rescue Captain::Copilot::LeaseLostError, Captain::Copilot::BackgroundRunPending
    raise
  rescue ArgumentError, ActiveRecord::RecordNotFound => e
    { error: e.message }
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @account).capture_exception
    { error: "Tool failed (#{e.class.name})" }
  end
end
