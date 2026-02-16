# frozen_string_literal: true

# Tool for listing upcoming Calendly events for the current contact
# Used by AI agent to check if a customer has upcoming meetings
#
# Example usage in agent:
#   chat.with_tools([CalendlyListEventsTool])
#   response = chat.ask("Does this customer have any upcoming meetings?")
#
class CalendlyListEventsTool < BaseTool
  description 'List upcoming scheduled Calendly events. ' \
              'Use when checking if a customer has any upcoming meetings or appointments.'

  def execute
    validate_context!

    if playground_mode?
      return success_response(
        message: '[Playground] Would list upcoming Calendly events',
        events: []
      )
    end

    validate_calendly_enabled!
    events = fetch_upcoming_events

    success_response(
      events: events,
      message: events.any? ? "Found #{events.length} upcoming event(s)." : 'No upcoming events found.'
    )
  rescue StandardError => e
    error_response("Failed to list events: #{e.message}")
  end

  private

  def validate_calendly_enabled!
    raise ArgumentError, 'Calendly is not connected for this account.' unless calendly_hook
  end

  def fetch_upcoming_events
    events = api_client.list_scheduled_events(min_start_time: Time.current)
    events.first(10).map do |event|
      {
        name: event['name'],
        start_time: event['start_time'],
        end_time: event['end_time'],
        status: event['status'],
        uri: event['uri']
      }
    end
  end

  def calendly_hook
    @calendly_hook ||= current_account.hooks.find_by(app_id: 'calendly')
  end

  def api_client
    @api_client ||= Integrations::Calendly::ApiClient.new(calendly_hook)
  end
end
