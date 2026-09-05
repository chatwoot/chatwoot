module Integrations
  module Todoist
    class CreateTaskService
      pattr_initialize [:hook!, :conversation!]

      def perform
        return unless hooks_configured?

        title = "Resolved: #{conversation.display_id} — #{conversation.try(:title) || conversation.contact.try(:name)}"
        body = conversation.to_llm_text

        response = client.create_task(
          title,
          project_id: hook.settings['project_id'],
          due_string: hook.settings['due_string'],
          description: body
        )

        Rails.logger.info "Todoist task created for conversation #{conversation.display_id}" if response.success?
      rescue StandardError => e
        ChatwootExceptionTracker.new(e, account: hook.account).capture_exception
        Rails.logger.error "Todoist task creation failed for conversation #{conversation.display_id}: #{e.message}"
      end

      private

      def hooks_configured?
        hook.settings['api_token'].present?
      end

      def client
        @client ||= ::Todoist.new(hook.settings['api_token'])
      end
    end
  end
end