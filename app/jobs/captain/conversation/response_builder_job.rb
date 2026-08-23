class Captain::Conversation::ResponseBuilderJob < ApplicationJob # rubocop:disable Metrics/ClassLength
  include Captain::Conversation::V2LifecycleEvents
  include Captain::Conversation::MessageBuilder
  include Captain::Conversation::ResponseLifecycleLogging

  MAX_MESSAGE_LENGTH = 10_000
  retry_on ActiveStorage::FileNotFoundError, attempts: 3, wait: 2.seconds
  retry_on Faraday::BadRequestError, attempts: 3, wait: 2.seconds

  def perform(conversation, assistant, responding_to_message_id = nil)
    @conversation = conversation
    @inbox = conversation.inbox
    @assistant = assistant
    @responding_to_message_id = responding_to_message_id

    return log_non_pending unless conversation_pending?

    Current.executed_by = @assistant

    # Simple replies are the non-LLM first layer: a keyword match answers the
    # customer directly and skips LLM generation entirely.
    return if simple_reply_handled?

    return log_pre_generation_discard if newer_customer_message_arrived?

    generate_response_with_v2
  rescue ActiveStorage::FileNotFoundError, Faraday::BadRequestError => e
    handle_error(e)
    raise e
  rescue StandardError => e
    handle_error(e)
  ensure
    Current.executed_by = nil
  end

  private

  delegate :account, :inbox, to: :@conversation

  def simple_reply_handled?
    Captain::Conversation::SimpleReplyService.new(conversation: @conversation, assistant: @assistant).perform.tap do |handled|
      capture_simple_reply_session if handled
    end
  end

  # Simple replies never run the agent loop, so they have no run_result to
  # derive a session from. Record a minimal trace so the debugging page still
  # shows the deterministic layer firing for the conversation.
  def capture_simple_reply_session
    Captain::AgentSession.create!(
      assistant: @assistant,
      session_type: :assistant,
      subject: @conversation,
      outcome: :simple_reply,
      run_context: simple_reply_run_context
    )
  rescue StandardError => e
    Rails.logger.error("[CAPTAIN][ResponseBuilderJob] Simple reply session capture failed for conversation=#{@conversation.display_id}: #{e.message}")
  end

  def simple_reply_run_context
    reply = @conversation.messages.where(sender: @assistant).order(created_at: :desc).first
    return [] unless reply

    [{
      role: 'assistant',
      agent_name: @assistant.agent_name,
      content: { reasoning: 'Simple reply matched', response: reply.content },
      tool_calls: []
    }]
  end

  def generate_response_with_v2
    runner_service = v2_runner_service
    @runner_service = runner_service
    message_history = Captain::Conversation::MessageHistoryBuilderService.new(conversation: @conversation).perform
    @response = runner_service.generate_response(message_history: message_history)
    @run_result = runner_service.last_run_result

    @v2_handoff_tool_completed = runner_service.handoff_completed?
    @v2_handoff_offer_pending = runner_service.handoff_offer_pending?
    @v2_handoff_offer_message_id = runner_service.handoff_offer_message_id
    return process_response if v2_handoff_tool_completed?
    return if runner_service.response_discarded? || newer_customer_message_arrived?

    process_response
  end

  def v2_runner_service
    runner_args = { assistant: @assistant, conversation: @conversation }
    runner_args[:responding_to_message_id] = @responding_to_message_id if @responding_to_message_id.present?
    Captain::Assistant::AgentRunnerService.new(**runner_args)
  end

  def process_response
    # The V2 runner rescues its own generation errors and signals them via an error
    # response instead of raising, so the failure event must be emitted here — the
    # top-level handle_error path only sees exceptions raised outside the runner.
    if v2_generation_errored?
      record_v2_response_failure(@response['error_reason'])
      return process_error_handoff
    end

    if v2_handoff_tool_fired?
      process_v2_handoff_response
    elsif conversation_pending?
      process_standard_response
    end
  end

  def process_standard_response
    message = nil
    ActiveRecord::Base.transaction do
      next if newer_customer_message_arrived?

      message = create_messages
    end
    return unless message

    capture_assistant_session(result_message: message, credits_consumed: 1.0)
    capture_decision_trace
    record_v2_response_completed(message)
  end

  def process_v2_handoff_response
    # A consent-gated offer (not a transfer) is handled here: the offer message
    # was already posted inside the tool, so we only record the run and keep the
    # conversation pending for the customer's reply. No transfer message is posted.
    if v2_handoff_offer_pending?
      @handoff_offer_message = @conversation.messages.find_by(id: @v2_handoff_offer_message_id)
      capture_assistant_session(result_message: @handoff_offer_message, credits_consumed: 0.0)
      capture_decision_trace
      return
    end

    # The completion marker is set inside the locked handoff. If the conversation
    # is no longer pending, a human took over mid-run; bail out rather than
    # posting a stale handoff message on top of their reply.
    return unless v2_handoff_tool_completed? || conversation_pending?

    v2_handoff_tool_completed? ? process_v2_handoff : process_v1_handoff
    record_v2_failure_handoff(source: Captain::ConversationEvents::Sources::TOOL) unless v2_handoff_tool_completed?

    capture_assistant_session(result_message: @handoff_message, credits_consumed: 0.0, outcome: :handoff)
    capture_decision_trace
  end

  def v2_handoff_tool_fired? = @response['handoff_tool_called']
  def v2_handoff_tool_completed? = @v2_handoff_tool_completed == true
  def v2_handoff_offer_pending? = @v2_handoff_offer_pending == true

  def process_v1_handoff
    I18n.with_locale(@assistant.account.locale) do
      Rails.logger.info(
        "[CAPTAIN][ResponseBuilderJob] Handoff requested for account=#{account.id} conversation=#{@conversation.display_id} " \
        "reason=#{@response&.dig('action_reason')}"
      )
      create_handoff_message
      @conversation.bot_handoff!
      send_out_of_office_message_if_applicable
    end
  end

  def process_v2_handoff
    # HandoffTool already ran bot_handoff! + OOO inside the agent loop. Preserve
    # waiting_since so this message doesn't clear the timestamp it left in place.
    I18n.with_locale(@assistant.account.locale) do
      create_handoff_message(preserve_waiting_since: true)
    end
  end

  def send_out_of_office_message_if_applicable
    # Campaign conversations should never receive OOO templates — the campaign itself
    # serves as the initial outreach, and OOO would be confusing in that context.
    return if @conversation.campaign.present?

    ::MessageTemplates::Template::OutOfOffice.perform_if_applicable(@conversation)
  end

  def create_handoff_message(preserve_waiting_since: false)
    content = generated_handoff_message.presence ||
              @assistant.config['handoff_message'].presence ||
              I18n.t('conversations.captain.handoff')
    @handoff_message = create_outgoing_message(content, preserve_waiting_since: preserve_waiting_since)
  end

  # The handoff farewell is LLM-generated from the conversation context, with
  # the configured/canned message as the fallback so a generation failure never
  # blocks handing off to a human.
  def generated_handoff_message
    result = Captain::Llm::HandoffMessageService.new(
      account: account,
      assistant: @assistant,
      conversation: @conversation
    ).perform
    result[:error] ? nil : result[:message]
  rescue StandardError => e
    Rails.logger.warn(
      "[CAPTAIN][ResponseBuilderJob] Handoff message generation failed for conversation=#{@conversation.display_id}: " \
      "#{e.class.name}: #{e.message}"
    )
    nil
  end

  # Capture runs outside the delivery transaction and never raises (the service
  # swallows its own failures): a session-logging bug must never roll back the
  # customer reply or trigger the top-level handle_error handoff on top of it.
  def capture_assistant_session(result_message:, credits_consumed:, outcome:)
    Captain::Assistant::SessionCaptureService.new(assistant: @assistant, conversation: @conversation, run_result: @run_result,
                                                  result_message: result_message, credits_consumed: credits_consumed, outcome: outcome).capture
  end

  # Persists the ordered decision trace (activated nodes, tool calls, handoffs,
  # final response) captured from the runner callbacks so the Debug tab can show
  # how Captain reasoned. Never raises and never rolls back the reply.
  def capture_decision_trace
    Captain::Assistant::DecisionTraceCaptureService.new(
      assistant: @assistant,
      conversation: @conversation,
      response: @response || {},
      decision_trace: @runner_service&.decision_trace || []
    ).capture
  end

  def handle_error(error)
    log_error(error)
    @response ||= {}
    @response['action_reason'] ||= error_action_reason(error)
    record_v2_response_failure(error_action_reason(error))
    process_error_handoff
    true
  end

  def process_error_handoff
    return unless conversation_pending?
    return if newer_customer_message_arrived?

    process_v1_handoff
    record_v2_failure_handoff(source: Captain::ConversationEvents::Sources::GENERATION_FAILURE)
  end

  def log_error(error)
    ChatwootExceptionTracker.new(error, account: account).capture_exception
  end

  def error_action_reason(error)
    error.class.name.underscore.tr('/', '_')
  end

  def newer_customer_message_arrived?
    return false if @responding_to_message_id.blank?

    Conversation.uncached do
      @conversation.messages
                   .captain_response_triggering
                   .exists?(['messages.id > ?', @responding_to_message_id])
    end
  end
end
