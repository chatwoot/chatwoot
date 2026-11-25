# One group snapshot, as this provider describes it, turned into the canonical GroupInfo.
#
# The shape is whatsmeow's `types.GroupInfo` serialized as-is, which the provider hands
# back from `/group/create`, `/group/list` and `/group/info`, and pushes on the `groups`
# webhook when a group is created. One reader for all four.
#
# The topic is passed through as it arrives, empty string included: this provider always
# reports the field, so an empty one means the group has no description, and the syncer
# is what turns that into a removal. Only an absent field is left alone.
class Whatsapp::Session::Backends::Uazapi::GroupMapper
  attr_reader :group

  def initialize(group)
    @group = (group || {}).to_h
  end

  def perform
    address = model::Address.parse(group['JID'])
    return if address.nil?

    model::GroupInfo.new(
      group: address, subject: group['Name'], description: group['Topic'], owner: owner,
      participants: participants, size: participants.size,
      announce: group['IsAnnounce'], locked: group['IsLocked'],
      join_approval: group['IsJoinApprovalRequired'], member_add_mode: group['MemberAddMode'].presence
    )
  end

  private

  def model = Whatsapp::Session::Model

  # Both halves of the owner's identity travel in their own fields, and the syncer stores
  # the LID as the identifier and the number beside it.
  def owner
    party(lid: group['OwnerJID'], phone: group['OwnerPN'])
  end

  def participants
    @participants ||= Array(group['Participants']).filter_map do |entry|
      entry = entry.to_h
      member = party(lid: entry['LID'].presence || entry['JID'], phone: entry['PhoneNumber'], name: entry['DisplayName'])
      next if member.nil?

      model::GroupInfo::Participant.new(party: member, role: role_of(entry))
    end
  end

  # Both fields arrive as JIDs, and either can name the other kind: a group addressed by
  # phone number reports `LID` empty and `JID` as the phone JID. Parsing decides which is
  # which instead of trusting the field name.
  def party(lid: nil, phone: nil, name: nil)
    addresses = [lid, phone].filter_map { |jid| model::Address.parse(jid) }
    return if addresses.empty?

    model::Party.new(
      lid: addresses.find(&:lid?)&.id, phone: addresses.find(&:phone?)&.id, push_name: name.presence
    )
  end

  def role_of(entry)
    return 'superadmin' if entry['IsSuperAdmin']
    return 'admin' if entry['IsAdmin']

    'member'
  end
end
