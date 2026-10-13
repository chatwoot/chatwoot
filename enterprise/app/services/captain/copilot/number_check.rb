# Asks the model once per turn to source or drop numbers that no tool result or agent message contains, such as a count
# it tallied from display pages, and reports the numbers still unsourced after that.
class Captain::Copilot::NumberCheck
  NOTE = 'Automatic check, not a message from the agent: these numbers in your answer do not appear in any tool result: ' \
         '%<numbers>s. Every number must come from a tool result, or be a ratio or percentage of two numbers a tool returned. ' \
         'Recompute counts with get_data, using group_by for counts per period or value, or remove each number you cannot ' \
         'source. Then give the complete answer again.'.freeze

  def initialize(run, token)
    @run = run
    @token = token
  end

  # The note for the model, or nil when the answer needs none or this turn was already checked.
  def request(answer)
    return if @run.context.key?('number_check')

    unsupported = unsupported(answer)
    @run.with_lease(@token) { @run.update!(context: @run.context.merge('number_check' => unsupported)) }
    format(NOTE, numbers: unsupported.join(', ')) if unsupported.any?
  end

  def remaining(answer)
    @run.context['number_check'].present? ? unsupported(answer) : []
  end

  private

  # Everything the model was given in this thread: the agent's messages, and every tool call and its result.
  def unsupported(answer)
    steps = CopilotRunStep.where(copilot_run: @run.copilot_thread.copilot_runs.chat)
    sources = [@run.copilot_thread.copilot_messages.user.map(&:message), steps.pluck(:arguments, :result), @run.user_id, @run.account_id]
    Captain::Copilot::AnswerNumbers.new(answer, sources).unsupported
  end
end
