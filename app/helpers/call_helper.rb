module CallHelper
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
  def get_call_log_string(callback_payload)
    agent_log = callback_payload['Legs'].first
    user_log = callback_payload['Legs'].last
    agent_call_status = agent_log['Status']
    user_call_status = user_log['Status']
    event_type = callback_payload['EventType']

    case event_type
    when 'terminal'
      return 'Call was connected to agent but they were busy' if agent_call_status == 'busy'
      return "Call was connected to agent but they didn't pick up the call" if agent_call_status == 'no-answer'
      return "The call failed, as it couldn't be connected to the user." if callback_payload['Status'] == 'failed' && user_call_status == 'canceled'

      if callback_payload['Status'] == 'completed'
        call_duration = format_duration_from_seconds(user_log['OnCallDuration'])
        "Call completed with user\n\nCall Duration: #{call_duration}\nCall recording link: #{callback_payload['RecordingUrl']}"
      end
    when 'answered'
      if agent_call_status == 'in-progress' && user_call_status == 'in-progress'
        'Both user and agent are on the call'
      elsif agent_call_status == 'in-progress'
        'Agent has picked up the call'
      end
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

  def format_duration_from_seconds(duration_seconds)
    hours = duration_seconds / 3600
    minutes = (duration_seconds % 3600) / 60
    remaining_seconds = duration_seconds % 60

    result = []
    result << "#{hours} hours" if hours.positive?
    result << "#{minutes} minutes" if minutes.positive?
    result << "#{remaining_seconds} seconds" if remaining_seconds.positive?

    result.join(' ')
  end
end
