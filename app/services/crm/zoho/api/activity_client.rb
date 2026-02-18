# frozen_string_literal: true

module Crm
  module Zoho
    module Api
      # Client for Zoho CRM Task and Event operations
      class ActivityClient < Crm::Zoho::BaseClient
        API_PATH = '/crm/v8'

        # ============================================================================
        # TASK OPERATIONS
        # ============================================================================

        # Create a new task in Zoho CRM
        #
        # @param task_data [Hash] Task data
        # @option task_data [Hash] :Owner Owner object with :id
        # @option task_data [Hash] :Who_Id Contact object with :id
        # @option task_data [Hash] :What_Id Related record object with :id
        # @option task_data [String] :$se_module Related module name
        # @option task_data [String] :Status Task status
        # @option task_data [String] :Priority Task priority
        # @option task_data [String] :Subject Task subject
        # @option task_data [String] :Due_Date Due date (YYYY-MM-DD)
        # @option task_data [String] :Description Task description
        # @option task_data [Boolean] :Send_Notification_Email Send notification
        # @return [Hash] API response
        def create_task(task_data)
          request(:post, "#{API_PATH}/Tasks", body: { data: [task_data] }.to_json)
        end

        # Update an existing task
        #
        # @param task_id [String] Zoho task ID
        # @param task_data [Hash] Updated task data
        # @return [Hash] API response
        def update_task(task_id, task_data)
          data_with_id = task_data.merge(id: task_id)
          request(:put, "#{API_PATH}/Tasks", body: { data: [data_with_id] }.to_json)
        end

        # Get task by ID
        #
        # @param task_id [String] Zoho task ID
        # @return [Hash] API response
        def get_task(task_id)
          request(:get, "#{API_PATH}/Tasks/#{task_id}")
        end

        # ============================================================================
        # EVENT OPERATIONS
        # ============================================================================

        # Create a new event in Zoho CRM
        #
        # @param event_data [Hash] Event data
        # @option event_data [Hash] :Owner Owner object with :id
        # @option event_data [Hash] :Who_Id Contact object with :id
        # @option event_data [Hash] :What_Id Related record object with :id
        # @option event_data [String] :$se_module Related module name
        # @option event_data [String] :Event_Title Event title
        # @option event_data [String] :Start_DateTime Start date/time (ISO 8601)
        # @option event_data [String] :End_DateTime End date/time (ISO 8601)
        # @option event_data [String] :Venue Event venue/location
        # @option event_data [String] :Description Event description
        # @option event_data [Array<Hash>] :Participants Array of participants
        # @option event_data [Boolean] :send_notification Send notification
        # @return [Hash] API response
        def create_event(event_data)
          request(:post, "#{API_PATH}/Events", body: { data: [event_data] }.to_json)
        end

        # Update an existing event
        #
        # @param event_id [String] Zoho event ID
        # @param event_data [Hash] Updated event data
        # @return [Hash] API response
        def update_event(event_id, event_data)
          data_with_id = event_data.merge(id: event_id)
          request(:put, "#{API_PATH}/Events", body: { data: [event_data_with_id] }.to_json)
        end

        # Get event by ID
        #
        # @param event_id [String] Zoho event ID
        # @return [Hash] API response
        def get_event(event_id)
          request(:get, "#{API_PATH}/Events/#{event_id}")
        end

        # ============================================================================
        # CALL OPERATIONS
        # ============================================================================

        # Create a call log in Zoho CRM
        #
        # @param call_data [Hash] Call data
        # @option call_data [Hash] :Who_Id Contact object with :id
        # @option call_data [Hash] :What_Id Related record object with :id
        # @option call_data [String] :Subject Call subject
        # @option call_data [String] :Call_Type Call type (Inbound/Outbound)
        # @option call_data [String] :Call_Start_Time Start time (ISO 8601)
        # @option call_data [String] :Call_Duration Duration in seconds
        # @option call_data [String] :Description Call description
        # @return [Hash] API response
        def create_call(call_data)
          request(:post, "#{API_PATH}/Calls", body: { data: [call_data] }.to_json)
        end
      end
    end
  end
end
