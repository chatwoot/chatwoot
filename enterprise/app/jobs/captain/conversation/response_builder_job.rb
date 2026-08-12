class Captain::Conversation::ResponseBuilderJob < ApplicationJob
  include Captain::Conversation::V1ActionClassifier
  include Captain::Conversation::V1FalsePromiseHandler
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
    @responding_to_message_id = responding_to_message_id if captain_v2_enabled?

    return log_non_pending unless conversation_pending?

    Current.executed_by = @assistant

    return generate_and_process_response unless captain_v2_enabled?

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

  def generate_and_process_response
    message_history = collect_previous_messages
    @response = Captain::Llm::AssistantChatService.new(assistant: @assistant, conversation: @conversation).generate_response(
      message_history: message_history
    )
    classify_v1_response_action(message_history) if conversation_pending?
    repair_v1_false_promise_response(message_history) if conversation_pending?
    process_response
  end

  def generate_response_with_v2
    runner_service = v2_runner_service
    message_history = Captain::Conversation::MessageHistoryBuilderService.new(conversation: @conversation).perform
    @response = runner_service.generate_response(message_history: message_history)
    @run_result = runner_service.last_run_result

    @v2_handoff_tool_completed = runner_service.handoff_completed?
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
    record_v2_response_failure(@response['error_reason']) if v2_generation_errored?

    if v2_handoff_tool_fired?
      process_v2_handoff_response
    elsif v1_handoff_requested?
      process_v1_handoff_request
    elsif conversation_pending?
      process_standard_response
    end
  end

  def process_v1_handoff_request
    # V1 only signals via the response string — no state has been touched yet. If
    # the conversation isn't pending anymore, a human took over mid-run; bail out
    # rather than posting a stale handoff message on top of their reply.
    return unless conversation_pending?

    process_v1_handoff
    record_v2_failure_handoff(source: Captain::ConversationEvents::Sources::GENERATION_FAILURE) if v2_generation_errored?
  end

  def process_standard_response
    message = nil
    ActiveRecord::Base.transaction do
      next if captain_v2_enabled? && newer_customer_message_arrived?

      message = create_messages
      Rails.logger.info("[CAPTAIN][ResponseBuilderJob] Incrementing response usage for #{account.id}")
      account.increment_response_usage
    end
    return unless message

    capture_assistant_session(result_message: message, credits_consumed: 1.0)
    record_v2_response_completed(message) if captain_v2_enabled?
  end

  def process_v2_handoff_response
    # Captain V1 infers completion from status. Captain V2 uses the completion
    # marker set inside the locked handoff.
    if captain_v2_enabled?
      return unless v2_handoff_tool_completed? || conversation_pending?

      v2_handoff_tool_completed? ? process_v2_handoff : process_v1_handoff
      record_v2_failure_handoff(source: Captain::ConversationEvents::Sources::TOOL) unless v2_handoff_tool_completed?
    else
      conversation_pending? ? process_v1_handoff : process_v2_handoff
    end

    capture_assistant_session(result_message: @handoff_message, credits_consumed: 0.0)
  end

  def v1_handoff_requested?
    legacy_v1_handoff_token? || classifier_v1_handoff_requested?
  end

  def classifier_v1_handoff_requested?
    @response['action'] == 'handoff'
  end

  def legacy_v1_handoff_token?
    @response['response'] == 'conversation_handoff'
  end

  def v2_handoff_tool_fired? = @response['handoff_tool_called']
  def v2_handoff_tool_completed? = @v2_handoff_tool_completed == true

  def process_v1_handoff
    I18n.with_locale(@assistant.account.locale) do
      Rails.logger.info(
        "[CAPTAIN][ResponseBuilderJob] V1 handoff requested for account=#{account.id} conversation=#{@conversation.display_id} " \
        "source=#{@response&.dig('action_source') || 'legacy'} reason=#{@response&.dig('action_reason')}"
      )
      create_handoff_message
      @conversation.bot_handoff!
      report_v1_handoff_not_executed if conversation_pending?
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
    @handoff_message = create_outgoing_message(
      @assistant.config['handoff_message'].presence || I18n.t('conversations.captain.handoff'),
      preserve_waiting_since: preserve_waiting_since
    )
  end

  # Capture runs outside the delivery transaction and never raises (the service
  # swallows its own failures): a session-logging bug must never roll back the
  # customer reply or trigger the top-level handle_error handoff on top of it.
  def capture_assistant_session(result_message:, credits_consumed:)
    Captain::Assistant::SessionCaptureService.new(assistant: @assistant, conversation: @conversation, run_result: @run_result,
                                                  result_message: result_message, credits_consumed: credits_consumed).capture
  end

  def handle_error(error)
    log_error(error)
    @response ||= {}
    @response['action_source'] ||= 'error'
    @response['action_reason'] ||= error_action_reason(error)
    record_v2_response_failure(error_action_reason(error)) if captain_v2_enabled?
    process_error_handoff
    true
  end

  def process_error_handoff
    return unless conversation_pending?
    return if captain_v2_enabled? && newer_customer_message_arrived?

    process_v1_handoff
    record_v2_failure_handoff(source: Captain::ConversationEvents::Sources::GENERATION_FAILURE) if captain_v2_enabled?
  end

  def log_error(error)
    ChatwootExceptionTracker.new(error, account: account).capture_exception
  end

  def error_action_reason(error)
    error.class.name.underscore.tr('/', '_')
  end

  def captain_v2_enabled?
    account.feature_enabled?('captain_integration_v2')
  end

  def report_v1_handoff_not_executed
    error = StandardError.new("Captain V1 handoff requested but conversation #{@conversation.display_id} is still pending")
    ChatwootExceptionTracker.new(error, account: account).capture_exception
    Rails.logger.error(
      "[CAPTAIN][ResponseBuilderJob] V1 handoff requested but not executed for account=#{account.id} " \
      "conversation=#{@conversation.display_id}"
    )
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
