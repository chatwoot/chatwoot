class CampaignMailerService
  def initialize(campaign, contacts)
    @campaign = campaign
    @inbox = campaign.inbox
    @contacts = contacts
  end

  def send_bulk_emails
    @contacts.each do |contact|
      Rails.logger.info("Sending to contact #{contact}")
      next unless contact.email.present?

      CampaignMailer.campaign_email(
        campaign: @campaign,
        contact: contact,
        inbox: @inbox,
        subject: @campaign.title,
        body: render_body(contact)
      ).deliver_later
    end
  end

  private

  def render_body(contact)
    # Optional simple templating
    @campaign.message.gsub('{{name}}', contact.name || 'there')
  end
end
