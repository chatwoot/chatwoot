# frozen_string_literal: true

# Provides Calendly scheduling support for conversation agents
module CalendlySupport
  extend ActiveSupport::Concern

  private

  def calendly_instructions
    return nil unless calendly_access_enabled?

    <<~PROMPT
      #{section_header('SCHEDULING & APPOINTMENTS')}

      You can help customers schedule, check, and manage appointments via Calendly.

      When to use scheduling tools:
      * Customer asks to book, schedule, or set up a meeting/appointment/call
      * Customer asks about available times or slots
      * Customer wants to check their upcoming appointments

      Workflow:
      1. If the customer wants to book — use book_meeting to find availability and generate a booking link
      2. If the customer only asks about availability — use check_availability first
      3. If the customer asks about existing appointments — use list_events
      4. Always share the booking link with the customer after generating one

      Rules:
      * Ask for the customer's preferred date/time range before checking availability
      * Present available slots clearly and concisely
      * Do NOT book without the customer's explicit confirmation of the time slot
    PROMPT
  end

  def calendly_tools
    return [] unless calendly_access_enabled?

    [CalendlyShareLinkTool, CalendlyCheckAvailabilityTool, CalendlyListEventsTool, CalendlyBookMeetingTool]
  end

  def calendly_access_enabled?
    current_assistant&.feature_calendly_enabled? && calendly_connected?
  end

  def calendly_connected?
    current_account&.hooks&.exists?(app_id: 'calendly')
  end
end
