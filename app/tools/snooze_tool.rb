# frozen_string_literal: true

# Tool for snoozing conversations until a specific time
# Used by AI agent to temporarily pause conversations when follow-up is needed later
#
# Example usage in agent:
#   chat.with_tools([SnoozeTool])
#   response = chat.ask("Snooze this for 2 hours while the customer checks their order")
#
class SnoozeTool < BaseTool
  description 'Snooze this conversation until a specified time. Use when: ' \
              '1) The customer needs time to take action (check order, try solution), ' \
              '2) Following up later is needed, ' \
              '3) Waiting for an external event or deadline.'

  param :until_time, type: :string,
                     desc: 'When to reopen: ISO8601 datetime, Unix timestamp, or relative time like "1 hour", "2 days", "tomorrow"',
                     required: true
  param :reason, type: :string, desc: 'Explanation of why the conversation is being snoozed', required: false

  # Relative time patterns: matches strings like "1 hour", "2 days", "30 minutes"
  RELATIVE_TIME_PATTERNS = [
    { pattern: /\A(\d+)\s*minutes?\z/i, handler: ->(m) { m[1].to_i.minutes.from_now } },
    { pattern: /\A(\d+)\s*hours?\z/i, handler: ->(m) { m[1].to_i.hours.from_now } },
    { pattern: /\A(\d+)\s*days?\z/i, handler: ->(m) { m[1].to_i.days.from_now } },
    { pattern: /\A(\d+)\s*weeks?\z/i, handler: ->(m) { m[1].to_i.weeks.from_now } },
    { pattern: /\Atomorrow\z/i, handler: ->(_) { 1.day.from_now.beginning_of_day + 9.hours } },
    { pattern: /\Anext\s*week\z/i, handler: ->(_) { 1.week.from_now.beginning_of_day + 9.hours } }
  ].freeze

  def execute(until_time:, reason: nil)
    validate_context!

    if playground_mode?
      return success_response({
                                snoozed: true,
                                message: "[Playground] Would snooze conversation until #{until_time}",
                                until_time: until_time
                              })
    end

    return error_response('Conversation is already snoozed') if current_conversation.snoozed?

    parsed_time = parse_snooze_time(until_time)
    return parse_error if parsed_time.nil?
    return error_response('Snooze time must be in the future') if parsed_time <= Time.current

    perform_snooze(until_time: until_time, parsed_time: parsed_time, reason: reason)
  rescue StandardError => e
    handle_error(until_time: until_time, error: e)
  end

  private

  def perform_snooze(until_time:, parsed_time:, reason:)
    add_snooze_note(reason: reason, until_time: parsed_time) if reason.present?
    current_conversation.update!(status: :snoozed, snoozed_until: parsed_time)

    build_success_response(parsed_time: parsed_time)
  end

  def build_success_response(parsed_time:)
    success_response(
      snoozed: true, conversation_id: current_conversation.id, snoozed_until: parsed_time.iso8601,
      human_readable: human_readable_time(parsed_time), message: "Conversation snoozed until #{human_readable_time(parsed_time)}"
    )
  end

  def parse_error
    error_response('Could not parse the snooze time. Use formats like "2 hours", "1 day", "tomorrow", or ISO8601 datetime')
  end

  def handle_error(until_time:, error:)
    error_response("Failed to snooze conversation: #{error.message}")
  end

  def parse_snooze_time(time_string)
    return nil if time_string.blank?

    time_string = time_string.to_s.strip

    # Try Unix timestamp (all digits)
    if time_string.match?(/\A\d{10,13}\z/)
      timestamp = time_string.to_i
      timestamp /= 1000 if timestamp > 9_999_999_999 # Handle milliseconds
      return Time.zone.at(timestamp)
    end

    # Try relative time patterns
    RELATIVE_TIME_PATTERNS.each do |config|
      match = time_string.match(config[:pattern])
      return config[:handler].call(match) if match
    end

    # Try ISO8601 / standard datetime parsing
    DateTime.parse(time_string).to_time
  rescue ArgumentError
    nil
  end

  def add_snooze_note(reason:, until_time:)
    current_conversation.messages.create!(
      account: current_account,
      inbox: current_conversation.inbox,
      message_type: :activity,
      content: "**Snoozed until #{human_readable_time(until_time)}:** #{reason}",
      private: true,
      content_attributes: {
        'aloo_snoozed' => true,
        'snooze_reason' => reason,
        'snoozed_until' => until_time.iso8601
      }
    )
  end

  def human_readable_time(time)
    time.strftime('%B %d, %Y at %I:%M %p')
  end
end
