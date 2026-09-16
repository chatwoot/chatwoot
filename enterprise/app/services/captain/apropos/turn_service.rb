class Captain::Apropos::TurnService
  def initialize(session)
    @session = session
  end

  def perform
    return unless claim_turn

    @session.reload
    runtime = Captain::Apropos::Runtime.new(
      account: @session.account, user: @session.user, state: @session.state,
      execution: { budget: { calls: 0, queries: 0 }, depth: 0, trace_context: { session_id: @session.id, turn_id: @turn_id } },
      on_event: ->(event) { @session.update!(trace: @session.trace + [event.merge('turn_id' => @turn_id)]) }
    )
    result = run_agent(runtime)
    finish('ready', result.is_a?(String) ? result : JSON.pretty_generate(result), runtime)
  rescue StandardError => e
    finish('failed', e.message, runtime)
    Rails.logger.error("[Apropos] Session #{@session.id}: #{e.class}: #{e.message}")
  end

  private

  def run_agent(runtime)
    Current.user = @session.user
    Current.account = @session.account
    history = @session.messages[0...-1].last(20).map { |message| { role: message.fetch('role').to_sym, content: message.fetch('content') } }
    runtime.ask(@session.messages.last.fetch('content'), history: history)
  ensure
    Current.reset
  end

  def claim_turn
    @session.with_lock do
      next false unless @session.status == 'queued'

      messages = @session.messages.deep_dup
      @turn_id = messages.last['turn_id'] ||= SecureRandom.uuid
      @session.update!(status: 'running', messages: messages)
      true
    end
  end

  def finish(status, content, runtime)
    @session.update!(
      status: status, state: runtime ? runtime.state : @session.state,
      messages: @session.messages + [{ 'role' => 'assistant', 'content' => content, 'error' => status == 'failed', 'turn_id' => @turn_id }]
    )
  end
end
