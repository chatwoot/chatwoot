# A WhatsApp addressable entity, stripped of the transport details: `id` never carries the
# @server suffix, the device (`:3`) or the agent (`_1`) part. Every place that used to
# build or split a JID by hand goes through this class.
class Whatsapp::Session::Model::Address < Data.define(:kind, :id)
  include Whatsapp::Session::Model::Serializable

  KINDS = %w[phone lid group newsletter broadcast status].freeze

  # Mirrors Baileys' jid-utils server table, which is also what whatsmeow emits.
  SERVER_KINDS = {
    's.whatsapp.net' => 'phone',
    'c.us' => 'phone',
    'lid' => 'lid',
    'g.us' => 'group',
    'newsletter' => 'newsletter',
    'broadcast' => 'broadcast'
  }.freeze

  KIND_SERVERS = {
    'phone' => 's.whatsapp.net',
    'lid' => 'lid',
    'group' => 'g.us',
    'newsletter' => 'newsletter',
    'broadcast' => 'broadcast',
    'status' => 'broadcast'
  }.freeze

  STATUS_ID = 'status'.freeze

  class << self
    def parse(jid)
      return if jid.blank?

      user, server = jid.to_s.split('@', 2)
      # `<user>_<agent>:<device>` — only the user part identifies the party
      user = user.to_s.split(':').first.to_s.split('_').first
      kind = SERVER_KINDS[server]
      kind = 'status' if server == 'broadcast' && user == STATUS_ID
      raise Whatsapp::Session::Errors::InvalidPayload, "unknown whatsapp jid: #{jid}" if kind.nil?

      new(kind: kind, id: user)
    end

    def phone(digits)
      digits.blank? ? nil : new(kind: 'phone', id: digits.to_s.delete('+'))
    end

    def lid(digits)
      digits.blank? ? nil : new(kind: 'lid', id: digits.to_s.delete_suffix('@lid'))
    end

    def group(id)
      id.blank? ? nil : new(kind: 'group', id: id.to_s.split('@').first)
    end

    # The address to reach a contact at, replacing the four divergent `recipient_id` rules
    # in Channel::Whatsapp. The identifier (LID or group JID) is authoritative when
    # present, because that is what the provider echoes back.
    def for_contact(contact)
      identifier = contact.identifier.presence
      return parse(identifier) if whatsapp_jid?(identifier)

      phone(contact.phone_number)
    end

    # `identifier` is account-wide, not per-inbox, and another channel may own it: an API
    # inbox writes the customer's id there, and that id is often an e-mail. Reading one of
    # those as an address makes the contact unreachable on WhatsApp, number and all, so
    # only a JID this layer knows the server of counts.
    def whatsapp_jid?(value)
      SERVER_KINDS.key?(value.to_s.split('@', 2).last)
    end
  end

  def initialize(kind:, id:)
    kind = kind.to_s
    raise Whatsapp::Session::Errors::InvalidPayload, "unknown whatsapp address kind: #{kind}" unless KINDS.include?(kind)
    raise Whatsapp::Session::Errors::InvalidPayload, 'whatsapp address id is required' if id.blank?

    super(kind: kind, id: id.to_s)
  end

  def to_jid
    "#{id}@#{KIND_SERVERS.fetch(kind)}"
  end

  def phone?
    kind == 'phone'
  end

  def lid?
    kind == 'lid'
  end

  def group?
    kind == 'group'
  end

  # Chats we never open a conversation for.
  def ignorable?
    kind.in?(%w[status broadcast newsletter])
  end

  # The `<lid>@lid` value stored in contacts.identifier, or the group JID for groups.
  def identifier
    to_jid if lid? || group?
  end
end
