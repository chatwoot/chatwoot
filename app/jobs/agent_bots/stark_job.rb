class AgentBots::StarkJob < ApplicationJob
  queue_as :high

  def perform(event, agent_bot, message)
    event_data = { message: message }
    Integrations::Stark::ProcessorService.new(
      event_name: event, hook: agent_bot, event_data: event_data
    ).perform
  end
end
