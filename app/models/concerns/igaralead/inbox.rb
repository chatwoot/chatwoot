# frozen_string_literal: true

module Igaralead::Inbox
  def baileys_whatsapp?
    channel_type == 'Channel::BaileysWhatsapp'
  end
end
