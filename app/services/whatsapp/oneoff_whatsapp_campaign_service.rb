class Whatsapp::OneoffWhatsappCampaignService
  pattr_initialize [:campaign!]

  def perform
    raise "Invalid campaign #{campaign.id}" if campaign.inbox.inbox_type != 'Whatsapp' || !campaign.one_off?
    raise 'Completed Campaign' if campaign.completed?

    # marks campaign completed so that other jobs won't pick it up
    campaign.completed!

    audience_label_ids = campaign.audience.select { |audience| audience['type'] == 'Label' }.pluck('id')
    audience_labels = campaign.account.labels.where(id: audience_label_ids).pluck(:title)
    process_audience(audience_labels)
  end

  private

  delegate :inbox, to: :campaign
  delegate :channel, to: :inbox

  def process_audience(audience_labels)
    contacts = campaign.account.contacts.tagged_with(audience_labels, any: true)
    message_index = 0
    contacts.each do |contact|
      next if contact.phone_number.blank?

      # Apply delay before sending (except for first message)
      if message_index.positive?
        delay_seconds = campaign.calculate_delay
        if delay_seconds.positive?
          Rails.logger.info "[WhatsApp Campaign] Applying delay of #{delay_seconds} seconds before sending to contact #{contact.id}"
          sleep(delay_seconds)
        end
      end

      send_message(to: contact.phone_number, content: campaign.message)
      message_index += 1
    rescue StandardError => e
      Rails.logger.error "[WhatsApp Campaign] Failed to send message to contact #{contact.id}: #{e.message}"
    end
  end

  def send_message(to:, content:)
    # Create a proper message object that the WhatsApp provider expects
    message_object = OpenStruct.new(
      content: content,
      attachments: [],
      conversation: OpenStruct.new(
        contact_inbox: OpenStruct.new(source_id: nil),
        can_reply?: true
      ),
      additional_attributes: {},
      content_type: nil,
      content_attributes: {}
    )

    channel.send_message(to, message_object)
  end
end
