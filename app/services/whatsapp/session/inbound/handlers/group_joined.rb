# The session was added to a group (or created one). The event carries the whole group,
# so the contact, its settings and its members are written without asking the provider
# anything.
class Whatsapp::Session::Inbound::Handlers::GroupJoined < Whatsapp::Session::Inbound::Handlers::Base
  def perform
    return :ignored unless capability?(:groups)
    return :ignored if payload.info.blank?

    # The long lease: this syncs the whole roster from the snapshot the event carried.
    inbound::Locks.with_chat_lock(inbox, payload.info.group.id, ttl: inbound::Locks::GROUP_SYNC_LOCK_TTL) { sync }
  end

  private

  def sync
    resolver = inbound::GroupResolver.new(inbox: inbox, group: payload.info.group, subject: payload.info.subject)
    result = resolver.perform
    # Opened right away so the group shows up in the chat list with its history, the
    # same as a group whose first message just arrived. Reopened explicitly, because this
    # event creates no message: an inbox that locks to a single conversation hands back
    # the resolved thread of the group it was in before, and nothing else would move it
    # off resolved until somebody happens to write there.
    reopen(resolver.conversation_for(result.group_contact_inbox))

    Whatsapp::Session::Groups::Syncer.new(channel: channel, group_contact: result.group_contact, info: payload.info).perform
    broadcast_roster(result.group_contact)
    :handled
  end

  # Snoozed counts as closed here: this event creates no message, so nothing triggers the
  # reopen a message would, and the restored group would stay hidden until the old snooze
  # happened to expire.
  def reopen(conversation)
    conversation.open! if conversation.resolved? || conversation.snoozed?
    conversation
  end

  # The roster changed, and an ordinary contact update does not carry `group_members`,
  # so without this an open dashboard keeps showing the members (and the admin rights)
  # the group had before, until a reload or the next participant event.
  def broadcast_roster(group_contact)
    group_contact.reload
    Rails.configuration.dispatcher.dispatch(
      Events::Types::CONTACT_GROUP_SYNCED, Time.zone.now, contact: group_contact, channel: channel
    )
  end
end
