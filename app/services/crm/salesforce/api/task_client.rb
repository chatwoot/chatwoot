# frozen_string_literal: true

module Crm
  module Salesforce
    module Api
      # Client for Salesforce Task API
      class TaskClient < Crm::Salesforce::BaseClient
        # Create a new task
        #
        # @param task_data [Hash] Task data
        # @return [Hash] Response with task ID
        def create_task(task_data)
          request(:post, '/sobjects/Task', body: task_data.to_json)
        end

        # Update an existing task
        #
        # @param task_id [String] Salesforce Task ID
        # @param task_data [Hash] Task data
        # @return [Hash] Response
        def update_task(task_id, task_data)
          request(:patch, "/sobjects/Task/#{task_id}", body: task_data.to_json)
        end

        # Get task by ID
        #
        # @param task_id [String] Salesforce Task ID
        # @return [Hash] Task data
        def get_task(task_id)
          request(:get, "/sobjects/Task/#{task_id}")
        end

        # ============================================================================
        # EVENT OPERATIONS
        # ============================================================================

        # Create a new event (meeting)
        #
        # @param event_data [Hash] Event data
        # @return [Hash] Response with event ID
        def create_event(event_data)
          request(:post, '/sobjects/Event', body: event_data.to_json)
        end
      end
    end
  end
end
