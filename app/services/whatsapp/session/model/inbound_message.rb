# A message as it arrived from WhatsApp, whatever the backend. This is what every inbound
# handler reads; the provider payload only survives in `raw`, which exists for the
# rich-message parser and for debugging.
class Whatsapp::Session::Model::InboundMessage < Data.define(
  :id, :chat, :sender, :from_me, :timestamp, :content, :quoted_id, :quoted_product, :mentions,
  :referral, :entry_point, :client_ref, :ephemeral, :raw
)
  include Whatsapp::Session::Model::Serializable

  coerce chat: Whatsapp::Session::Model::Address,
         sender: Whatsapp::Session::Model::Party,
         content: Whatsapp::Session::Model::Content,
         quoted_product: Whatsapp::Session::Model::Product,
         mentions: [Whatsapp::Session::Model::Address]
  defaults from_me: false

  def group?
    chat.group?
  end

  def incoming?
    !from_me
  end

  def sent_at
    Time.zone.at(timestamp / 1000.0)
  end

  # The party that wrote the message: in a group it is the participant, in a 1:1 chat the
  # chat itself (unless we sent it).
  def author
    sender || (from_me ? nil : Whatsapp::Session::Model::Party.from_address(chat))
  end
end
