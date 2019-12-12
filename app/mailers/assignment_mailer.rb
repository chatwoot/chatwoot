class AssignmentMailer < ApplicationMailer
  default from: ENV.fetch('MAILER_SENDER_EMAIL', 'accounts@chatwoot.com')
  layout 'mailer'

  def conversation_assigned(conversation, agent)
    return if ENV.fetch('SMTP_ADDRESS', nil).blank?

    @agent = agent
    @conversation = conversation
    mail(to: @agent.email, subject: "#{@agent.name}, A new conversation [ID - #{@conversation.display_id}] has been assigned to you.")
  end
end
