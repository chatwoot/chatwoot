class AgentBots::GptJob < ApplicationJob
  queue_as :bots

  def perform(event, agent_bot, message)
    event_data = { message: message }
    Integrations::Gpt::ProcessorService.new(
      event_name: event, agent_bot: agent_bot, event_data: event_data
    ).perform
  end
end
