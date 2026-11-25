# Brings a group contact in line with what WhatsApp says about the group: its name,
# description, settings, invite code and member list.
#
# It runs from two places, which is why the metadata can be passed in: an event that
# already carries the group (group.joined) supplies it directly, while a scheduled or
# manual sync fetches it through the backend.
class Whatsapp::Session::Groups::Syncer
  # Group settings, as WhatsApp names them on the wire and as the dashboard reads them
  # from additional_attributes (the keys the Baileys layer already writes).
  # Same reason as everywhere else in this layer: an implicit namespace captured in a
  # constant is the module object from before the last reload.
  def model = Whatsapp::Session::Model

  SETTINGS = { announce: 'announce', locked: 'restrict',
               join_approval: 'join_approval_mode', member_add_mode: 'member_add_mode' }.freeze

  # Three of the four settings arrive as booleans and one as the wire enum, but the
  # dashboard reads all four out of additional_attributes as booleans, and reads
  # member_add_mode as "may every member add people". Storing `admin_add` raw would be
  # read as true, showing the exact opposite of the setting the group has.
  def self.setting_value(member, raw)
    return raw unless member == :member_add_mode

    raw.to_s == 'all_member_add'
  end

  attr_reader :channel, :group_contact, :soft

  # `soft` is the activity ping: something happened in this group, but not what. The
  # roster is read anyway, exactly as the Baileys path does, because `group_last_synced_at`
  # is advanced either way and `Contacts::SyncGroupJob` reads it as a 15 minute cooldown
  # for every sync that is not forced, the manual one from the dashboard included.
  # Skipping the members while stamping the group as synced would leave a stale roster
  # that nothing can refresh for the next quarter of an hour. Only the avatar is skipped.
  def initialize(channel:, group_contact:, info: nil, soft: false)
    @channel = channel
    @group_contact = group_contact
    @info = info
    @soft = soft
  end

  def perform
    # A snapshot handed in came with an event the caller already serialized, so this only
    # takes the lock when it fetches one: a scheduled or manual sync otherwise races the
    # group's own events and can apply metadata older than what just landed, reviving
    # members that left or overwriting `group_left`.
    return apply(@info) if @info.present?

    Whatsapp::Session::Inbound::Locks.with_chat_lock(
      inbox, group_address&.id, ttl: Whatsapp::Session::Inbound::Locks::GROUP_SYNC_LOCK_TTL
    ) { apply(fetch_info) }
  end

  private

  def inbox = channel.inbox

  def group_contact_inbox = group_contact.contact_inboxes.find_by(inbox_id: inbox.id)

  def apply(info)
    return if info.blank?

    # Only rejoining clears the left flag, and only an event that carries the group
    # (`group.joined`) knows that happened. A scheduled sync can still read cached
    # metadata for a group this inbox left, and clearing it there would put the group
    # actions back in the dashboard for a thread that can no longer send anything.
    group_contact_inbox&.mark_group_rejoined! if @info.present?
    update_contact(info)
    sync_members(info)
    update_avatar(info) unless soft
    group_contact
  end

  def group_address
    address = model::Address.parse(group_contact.identifier)
    address if address.present? && address.group?
  end

  def fetch_info
    address = group_address
    return if address.blank?

    channel.session_backend.group_info(model::Commands::GroupInfo.new(group: address))
  rescue Whatsapp::Session::Errors::ProviderUnavailable, Whatsapp::Session::Errors::RateLimited
    # Raised on. Swallowing it here returns nil, and the caller reads that as "nothing to
    # apply" and goes on to dispatch CONTACT_GROUP_SYNCED and hand back the untouched
    # contact: a sync that never happened, reported as one that did.
    raise
  rescue Whatsapp::Session::Errors::Error => e
    # What is left says the group cannot be read at all, which no retry changes.
    Rails.logger.error("[WHATSAPP SESSION] group info failed for #{group_contact.identifier}: #{e.message}")
    nil
  end

  # `group_contact` was handed in before `fetch_info`, so the copy this merges into predates
  # the call. The chat lock around the fetch serialises this group's own events and nothing
  # else: an avatar sync, a dashboard edit or another inbox writes the same column outside it.
  # The name travels with the merge because taking the row lock reloads the record.
  def update_contact(info)
    attributes = {}
    attributes[:name] = info.subject if info.subject.present? && group_contact.name != info.subject

    group_contact.merge_json_column!(:additional_attributes, attributes: attributes, merge: synced_attributes(info))
  end

  # A snapshot describes the group as it is now, so a description the group removed has
  # to overwrite the one stored: it arrives as an empty value, and dropping it would
  # leave the old text on screen forever. An *absent* field is a different thing and is
  # left alone, because `invite_code` is only readable by an admin and `owner` is not
  # always reported, so treating either absence as a removal would throw away what we
  # legitimately have.
  def synced_attributes(info)
    attributes = {
      'owner' => info.owner&.identifier || info.owner&.phone,
      'owner_pn' => info.owner&.phone,
      'invite_code' => info.invite_code.presence,
      'group_last_synced_at' => Time.current.to_i
    }.compact
    attributes['description'] = info.description.presence unless info.description.nil?
    # Written only where the provider reported the id at all. Absent is not "this
    # description can be changed", it is "this provider does not say" -- uazapi never
    # does -- and writing false for it would erase what a native sync of the same group
    # legitimately learned, leaving the panel offering an edit WhatsApp refuses forever.
    attributes['description_frozen'] = info.description_frozen? unless info.topic_id.nil?
    attributes.merge(setting_attributes(info))
  end

  def setting_attributes(info)
    SETTINGS.filter_map do |member, key|
      raw = info.public_send(member)
      [key, self.class.setting_value(member, raw)] unless raw.nil?
    end.to_h
  end

  def sync_members(info)
    return if info.participants.blank?

    member_ids = info.participants.filter_map { |participant| upsert_member(participant) }
    group_contact.group_memberships.active.where.not(contact_id: member_ids).find_each do |membership|
      membership.update!(is_active: false)
    end
  end

  # `skip_avatar` on a soft sync, exactly as the Baileys path passes `skip_avatars: soft`:
  # an activity hint on a large group would otherwise enqueue one provider profile
  # lookup per member without an avatar, which is the expensive half a hint does not
  # justify paying for.
  def upsert_member(participant)
    contact = Whatsapp::Session::Inbound::ContactResolver
              .new(inbox: inbox, party: participant.party, skip_avatar: soft)&.perform&.contact
    return if contact.blank?

    member = GroupMember.find_or_initialize_by(group_contact: group_contact, contact: contact)
    member.assign_attributes(role: participant.admin? ? :admin : :member, is_active: true)
    member.save! if member.changed?
    contact.id
  end

  # An event that carried the group is a snapshot of it right now, so its picture wins
  # over the stored one: nothing replays the picture-change events from while the session
  # was out of the group, and the guard below would otherwise keep the old image for as
  # long as the avatar stays attached, which is forever.
  # A snapshot reporting no picture used to read exactly like one that does not mention
  # the picture, and this could only stand still: a photo removed while the session was
  # out of the group kept the stored one. `has_picture` is what says the difference, and
  # a producer that cannot answer leaves it out, which is the case this keeps unchanged.
  def update_avatar(info)
    return Whatsapp::Session::AvatarSync.remove(group_contact) if info.has_picture == false
    return if info.picture_url.blank?
    return Whatsapp::Session::AvatarSync.refetch(group_contact, info.picture_url) if @info.present?
    return if group_contact.avatar.attached?

    ::Avatar::AvatarFromUrlJob.perform_later(group_contact, info.picture_url, resolved_at: Time.current.iso8601)
  end
end
