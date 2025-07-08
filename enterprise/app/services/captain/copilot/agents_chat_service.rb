module Captain
  module Copilot
    class AgentsChatService
      def initialize(copilot_thread:, message_content:, conversation_id: nil, user_id: nil)
        @copilot_thread = copilot_thread
        @message_content = message_content
        @conversation_id = conversation_id
        @user_id = user_id

        # Set up user and account context
        @user = ::User.find(@user_id)
        @account = copilot_thread.account
      end

      def perform
        generate_response
      end

      private

      def generate_response
        # Check if required modules are available
        unless defined?(::Agents)
          Rails.logger.error '[ERROR] AgentsChatService: Agents module not defined'
          raise StandardError, 'AI Agents SDK not available'
        end

        unless defined?(Captain::Agents)
          Rails.logger.error '[ERROR] AgentsChatService: Captain::Agents module not defined'
          raise StandardError, 'Captain Agents module not available'
        end

        unless defined?(Captain::Agents::CopilotOrchestratorAgent)
          Rails.logger.error '[ERROR] AgentsChatService: CopilotOrchestratorAgent not defined'
          raise StandardError, 'CopilotOrchestratorAgent not available'
        end

        # Find the assistant
        assistant = Captain::Assistant.find(@copilot_thread.assistant_id)

        # Create the orchestrator agent
        agent = Captain::Agents::CopilotOrchestratorAgent.create(assistant, user: @user)

        # Build context for the agent
        context = build_context

        # Load persisted state from Redis
        context = load_persisted_state(context)

        # Create a runner and execute
        runner = ::Agents::Runner.with_agents(agent)

        # Setup callbacks for real-time UI updates
        setup_callbacks(runner)

        result = runner.run(@message_content, context: context)

        # Persist updated state to Redis
        persist_state(result.context) if result.respond_to?(:context) && result.context

        response_content = result.output

        # Generate and save the response
        response = { content: response_content, message_type: 'assistant' }

        save_response(response)
      rescue StandardError => e
        Rails.logger.error { "[ERROR] AgentsChatService: ERROR - #{e.class}: #{e.message}" }
        Rails.logger.error '[ERROR] AgentsChatService: FULL BACKTRACE:'
        e.backtrace.each { |line| Rails.logger.error "[ERROR] #{line}" }

        # Generate an error response
        error_response = {
          content: 'I apologize, but I encountered an error while processing your request. Please try again or contact support.',
          message_type: 'assistant'
        }
        save_response(error_response)
      end

      def build_context
        context = {
          conversation_history: build_conversation_history,
          state: {
            user_info: {
              id: @user.id,
              name: @user.name,
              email: @user.email,
              role: @user.respond_to?(:custom_role) ? @user.custom_role&.name : @user.class.name
            },
            account_info: {
              id: @account.id,
              name: @account.name,
              locale: @account.locale,
              domain: @account.domain,
              feature_flags: @account.feature_flags
            },
            current_time: Time.current.iso8601
          }
        }

        # Add current conversation context if available
        if @conversation_id.present?
          conversation = ::Conversation.find_by(display_id: @conversation_id, account_id: @account.id)
          if conversation
            context[:state][:current_conversation] = {
              id: conversation.id,
              display_id: conversation.display_id,
              status: conversation.status,
              contact_name: conversation.contact.name,
              assignee: conversation.assignee&.name,
              labels: conversation.labels.pluck(:name),
              last_activity: conversation.last_activity_at
            }
          end
        end

        context
      end

      def build_conversation_history
        history = []

        # Get all previous messages from the thread (excluding current message)
        previous_messages = @copilot_thread.copilot_messages
                                           .where.not(message_type: 'assistant_thinking')
                                           .order(:created_at)

        # this will also contain the current message
        previous_messages.each do |message|
          role = case message.message_type
                 when 'user' then 'user'
                 when 'assistant' then 'assistant'
                 else next # Skip unknown message types
                 end

          history << {
            content: message.message['content'],
            role: role
          }
        end

        history
      end

      def setup_callbacks(runner)
        runner.on_agent_thinking do |agent_name, _input|
          broadcast_thinking_message("#{agent_name} is thinking...")
        end

        runner.on_tool_start do |tool_name, _args|
          broadcast_thinking_message("Using #{tool_name}...")
        end

        runner.on_tool_complete do |tool_name, _result|
          broadcast_thinking_message("Completed #{tool_name}")
        end

        runner.on_agent_handoff do |from_agent, to_agent, _reason|
          broadcast_thinking_message("Handoff: #{from_agent} → #{to_agent}")
        end
      end

      def load_persisted_state(context)
        redis_key = "copilot_state:#{@copilot_thread.id}"

        begin
          persisted_state = Redis::Alfred.get(redis_key)
          if persisted_state
            # Merge persisted state with current context
            context[:state] = context[:state].merge(persisted_state.with_indifferent_access)
          end
        rescue StandardError => e
          Rails.logger.warn "Failed to load persisted state from Redis: #{e.message}"
        end

        context
      end

      def persist_state(context)
        redis_key = "copilot_state:#{@copilot_thread.id}"

        begin
          # Extract only the state we want to persist (excluding conversation_history)
          state_to_persist = context[:state]&.except(:conversation_history, :current_time) || {}

          # Set expiration to 24 hours
          Redis::Alfred.set(redis_key, state_to_persist, expire: 24.hours.to_i)
        rescue StandardError => e
          Rails.logger.warn "Failed to persist state to Redis: #{e.message}"
        end
      end

      def broadcast_thinking_message(content)
        message_data = { content: content }

        @copilot_thread.copilot_messages.create!(
          message_type: 'assistant_thinking',
          message: message_data
        )
      end

      def save_response(response)
        message_data = { content: response[:content] }

        @copilot_thread.copilot_messages.create!(
          message_type: response[:message_type],
          message: message_data
        )
      end
    end
  end
end
