# The two markers `Avatar::AvatarFromUrlJob` keeps on a Contact to avoid refetching the
# same picture: the last sync time (a one minute rate limit) and a hash of the URL it
# already fetched. That job stamps both even on the run it skipped, so anything that
# knows the stored avatar is out of date has to clear them first or its refresh is
# dropped, and so is every later attempt at the same URL.
#
# Three callers know that: the contact picture-changed event, the forced group photo
# refresh, and the group rejoin snapshot.
module Whatsapp::Session::AvatarSync
  MARKERS = %w[last_avatar_sync_at avatar_url_hash].freeze
  REMOVED_AT = 'avatar_removed_at'.freeze

  module_function

  # `additional_attributes` is one JSON column that also carries the group's description, its
  # settings and `group_left`, and the caller is often a job that fetched group info first.
  # `update_avatar_sync_markers!` is what re-reads under the row lock rather than persisting the
  # hash the caller read before that round trip; the reason it exists lives on it.
  def reset(contact)
    return if contact.blank?

    contact.update_avatar_sync_markers!(remove: MARKERS)
  end

  # Clears the markers and asks for the picture at `url`, which the caller already has.
  def refetch(contact, url)
    return if contact.blank? || url.blank?

    reset(contact)
    ::Avatar::AvatarFromUrlJob.perform_later(contact, url, resolved_at: Time.current.iso8601)
  end

  # Drops the picture and records when, so a download already queued for the picture
  # that was just removed does not put it back.
  #
  # `Avatar::AvatarFromUrlJob` is handed a URL with no notion of how fresh it is, and a
  # removal that lands between the URL being resolved and the job running cannot be seen
  # from inside it: an avatarable with nothing attached is both "just purged" and "never
  # had one", which is the case the job exists to fill. The timestamp is what separates
  # them, and the job compares it against the moment its URL was resolved.
  def remove(contact)
    return if contact.blank?

    contact.avatar.purge if contact.avatar.attached?
    contact.update_avatar_sync_markers!(remove: MARKERS, merge: { REMOVED_AT => Time.current.iso8601 })
  end
end
