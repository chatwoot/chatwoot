class AdminNotifications::AgentStatusMailer < ApplicationMailer
  def agent_went_online(agent, account, recipient_email)
    @agent = agent
    @account = account

    subject = "#{@agent.name} is now Online"

    mail(
      to: recipient_email,
      subject: subject
    )
  end

  def agent_went_offline(agent, account, recipient_email)
    @agent = agent
    @account = account

    subject = "#{@agent.name} is now Offline"

    mail(
      to: recipient_email,
      subject: subject
    )
  end
end
