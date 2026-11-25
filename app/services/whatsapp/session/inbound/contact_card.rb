# Reading one card out of a shared-contact payload.
#
# Pure text handling with nothing of the writer's state in it, which is why it is here
# rather than in `MessageWriter`: the same card is read on the writing path and on the
# recovery path, and both want the same answer.
module Whatsapp::Session::Inbound::ContactCard
  module_function

  # The WhatsApp vCard TEL line is `...;waid=<digits>:<formatted phone>`, so the formatted
  # number is preferred and the waid digits are the fallback. Same reading the Baileys
  # layer does, kept so a card with nothing else still lands.
  def phone_in(vcard)
    vcard = vcard.to_s
    vcard[/waid=\d+:\s*([^\r\n]+)/, 1]&.strip.presence || vcard[/waid=(\d+)/, 1].presence
  end

  def name_in(vcard)
    vcard.to_s[/^FN[^:]*:\s*([^\r\n]+)/, 1]&.strip.presence
  end

  # Whether a card says anything a row could show. A card that says nothing takes no row
  # on the writing path, so it does not make a share of one into a share of several.
  def readable?(card)
    card = card.to_h.stringify_keys

    card['phone'].presence || card['display_name'].presence ||
      phone_in(card['vcard']) || name_in(card['vcard'])
  end

  def line(name, phone)
    return name if phone.blank?
    return phone if name.blank? || name.start_with?('+')

    "#{name} - #{phone}"
  end
end
