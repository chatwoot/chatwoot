class PortalInstructionsMailer < ApplicationMailer
  def send_cname_instructions(portal:, recipient_email:)
    return unless smtp_config_set_or_development?
    return if target_domain.blank?

    @portal = portal
    @cname_record = generate_cname_record

    send_mail_with_liquid(
      to: recipient_email,
      subject: I18n.t('portals.send_instructions.subject', custom_domain: @portal.custom_domain)
    )
  end

  private

  def liquid_locals
    super.merge({ cname_record: @cname_record })
  end

  def generate_cname_record
    "#{@portal.custom_domain} CNAME #{target_domain}"
  end

  def target_domain
    helpcenter_url = ENV.fetch('HELPCENTER_URL', '')
    frontend_url = ENV.fetch('FRONTEND_URL', '')

    return extract_hostname(helpcenter_url) if helpcenter_url.present?
    return extract_hostname(frontend_url) if frontend_url.present?

    ''
  end

  def extract_hostname(url)
    uri = URI.parse(url)
    uri.host
  rescue URI::InvalidURIError
    url.gsub(%r{https?://}, '').split('/').first
  end
end
