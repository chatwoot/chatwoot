module Concerns::Agentable
  extend ActiveSupport::Concern

  DEFAULT_TEMPERATURE = 0.5
  # Only these channels can verify a contact with HMAC, so only they get the customer identity prompt section
  HMAC_CHANNEL_TYPES = %w[Channel::WebWidget Channel::Api].freeze

  def agent(runtime_configuration: nil, runtime_agent_name: nil)
    model = agent_model
    Agents::Agent.new(
      name: runtime_agent_name || agent_name,
      instructions: ->(context) { agent_instructions(context, runtime_configuration: runtime_configuration) },
      tools: agent_tools,
      model: model,
      temperature: Llm::Models.temperature_for(model, temperature.presence&.to_f || DEFAULT_TEMPERATURE),
      response_schema: agent_response_schema
    )
  end

  def agent_instructions(context = nil, prompt_template: template_name, runtime_configuration: nil)
    enhanced_context = runtime_prompt_context(prompt_context, runtime_configuration)

    if context
      state = context.context[:state] || {}
      config = state[:assistant_config] || {}
      enhanced_context = enhanced_context.merge(
        current_time: format_current_time(state[:timezone]),
        conversation: state[:conversation] || {},
        contact: config['feature_contact_attributes'].present? ? state[:contact] : nil,
        contact_inbox: verifiable_contact_inbox(state),
        verified_email: state[:verified_email],
        campaign: state[:campaign] || {},
        message_length_limit: state[:message_length_limit]
      )
    end

    Captain::PromptRenderer.render(prompt_template, enhanced_context.with_indifferent_access)
  end

  def agent_model
    route = Llm::FeatureRouter.resolve(feature: 'assistant', account: account)
    return route[:model] if route[:source] == :account_override || account&.feature_enabled?('captain_integration')

    installation_model.presence || route[:model]
  end

  private

  def verifiable_contact_inbox(state)
    state[:contact_inbox] if HMAC_CHANNEL_TYPES.include?(state[:channel_type])
  end

  def runtime_prompt_context(context, runtime_configuration)
    return context unless runtime_configuration

    runtime_configuration.prompt_context_for(self, context)
  end

  def agent_name
    raise NotImplementedError, "#{self.class} must implement agent_name"
  end

  def template_name
    self.class.name.demodulize.underscore
  end

  def agent_tools
    []  # Default implementation, override if needed
  end

  def installation_model
    InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value
  end

  def agent_response_schema
    Captain::ResponseSchema
  end

  def format_current_time(timezone)
    tz = ActiveSupport::TimeZone[timezone] if timezone.present?
    time = tz ? Time.current.in_time_zone(tz) : Time.current
    time.strftime('%A, %B %d, %Y %I:%M %p %Z')
  end

  def prompt_context
    raise NotImplementedError, "#{self.class} must implement prompt_context"
  end
end
