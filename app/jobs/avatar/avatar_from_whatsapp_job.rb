# Generates an initials-based avatar for WhatsApp contacts.
#
# The WhatsApp Cloud API does not provide an endpoint to fetch a contact's
# profile picture (the /contacts endpoint only exists in the On-Premises API).
# Instead, this job generates a PNG avatar with the contact's initials on a
# deterministic color background, similar to how WhatsApp itself renders
# contacts without a profile picture.
class Avatar::AvatarFromWhatsappJob < ApplicationJob
  queue_as :purgable

  # WhatsApp-inspired palette for avatar backgrounds
  AVATAR_COLORS = %w[
    #00A884 #25D366 #128C7E #075E54 #34B7F1
    #7C3AED #E11D48 #0891B2 #D97706 #059669
    #6366F1 #EC4899 #14B8A6 #F97316 #8B5CF6
  ].freeze

  def perform(contact, _channel = nil)
    return if contact.avatar.attached?

    initials = extract_initials(contact.name)
    bg_color = deterministic_color(contact.name)

    tempfile = generate_png(initials, bg_color)
    return if tempfile.blank?

    contact.avatar.attach(
      io: File.open(tempfile.path),
      filename: "whatsapp_avatar_#{contact.id}.png",
      content_type: 'image/png'
    )
  rescue StandardError => e
    Rails.logger.info "[WHATSAPP AVATAR] Could not generate avatar for contact #{contact.id}: #{e.message}"
  ensure
    tempfile&.close!
  end

  private

  def extract_initials(name)
    return '?' if name.blank?

    parts = name.strip.split(/\s+/)
    if parts.length >= 2
      "#{parts.first[0]}#{parts.last[0]}".upcase
    else
      parts.first[0..1].upcase
    end
  end

  def deterministic_color(name)
    AVATAR_COLORS[name.to_s.bytes.sum % AVATAR_COLORS.length]
  end

  def generate_png(initials, bg_color)
    tempfile = Tempfile.new(['avatar', '.png'])

    MiniMagick::Tool::Convert.new do |convert|
      convert.size '256x256'
      convert << "xc:#{bg_color}"
      convert.gravity 'center'
      convert.fill 'white'
      convert.font 'Noto-Sans-Bold'
      convert.pointsize '96'
      convert.annotate '+0+0', initials
      convert << tempfile.path
    end

    tempfile.rewind
    tempfile
  rescue StandardError => e
    Rails.logger.info "[WHATSAPP AVATAR] ImageMagick error: #{e.message}"
    tempfile&.close!
    nil
  end
end
