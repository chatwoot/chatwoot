class ResponseBotJob < ApplicationJob
  queue_as :medium

  def perform(conversation)
    MessageTemplates::Template::ResponseBotService.new(conversation: conversation).perform
  end
end
