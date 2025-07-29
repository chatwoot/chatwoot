class PortalInstructionsMailer < ApplicationMailer
  def send_cname_instructions(portal:, recipient_email:, sender:)
    return unless smtp_config_set_or_development?

    @portal = portal
    @sender = sender
    @cname_record = generate_cname_record
    @account = portal.account

    send_mail_with_liquid(
      to: recipient_email,
      subject: "DNS Configuration Instructions for #{@portal.custom_domain}"
    )
  end

  private

  def liquid_droppables
    {
      portal: @portal,
      sender: @sender,
      account: @account
    }
  end

  def liquid_locals
    {
      cname_record: @cname_record
    }
  end

  def generate_cname_record
    target_domain = determine_target_domain
    "#{@portal.custom_domain} CNAME #{target_domain}"
  end

  def determine_target_domain
    helpcenter_url = ENV.fetch('HELPCENTER_URL', '')
    frontend_url = ENV.fetch('FRONTEND_URL', '')

    return extract_hostname(helpcenter_url) if helpcenter_url.present?
    return extract_hostname(frontend_url) if frontend_url.present?

    'chatwoot.help'
  end

  def extract_hostname(url)
    uri = URI.parse(url)
    uri.host
  rescue URI::InvalidURIError
    url.gsub(%r{https?://}, '').split('/').first
  end
end
