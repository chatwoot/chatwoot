# frozen_string_literal: true

# Generates friendly customer-facing notifications for Calendly booking events
#
# Example:
#   result = CalendlyNotificationAgent.call(
#     event_type: 'booked',
#     event_name: 'Discovery Call',
#     event_time: 'January 15, 2025 at 02:00 PM UTC',
#     contact_name: 'Sarah'
#   )
#   result.content  # => "Hi Sarah! Your Discovery Call is confirmed for January 15..."
#
class CalendlyNotificationAgent < ApplicationAgent
  description 'Generates friendly customer notifications for Calendly events'
  model 'gpt-4.1-nano'
  temperature 0.6

  on_failure do
    fallback to: ['gemini-2.5-flash']
  end

  param :event_type, required: true # booked, rescheduled, canceled
  param :event_name, required: true
  param :event_time, required: true
  param :contact_name, required: true
  param :cancellation_reason, default: nil

  system <<~PROMPT
    You are a friendly scheduling assistant. Generate a short customer-facing notification about a calendar event.

    Rules:
    - 1-2 sentences maximum
    - Warm, professional tone
    - No markdown formatting
    - No emojis
    - Include the event name and time
    - Address the customer by first name
    - For cancellations, be empathetic and brief
  PROMPT

  def user_prompt
    parts = ["Event: #{event_name}", "Time: #{event_time}", "Customer: #{contact_name}", "Type: #{event_type}"]
    parts << "Cancellation reason: #{cancellation_reason}" if cancellation_reason.present?
    parts.join("\n")
  end
end
