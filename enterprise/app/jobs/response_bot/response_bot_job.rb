class ResponseBot::ResponseBotJob < ApplicationJob
  queue_as :medium

  def perform(conversation)
    ::Enterprise::MessageTemplates::ResponseBotService.new(conversation: conversation).perform
  end
end
