# What changed in a group, as this provider reports it: whatsmeow's `GroupChange` with
# every field the event did not touch left null.
#
# Which of the arrays is populated is the whole signal. There is no event type on a
# membership change, and `nil` has to keep meaning "not reported": read as `false`, an
# untouched setting would be applied as one somebody just turned off.
class Whatsapp::Session::Backends::Uazapi::GroupChangeMapper
  # Each action names the same people twice, once by number and once by LID.
  ACTIONS = %w[Join Leave Promote Demote].freeze

  attr_reader :event

  def initialize(event)
    @event = event
  end

  # Returns the canonical changes, or nil when the event reports none.
  def perform
    changes = events::GroupUpdated::Changes.new(**settings, **participants)
    changes if changes.any?
  end

  # Whether the event named a change this contract has no truthful way to carry, which is
  # not the same as naming no change at all. The caller answers it with a `group.activity`,
  # so the group is read from a snapshot instead of from an assertion.
  def uncarried?
    event[:MembershipApprovalMode].present?
  end

  private

  def model = Whatsapp::Session::Model
  def events = Whatsapp::Session::Model::Events

  # No `join_approval`, and its absence is the correction. Measured against real accounts on
  # 10/09/2026: turning approval on and turning it off both arrive as
  # `MembershipApprovalMode: {IsJoinApprovalRequired: true}`. WhatsApp sends the same tag in
  # both directions with the state in a child element, and whatsmeow -- which this provider
  # wraps, and whose `GroupChange` it forwards -- reads the tag's presence and never the
  # child, so the library has no way to say "off".
  #
  # Reading it anyway is worse than not reading it, because the two halves of the damage are
  # not alike. The stored value heals: the next `group.info` reads approval from a snapshot,
  # where presence of the element is the whole signal and is right in both directions. The
  # activity written into the group's thread does not heal, and an operator is left reading
  # "join approval enabled" at the moment somebody disabled it, with nothing to contradict it.
  def settings
    {
      subject: nested(event[:Name], 'Name'),
      description: nested(event[:Topic], 'Topic'),
      announce: nested(event[:Announce], 'IsAnnounce'),
      locked: nested(event[:Locked], 'IsLocked')
    }
  end

  def participants
    ACTIONS.index_with { |action| parties(event[action], event["#{action}Lid"]) }
           .transform_keys { |action| action.downcase.to_sym }
  end

  # Two parallel lists describing the same people. Paired by position, which is how the
  # provider sends them; either can be the only one there.
  def parties(phones, lids)
    phones = Array(phones)
    lids = Array(lids)
    return if phones.empty? && lids.empty?

    [phones.size, lids.size].max.times.filter_map { |index| party(lids[index], phones[index]) }
  end

  def party(lid, phone)
    lid = address_id(lid)
    phone = address_id(phone)
    model::Party.new(lid: lid, phone: phone) if lid.present? || phone.present?
  end

  def address_id(jid)
    model::Address.parse(jid)&.id
  end

  # A changed field arrives either as the value itself or wrapped in the struct that
  # carries it and its metadata.
  def nested(value, key)
    value.is_a?(Hash) ? value[key] : value
  end
end
