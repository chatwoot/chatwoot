# Resolves the three records a group message needs: the contact that stands for the
# group, the contact of whoever wrote the message, and the membership between them.
#
# The heavy lifting is GroupConversationHandler, the concern every channel shares. It
# is written against abstract extractors, which is what this class supplies from the
# canonical event.
class Whatsapp::Session::Inbound::GroupResolver
  include GroupConversationHandler

  # What a group message handler needs to write the message.
  Result = Data.define(:group_contact_inbox, :group_contact, :sender_contact)

  # Long enough for the caller to have written its message and opened the thread. Matches
  # what the Baileys layer waits before the same job.
  SYNC_DELAY = 5.seconds

  attr_reader :inbox, :group, :sender, :subject

  def initialize(inbox:, group:, sender: nil, subject: nil)
    @inbox = inbox
    @group = group
    @sender = sender
    @subject = subject
  end

  def perform
    group_contact_inbox, group_contact = find_or_create_group_contact
    sender_contact = resolve_sender
    track_membership(group_contact, sender_contact) if sender_contact
    sync_unless_known(group_contact)

    Result.new(group_contact_inbox: group_contact_inbox, group_contact: group_contact, sender_contact: sender_contact)
  end

  # The thread of the group, honouring the same reopen rules as a 1:1 conversation.
  #
  # Not `find_or_create_group_conversation`: that one only reuses open and pending rows,
  # so a group whose thread was snoozed, or resolved under `lock_to_single_conversation`,
  # would get a second conversation and split the group in two. It lives in the concern
  # the frozen Baileys layer also uses, so the policy is applied here instead of changed
  # there.
  def conversation_for(group_contact_inbox, archived: false, occurred_at: nil)
    Whatsapp::Session::Inbound::ConversationFinder.new(
      inbox: inbox, contact: group_contact_inbox.contact, contact_inbox: group_contact_inbox,
      archived: archived, occurred_at: occurred_at
    ).perform
  end

  # Membership writes live in GroupConversationHandler, which keeps them private
  # because most channels only reach them from their own handler. Group events change
  # membership without a message, so they are exposed here.
  def add_member(group_contact, contact, role: :member)
    add_group_member(group_contact, contact, role: role)
  end

  def remove_member(group_contact, contact)
    remove_group_member(group_contact, contact)
  end

  def update_member_role(group_contact, contact, role)
    update_group_member_role(group_contact, contact, role)
  end

  private

  # A message proves that whoever wrote it is in the group; it says nothing about what
  # they are in it. `add_group_member` writes the role it is handed, so calling it here
  # with the default would demote back to member, on every message they send, anyone a
  # roster sync or a `promote` event recorded as an administrator, including our own
  # number on the echo of our own sends. `inbox_admin?` reads exactly that row to decide
  # whether this inbox may post in an announce-only group.
  def track_membership(group_contact, contact)
    member = GroupMember.find_by(group_contact: group_contact, contact: contact)
    return add_group_member(group_contact, contact) if member.nil?

    member.update!(is_active: true) unless member.is_active?
    member
  end

  # A group nobody ever synced is named after its JID, because that is the fallback
  # `find_or_create_group_contact` uses when no subject was supplied, and a message
  # carries none: the wire names the chat, not the group. Left alone the thread stays
  # called `120363...` forever, since the events that do carry a subject only fire when
  # something happens to the group, and being added to it already happened.
  #
  # A group is first seen through a message far more often than through `group.joined`:
  # an inbox converted from another provider, a session resumed after a deploy, any
  # downtime at all. The Baileys layer schedules the same sync from its own stub handler,
  # for the same reason.
  #
  # Once, not per message: the job's own 15 minute cooldown covers a burst, and this
  # guard covers the rest, so a busy group does not queue a roster read per message.
  #
  # Delayed, and not as a precaution: `Contacts::SyncGroupService` needs a conversation to
  # drive the roster read through and creates one when it finds none. This runs before the
  # caller has written the message, so an immediate job finds a group contact with no
  # thread yet and opens a second one, which then stays empty in the chat list next to the
  # real thread. The wait is the same one the Baileys layer uses on the same job, and it
  # also lets a `group.joined` arriving alongside the first message fill the name first,
  # which the job's cooldown then reads as work already done.
  def sync_unless_known(group_contact)
    return if group_contact.additional_attributes&.dig('group_last_synced_at').present?
    return unless inbox.channel.respond_to?(:session_capabilities)
    return unless inbox.channel.session_capabilities.include?('group_management')

    Contacts::SyncGroupJob.set(wait: SYNC_DELAY).perform_later(group_contact, channel: inbox.channel)
  end

  def resolve_sender
    return if sender.blank?

    Whatsapp::Session::Inbound::ContactResolver.new(inbox: inbox, party: sender)&.perform&.contact
  end

  # Matches what the Baileys layer persists, so a converted inbox keeps addressing the
  # same group contact instead of creating a second one.
  def extract_group_identifier = group.to_jid
  def extract_group_source_id = group.id
  def extract_group_name = subject
  def extract_sender_identifier = sender&.identifier
  def extract_sender_source_id = sender&.source_id
  def extract_sender_name = sender&.name || sender&.phone || sender&.lid
  def extract_sender_phone = sender&.phone_e164
end
