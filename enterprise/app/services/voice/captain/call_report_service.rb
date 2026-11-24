# Adds what Captain and the caller said to the conversation once Vapi reports the call ended
class Voice::Captain::CallReportService
  ROLE_LABELS = { 'user' => 'Caller', 'bot' => 'Captain', 'assistant' => 'Captain' }.freeze

  pattr_initialize [:session!, :report!]

  def perform
    session.conversation.messages.create!(
      account_id: session.account_id,
      inbox_id: session.inbox_id,
      message_type: :outgoing,
      private: true,
      sender: session.assistant,
      content: content
    )
  end

  private

  def content
    [
      '**Call answered by Captain**',
      summary.presence && "**Summary:** #{summary}",
      "**Ended:** #{report['endedReason'].to_s.humanize}",
      "**Transcript**\n#{transcript}"
    ].compact.join("\n\n")
  end

  def summary
    report.dig('analysis', 'summary')
  end

  def transcript
    lines = Array(report.dig('artifact', 'messages')).filter_map do |message|
      label = ROLE_LABELS[message['role']]
      "#{label}: #{message['message']}" if label && message['message'].present?
    end
    lines.join("\n")
  end
end
