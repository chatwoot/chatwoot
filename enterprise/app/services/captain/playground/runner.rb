class Captain::Playground::Runner
  def initialize(assistant:, configuration_params:, message_history:)
    @assistant = assistant
    @configuration_params = configuration_params
    @message_history = message_history
  end

  def generate_response
    configuration = Captain::Playground::Configuration.new(
      assistant: @assistant,
      params: @configuration_params
    )
    run_details = Captain::Playground::RunDetails.new(configuration: configuration)
    response = agent_runner(configuration, run_details).generate_response(message_history: @message_history)
    response.merge(run_details: run_details.to_h(agent_name: response['agent_name']))
  end

  private

  def agent_runner(configuration, run_details)
    Captain::Assistant::AgentRunnerService.new(
      assistant: @assistant,
      callbacks: run_details.callbacks,
      source: 'playground',
      runtime_configuration: configuration
    )
  end
end
