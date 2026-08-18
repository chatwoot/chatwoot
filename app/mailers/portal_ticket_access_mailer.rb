class PortalTicketAccessMailer < ApplicationMailer
  def access_link(portal:, contact:, verify_url:)
    return unless smtp_config_set_or_development?

    @portal = portal
    @action_url = verify_url

    send_mail_with_liquid(
      to: contact.email,
      subject: I18n.t('public_portal.tickets.access_mailer.subject', portal_name: @portal.name)
    )
  end

  private

  def liquid_locals
    super.merge(portal_name: @portal.name)
  end
end
