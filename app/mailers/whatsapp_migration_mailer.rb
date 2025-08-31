# frozen_string_literal: true

class WhatsappMigrationMailer < ApplicationMailer
  def official_api_confirmation(account, user, channel)
    @account = account
    @user = user
    @channel = channel
    @phone_number = channel.phone_number
    
    mail(
      to: user.email,
      subject: "WhatsApp Official API Connected - #{@account.name}",
      template_name: 'official_api_confirmation'
    )
  end
  
  def unofficial_risk_notification(account, user, channel)
    @account = account
    @user = user
    @channel = channel
    @phone_number = channel.phone_number
    
    mail(
      to: user.email,
      subject: "WhatsApp Unofficial Connection Risk - #{@account.name}",
      template_name: 'unofficial_risk_notification'
    )
  end
end