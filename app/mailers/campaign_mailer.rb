class CampaignMailer < ApplicationMailer
  def email_drops
    {
      'contact' => ContactDrop.new(@contact),
      'agent' => UserDrop.new(@agent),
      'inbox' => InboxDrop.new(@inbox),
      'account' => AccountDrop.new(@account)
    }
  end

  def campaign_email(campaign:, contact:, inbox:, subject:, body:) # rubocop:disable Metrics/MethodLength
    @body = body
    @campaign = campaign
    @contact = contact
    @inbox = inbox
    @channel = inbox.channel
    @agent = inbox.members[0]
    @account = @agent.accounts[0]

    rendered_content = LiquidRenderer.new(body, email_drops).render

    mail_options = {
      to: contact.email,
      from: formatted_from_email,
      reply_to: reply_to_email,
      subject: subject,
      message_id: generate_message_id,
      content_type: 'text/html',
      body: rendered_content
    }

    apply_smtp_settings(mail_options)

    mail(mail_options)
  end

  private

  def formatted_from_email
    name = @inbox.business_name || @inbox.name || 'Campaign'
    "#{name} <#{from_email_address}>"
  end

  def from_email_address
    @channel.email || @campaign.account.support_email
  end

  def reply_to_email
    @channel.email || @campaign.account.support_email
  end

  def generate_message_id
    "<campaign/#{@campaign.id}/contact/#{@contact.id}@#{email_domain}>"
  end

  def email_domain
    @channel.email&.split('@')&.last || 'campaign.chatwoot.com'
  end

  def apply_smtp_settings(mail_options)
    return unless @inbox.inbox_type == 'Email' && @channel.smtp_enabled

    smtp_settings = {
      address: @channel.smtp_address,
      port: @channel.smtp_port,
      user_name: @channel.smtp_login,
      password: @channel.smtp_password,
      domain: @channel.smtp_domain,
      tls: @channel.smtp_enable_ssl_tls,
      enable_starttls_auto: @channel.smtp_enable_starttls_auto,
      openssl_verify_mode: @channel.smtp_openssl_verify_mode,
      authentication: @channel.smtp_authentication
    }

    mail_options[:delivery_method] = :smtp
    mail_options[:delivery_method_options] = smtp_settings
  end
end
