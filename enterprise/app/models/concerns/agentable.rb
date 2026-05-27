module Concerns::Agentable
  extend ActiveSupport::Concern

  def agent
    agent_attributes = {
      name: agent_name,
      instructions: ->(context) { agent_instructions(context) },
      tools: agent_tools,
      model: agent_model,
      temperature: temperature.to_f || 0.7,
      response_schema: agent_response_schema
    }
    if agent_supports_provider?
      agent_attributes[:provider] = agent_provider
      agent_attributes[:assume_model_exists] = true
    end

    Agents::Agent.new(**agent_attributes)
  end

  def agent_instructions(context = nil)
    enhanced_context = prompt_context

    if context
      state = context.context[:state] || {}
      config = state[:assistant_config] || {}
      enhanced_context = enhanced_context.merge(
        conversation: state[:conversation] || {},
        contact: config['feature_contact_attributes'].present? ? state[:contact] : nil,
        campaign: state[:campaign] || {}
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
    InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value.presence || LlmConstants::DEFAULT_MODEL
  end

  def agent_provider
    Llm::Config.ruby_llm_provider
  end

  def agent_supports_provider?
    Agents::Agent.instance_method(:initialize).parameters.any? do |kind, name|
      %i[key keyreq].include?(kind) && name == :provider
    end
  end

  def agent_response_schema
    Captain::ResponseSchema if Llm::Config.supports_structured_outputs_with_tools?
  end

  def prompt_context
    raise NotImplementedError, "#{self.class} must implement prompt_context"
  end
end
