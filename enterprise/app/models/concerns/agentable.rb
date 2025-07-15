module Agentable
  extend ActiveSupport::Concern

  included do
    def agent
      Agents::Agent.new(
        name: agent_name,
        instructions: ->(context) { agent_instructions(context) },
        tools: agent_tools,
        model: agent_model
      )
    end

    def agent_instructions(context = nil)
      enhanced_context = prompt_context

      if context
        state = context.context[:state] || {}
        conversation_data = state[:conversation] || {}
        enhanced_context = enhanced_context.merge(
          conversation: conversation_data,
          has_conversation: conversation_data.present?
        )
      end

      Captain::PromptRenderer.render(template_name, enhanced_context.with_indifferent_access)
    end

    private

    def agent_name
      raise NotImplementedError, "#{self.class} must implement agent_name"
    end

    def template_name
      self.class.name.demodulize.underscore
    end

    def agent_tools
      []  # Default implementation, override if needed
    end

    def agent_model
      'gpt-4.1-mini'
    end

    def prompt_context
      raise NotImplementedError, "#{self.class} must implement prompt_context"
    end
  end
end
