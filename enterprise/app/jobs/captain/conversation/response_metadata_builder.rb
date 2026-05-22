module Captain::Conversation::ResponseMetadataBuilder
  private

  def captain_response_metadata
    return unless captain_v2_enabled?

    {
      'version' => 'v2',
      'agent' => captain_agent_metadata(@response['agent_name']),
      'run' => captain_response_run_context
    }
  end

  def captain_handoff_metadata
    return unless captain_v2_enabled?

    {
      'version' => 'v2',
      'agent' => captain_agent_metadata(@response&.dig('agent_name') || assistant_agent_name),
      'run' => {
        'messages' => [],
        'handoff_tool_called' => true
      }
    }
  end

  def captain_response_run_context
    run_context = (@response['run_context'] || {}).deep_stringify_keys
    messages = Array(run_context['messages'])
    messages = fallback_captain_run_messages if messages.empty?

    {
      'messages' => messages,
      'handoff_tool_called' => @response['handoff_tool_called'] || false
    }
  end

  def fallback_captain_run_messages
    content = {}
    content['reasoning'] = @response['reasoning'] if @response['reasoning'].present?

    [
      {
        'role' => 'assistant',
        'content' => content,
        'agent_name' => @response['agent_name']
      }.compact
    ]
  end

  def captain_agent_metadata(agent_name)
    agent_name = agent_name.presence || assistant_agent_name
    scenario = @assistant.scenarios.enabled.find { |enabled_scenario| enabled_scenario.handoff_key == agent_name }

    return scenario_agent_metadata(scenario, agent_name) if scenario
    return assistant_agent_metadata(agent_name) if agent_name == assistant_agent_name

    unknown_agent_metadata(agent_name)
  end

  def scenario_agent_metadata(scenario, agent_name)
    {
      'name' => agent_name,
      'type' => 'scenario',
      'assistant_id' => @assistant.id,
      'scenario_id' => scenario.id,
      'handoff_key' => scenario.handoff_key
    }
  end

  def assistant_agent_metadata(agent_name)
    {
      'name' => agent_name,
      'type' => 'assistant',
      'assistant_id' => @assistant.id
    }
  end

  def unknown_agent_metadata(agent_name)
    {
      'name' => agent_name,
      'type' => 'unknown',
      'assistant_id' => @assistant.id
    }
  end

  def assistant_agent_name
    @assistant.name.parameterize(separator: '_')
  end
end
