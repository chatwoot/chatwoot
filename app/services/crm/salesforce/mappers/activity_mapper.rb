# frozen_string_literal: true

module Crm
  module Salesforce
    module Mappers
      # Maps Nauto Console data to Salesforce Task/Event format
      class ActivityMapper
        # Map to Salesforce Task format
        #
        # @param params [Hash] Task parameters
        # @return [Hash] Salesforce Task data
        def self.map_task(subject:, description: nil, due_date: nil, priority: 'Normal', status: 'Not Started', who_id: nil, what_id: nil)
          {
            Subject: subject,
            Description: description,
            ActivityDate: due_date || Date.current.to_s,
            Priority: priority, # High, Normal, Low
            Status: status, # Not Started, In Progress, Completed, Waiting on someone else, Deferred
            WhoId: who_id, # Lead or Contact ID
            WhatId: what_id # Account, Opportunity, etc.
          }.compact
        end

        # Map to Salesforce Event format
        #
        # @param appointment_or_params [Appointment, Hash] Appointment model or params hash
        # @param params [Hash] Additional parameters (usado cuando el primer arg es Appointment)
        # @return [Hash] Salesforce Event data
        def self.map_event(appointment_or_params, params = {})
          is_appointment = appointment_or_params.is_a?(Appointment)
          p = is_appointment ? params : appointment_or_params

          subject = if is_appointment
                      appointment_or_params.description.presence
                    else
                      p[:subject] || p[:event_title]
                    end
          subject ||= 'Meeting from Nauto Console'

          start_at = if is_appointment
                       appointment_or_params.scheduled_at
                     else
                       p[:start_time] || p[:scheduled_at] || Time.current + 1.hour
                     end
          start_at = Time.zone.parse(start_at) if start_at.is_a?(String)

          end_at = if is_appointment
                     appointment_or_params.ended_at || appointment_or_params.scheduled_at + 1.hour
                   else
                     p[:end_time] || start_at + 1.hour
                   end

          location = is_appointment ? appointment_or_params.location : p[:venue]
          description = is_appointment ? appointment_or_params.description : p[:description]

          {
            Subject: subject,
            StartDateTime: format_datetime(start_at),
            EndDateTime: format_datetime(end_at),
            Location: location,
            Description: description,
            WhoId: p[:who_id],
            WhatId: p[:what_id],
            IsAllDayEvent: false
          }.compact
        end

        # Format datetime for Salesforce (ISO 8601)
        #
        # @param datetime [DateTime, Time] DateTime object
        # @return [String] ISO 8601 formatted datetime
        def self.format_datetime(datetime)
          return nil unless datetime
          return datetime if datetime.is_a?(String)

          datetime.utc.iso8601
        end
      end
    end
  end
end
