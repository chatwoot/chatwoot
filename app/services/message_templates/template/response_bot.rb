class MessageTemplates::Template::ResponseBot
  pattr_initialize [:conversation!]

  def perform
    ResponseBotJob.perform_later(conversation)
  end
end
