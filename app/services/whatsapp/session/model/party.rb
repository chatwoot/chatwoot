# The human or business behind an address. WhatsApp addresses the same person by phone
# number and by LID depending on the chat, so both travel together and the resolver
# decides which one identifies the contact.
class Whatsapp::Session::Model::Party < Data.define(:phone, :lid, :push_name, :verified_name)
  include Whatsapp::Session::Model::Serializable

  def self.from_address(address, push_name: nil)
    return if address.nil?

    case address.kind
    when 'lid' then new(lid: address.id, push_name: push_name)
    when 'phone' then new(phone: address.id, push_name: push_name)
    end
  end

  def initialize(**attributes)
    super(
      phone: attributes[:phone]&.to_s&.delete('+').presence,
      lid: attributes[:lid]&.to_s&.delete_suffix('@lid').presence,
      push_name: attributes[:push_name].presence,
      verified_name: attributes[:verified_name].presence
    )
  end

  # contact_inboxes.source_id: the LID when WhatsApp gives us one, the phone otherwise.
  def source_id
    lid.presence || phone
  end

  # contacts.identifier, matching what the Baileys layer already persists.
  def identifier
    "#{lid}@lid" if lid.present?
  end

  # NOTE: `verified_name` only exists for business accounts and outranks `push_name`.
  def name
    verified_name.presence || push_name.presence
  end

  def phone_e164
    "+#{phone}" if phone.present?
  end

  def address
    lid.present? ? Whatsapp::Session::Model::Address.lid(lid) : Whatsapp::Session::Model::Address.phone(phone)
  end
end
