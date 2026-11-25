# The two guards the inbound path needs, in one place.
#
# The `native` backend already delivers a session's events in order on a single
# consumer thread, so nothing there can race. Uazapi arrives as HTTP webhooks fanned
# out over Sidekiq, where two messages of the same chat can land at once, so both
# guards have to hold for the family as a whole.
module Whatsapp::Session::Inbound::Locks
  # Raised when another worker holds the chat: the caller retries the job instead of
  # spinning, so a Sidekiq thread is never parked waiting on Redis.
  class Busy < StandardError; end

  CHAT_LOCK_TTL = 30.seconds
  # What a history import leases the chat for. A batch is a few hundred messages with a
  # contact resolution behind the first of them, and a lease that expires mid-import is not
  # a lock: a live message for the same chat would take the key and open a second
  # conversation beside the one being filled.
  #
  # It lives here rather than in either importer because it is not only the importer's
  # business. It is the longest anything holds a chat key, so it is also the floor for the
  # retry budget of whoever might be waiting on one -- and a copy per importer is how those
  # two drift until a live message gives up on a lock that was going to be released.
  IMPORT_CHAT_LOCK_TTL = 5.minutes
  # How long a note that somebody wanted a chat and could not have it outlives the attempt
  # that left it, and the only thing that ends it. Nobody clears it: the note is shared by
  # every caller waiting on that chat, so the first one to be served would be deleting a
  # claim the others still hold, and an import could cut back in ahead of them.
  #
  # Expiry therefore has to outlast the gap between two attempts by the same caller, or the
  # note is gone while its author is still queued -- which is why the live retry waits below
  # are stated in terms of it rather than chosen. The cost of the other end is one window of
  # imports held off a chat after the last live message was served, which an import can
  # afford and a message cannot.
  WAITER_TTL = 1.minute
  # Reading a group's whole roster is the one guarded operation that can run for minutes:
  # each participant is resolved, and a large group has hundreds. A lease that expires
  # mid-way is not a lock at all, because a second worker takes the key and the two
  # interleave their membership writes, and releasing by token only stops the first from
  # deleting the second's lease.
  GROUP_SYNC_LOCK_TTL = 2.minutes
  # Long enough to cover one processing pass, short enough that a marker orphaned by a
  # killed worker heals on its own within the job's retry budget.
  MESSAGE_LOCK_TTL = 30.seconds
  # How often a caller that was given a `wait` looks again. Waiting at all is the exception
  # here -- everything else answers Busy and lets the job retry, so a Sidekiq thread is
  # never parked on Redis -- and it is granted only for the seconds an album takes to
  # finish arriving, where a retry a quarter of a minute later is worse than a short park.
  SPIN_INTERVAL = 0.1

  module_function

  # Marks a provider message id as being processed, so a redelivery arriving while the
  # first pass is still running retries instead of racing it into a second row.
  #
  # Holding the marker answers `Busy`, never :duplicate. What makes a *finished* message
  # a duplicate is its stored source_id, and the caller checks that inside; a worker
  # killed between taking the marker and writing the row would otherwise have its own
  # retry answered ":duplicate", which acknowledges the event and loses the message.
  def with_message_lock(inbox, message_id)
    return yield if message_id.blank?

    key = message_key(inbox, message_id)
    token = SecureRandom.uuid
    unless Redis::Alfred.set(key, token, nx: true, ex: MESSAGE_LOCK_TTL)
      raise Busy, "message #{message_id} of inbox #{inbox.id} is already being processed"
    end

    begin
      yield
    ensure
      # By token, for the same reason the chat lock is: a pass that outran the TTL would
      # otherwise delete the marker a redelivery had already taken, and a third delivery
      # could then run alongside it and write a second row.
      Redis::Alfred.delete_if_equals(key, token)
    end
  end

  # Serializes everything that resolves a contact or picks a conversation for one chat,
  # so two messages of the same chat cannot each create their own conversation.
  #
  # Takes every id the chat can be addressed by, because WhatsApp names the same 1:1 peer
  # by phone in one event and by LID in the next: locking only the one an event happens
  # to carry lets two workers each find no conversation and open one. The ids are locked
  # in a fixed order, so two workers holding different aliases cannot deadlock, and each
  # is released by token: `Redis::LockManager#unlock` deletes unconditionally, so an
  # operation that outran the TTL (syncing a large group roster is the realistic one)
  # would delete a lock a second worker had already taken.
  #
  # `ttl` and `wait` are the two numbers a lock has, and conflating them is the failure this
  # signature exists to prevent: `ttl` is how long the work behind the key may run, `wait`
  # is how long it is worth standing here to get the key. A `ttl` sized by somebody's
  # patience expires mid-block, and from there the guarded work runs unguarded. `wait` is
  # nil by default, so the answer is Busy and the job retries.
  #
  # `defer_to_waiters` marks the caller as the one that gives way, which an import is and
  # nothing else is. Two things follow from it, and they are the same rule read from both
  # ends: it stands aside while somebody is waiting, and it does not register itself as a
  # waiter when it cannot have the key.
  #
  # Without that the batches of one dump hand the chat to each other for as long as the dump
  # is long, and a live message beside them can lose every attempt it has against a lock
  # that is never free at the moment it looks -- a retry budget covers one holder, and what
  # it is really up against is a queue of them. And an import that noted itself would be
  # standing aside for its own siblings, which is a deadlock spelled differently.
  def with_chat_lock(inbox, *chats, ttl: CHAT_LOCK_TTL, wait: nil, defer_to_waiters: false)
    keys = chats.flatten.compact_blank.uniq.sort.map { |chat| chat_key(inbox, chat) }
    return yield if keys.empty?
    raise Busy, "#{keys.first} of inbox #{inbox.id} has a caller waiting on it" if defer_to_waiters && waiting?(inbox, chats)

    held = {}
    note = defer_to_waiters ? nil : waiter_keys(inbox, chats)
    begin
      take(keys, held, ttl: ttl, deadline: deadline_for(wait), note: note)
      yield
    ensure
      held.each { |key, token| Redis::Alfred.delete_if_equals(key, token) }
    end
  end

  # Whether anybody has said they want one of these chats and could not have it. Read by
  # the callers that give way, and by nothing else.
  def waiting?(inbox, *chats)
    waiter_keys(inbox, chats).any? { |key| Redis::Alfred.get(key).present? }
  end

  def note_waiter(inbox, *chats)
    mark_waiting(waiter_keys(inbox, chats))
  end

  # Kept to the claiming, not wrapped around the block: a Busy raised by something the
  # block itself locks says nothing about this chat, and noting it would hold imports off
  # a chat nobody is actually waiting for.
  #
  # `note` carries the chats to record against, or nil for the caller that gives way.
  # nil means take it or answer Busy, which is what every caller but the live inbound path
  # wants: a Sidekiq thread that parks on Redis is a thread not processing anything else.
  def deadline_for(wait) = wait && (Time.now.to_f + wait)

  def take(keys, held, ttl:, deadline:, note:)
    keys.each { |key| held[key] = claim(key, ttl, deadline) }
  rescue Busy
    mark_waiting(note) if note
    raise
  end

  # `ttl` is how long the work behind the lock may take; `deadline` is how long it is worth
  # standing here to get it. They are unrelated numbers, and the one bug this module exists
  # to not have is a lock that expires while the block it guards is still running.
  def claim(key, ttl, deadline)
    token = SecureRandom.uuid
    loop do
      return token if Redis::Alfred.set(key, token, nx: true, ex: ttl)
      break if deadline.nil? || Time.now.to_f >= deadline

      sleep(SPIN_INTERVAL)
    end

    raise Busy, "#{key} is locked"
  end

  def mark_waiting(keys)
    keys.each { |key| Redis::Alfred.set(key, 1, ex: WAITER_TTL) }
  end

  def processing?(inbox, message_id)
    Redis::Alfred.get(message_key(inbox, message_id)).present?
  end

  def message_key(inbox, message_id)
    format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: "#{inbox.id}_#{message_id}")
  end

  def chat_key(inbox, chat)
    "WHATSAPP::CONTACT_LOCK::#{inbox.id}_#{chat}"
  end

  def waiter_keys(inbox, chats)
    chats.flatten.compact_blank.uniq.map { |chat| "#{chat_key(inbox, chat)}::WAITING" }
  end
end
