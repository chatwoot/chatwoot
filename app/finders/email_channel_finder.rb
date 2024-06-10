class EmailChannelFinder
  include EmailHelper

  def initialize(email_object)
    @email_object = email_object
  end

  def perform
    channel = nil

    recipient_mails.each do |email|
      normalized_email = normalize_email_with_plus_addressing(email)
      channel = Channel::Email.find_by('lower(email) = ? OR lower(forward_to_email) = ?', normalized_email, normalized_email)

      break if channel.present?
    end
    channel
  end

  def recipient_mails
    delivered_to_fields = @email_object.header.fields.select { |field| field.name == 'Delivered-To' }
    delivered_to_emails = delivered_to_fields.map { |field| field.value }
    puts "Delivered-To #{delivered_to_emails}}"
    # Delivered-To added for catch-all functionality.
    recipient_addresses = delivered_to_emails + @email_object.cc.to_a + @email_object.bcc.to_a + [@email_object['X-Original-To'].try(:value)]
    recipient_addresses.flatten.compact
  end
end
