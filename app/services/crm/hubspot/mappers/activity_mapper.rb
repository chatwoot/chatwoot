# frozen_string_literal: true

module Crm
  module Hubspot
    module Mappers
      # Maps Nauto Console data to HubSpot Task / Meeting / Deal / Note payloads.
      # All payloads include inline associations (no separate association request needed).
      class ActivityMapper
        # HubSpot association type IDs (HUBSPOT_DEFINED)
        ASSOC_CONTACT_TO_TASK    = 204
        ASSOC_CONTACT_TO_MEETING = 200
        ASSOC_CONTACT_TO_DEAL    = 3
        ASSOC_CONTACT_TO_NOTE    = 207

        # Build task payload
        def self.map_task(params = {})
          properties = {
            hs_task_subject: params[:subject] || 'Task from Nauto Console',
            hs_task_status: params[:status] || 'NOT_STARTED',
            hs_timestamp: params[:due_date] || Time.current.iso8601
          }

          properties[:hs_task_body] = params[:description] if params[:description].present?
          properties[:hubspot_owner_id] = params[:owner_id] if params[:owner_id].present?

          build_payload(properties, params[:contact_id], ASSOC_CONTACT_TO_TASK)
        end

        # Build meeting payload
        def self.map_meeting(params = {})
          start_time = params[:start_time].presence || (Time.current + 1.hour).iso8601
          end_time = params[:end_time].presence || (Time.zone.parse(start_time.to_s) + 1.hour).iso8601

          properties = {
            hs_meeting_title: params[:subject] || 'Meeting from Nauto Console',
            hs_meeting_start_time: start_time,
            hs_meeting_end_time: end_time,
            hs_timestamp: end_time
          }

          properties[:hs_meeting_location] = params[:venue] if params[:venue].present?
          properties[:hs_meeting_body] = params[:description] if params[:description].present?
          properties[:hubspot_owner_id] = params[:owner_id] if params[:owner_id].present?

          build_payload(properties, params[:contact_id], ASSOC_CONTACT_TO_MEETING)
        end

        # Build deal payload
        def self.map_deal(params = {})
          properties = {
            dealname: params[:name] || 'Deal from Nauto Console',
            dealstage: params[:stage] || 'prospecting',
            closedate: params[:close_date] || (Date.current + 30.days).iso8601
          }

          properties[:amount] = params[:amount].to_s if params[:amount].present?
          properties[:description] = params[:description] if params[:description].present?

          build_payload(properties, params[:contact_id], ASSOC_CONTACT_TO_DEAL)
        end

        # Build note payload
        def self.map_note(params = {})
          properties = {
            hs_note_title: params[:note_title] || 'Note from Nauto Console',
            hs_note_body: params[:note_text] || '',
            hs_timestamp: Time.current.iso8601
          }

          build_payload(properties, params[:contact_id], ASSOC_CONTACT_TO_NOTE)
        end

        # Wrap properties + optional inline association
        def self.build_payload(properties, contact_id, assoc_type_id)
          payload = { properties: properties }
          assoc = contact_association(contact_id, assoc_type_id)
          payload[:associations] = assoc unless assoc.empty?
          payload
        end

        # Build HubSpot inline association array for a contact
        def self.contact_association(contact_id, type_id)
          return [] unless contact_id.present?

          [{
            to: { id: contact_id.to_s },
            types: [{ associationCategory: 'HUBSPOT_DEFINED', associationTypeId: type_id }]
          }]
        end
      end
    end
  end
end
