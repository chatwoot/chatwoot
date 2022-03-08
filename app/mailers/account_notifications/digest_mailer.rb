class AccountNotifications::DigestMailer < ApplicationMailer
  def send_email_digest(account, user, data, chart_data)
    return unless smtp_config_set_or_development?

    @account = account
    @data = data
    @chart_data = chart_data

    mail({
           to: user.email,
           from: from_email_with_name,
           subject: email_digest_subject
         })
  end

  def email_digest_subject
    if @data[:conversation_resolved] > 50
      "Whoa! You've reached new milestone in the customer satisfaction"
    elsif @data[:conversation_created] > 20
      "More people reaching out to #{@account.name}"
    elsif @data[:conversation_resolved] > 20
      'Pretty busy weeks to resolve all those cutomer questions.'
    elsif (@data[:conversation_resolved]).positive?
      'Superclass this week!'
    else
      'Check your customer satisfaction with us.'
    end
  end

  def from_email_with_name
    'Chatwoot Insights <accounts@chatwoot.com>'
  end
end
