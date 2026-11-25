# Remembers how far an inbox's mailbox has already been swept, so the next fetch can
# ask the server for "everything after UID N" instead of re-listing the whole window.
#
# This is deliberately a cache and not a column. Losing it costs one expensive sweep,
# never a message: the date-based sweep it optimises away still runs on a schedule, and
# `email_already_present?` remains the final net. That asymmetry is what makes the
# optimisation safe to fail.
class Imap::UidCursor
  # A week is long enough that a quiet inbox keeps its cursor across a Redis restart,
  # and short enough that a channel deleted from Chatwoot does not leak a key forever.
  TTL = 7.days.to_i

  pattr_initialize [:inbox!]

  def read
    raw = Redis::Alfred.get(key)
    return if raw.blank?

    parsed = JSON.parse(raw).symbolize_keys
    return unless parsed[:uid_validity].present? && parsed[:last_uid].present?
    # A cursor written before the mailbox fingerprint existed cannot prove which mailbox
    # it came from, and unprovable is the same as absent here.
    return if parsed[:mailbox].blank?

    parsed
  rescue JSON::ParserError
    # A malformed cursor is indistinguishable from no cursor, and both mean the same
    # thing: fall back to the date sweep.
    nil
  end

  def write(uid_validity:, last_uid:, swept_at:, mailbox:)
    Redis::Alfred.set(
      key,
      { uid_validity: uid_validity, last_uid: last_uid, swept_at: swept_at.to_i, mailbox: mailbox }.to_json,
      ex: TTL
    )
  end

  def clear
    Redis::Alfred.delete(key)
  end

  private

  def key
    format(Redis::RedisKeys::IMAP_UID_CURSOR, inbox_id: inbox.id)
  end
end
