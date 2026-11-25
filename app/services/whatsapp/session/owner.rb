# Whether a contact is the WhatsApp account this inbox is connected as.
#
# There are two ways to be it and both have to be tried. The phone number the operator
# configured, compared through the normalizers because WhatsApp reports a Brazilian line
# with or without its ninth digit depending on when it was registered. And the LID, which
# for an account WhatsApp has not disclosed the number of is the only identity a group
# roster carries: comparing phone numbers there compares nil to something and answers no
# to "is this us?", which is how an inbox that administers an announcement-only group
# ends up refusing to post in it.
module Whatsapp::Session::Owner
  module_function

  def owns?(channel, contact)
    return false if contact.blank?
    return true if Whatsapp::Session::PhoneMatch.same_number?(contact.phone_number, channel.phone_number)

    contact.identifier.present? && contact.identifier == lid_identifier(channel)
  end

  # The roster row that IS the connected account, by the same rule, as a lookup rather
  # than `owns?` over a loaded roster: the callers hold thousands of rows and want one.
  #
  # Every publisher of that answer has to use this. The REST roster and the group-sync
  # broadcast each grew their own phone-only query, so an account known by LID alone was
  # recognised by whichever one ran last -- the fetch said "you administer this group" and
  # the first sync event took it back.
  def group_member(channel, group_contact)
    return if channel.blank? || group_contact.blank?

    phones = Whatsapp::Session::PhoneMatch.variants(channel.try(:phone_number))
    identifier = lid_identifier(channel)
    return if phones.blank? && identifier.blank?

    GroupMember.active
               .where(group_contact: group_contact)
               .joins(:contact)
               .where(MEMBER_MATCH_SQL, phones: phones, identifier: identifier)
               .includes(:contact)
               .first
  end

  def admin?(channel, group_contact)
    group_member(channel, group_contact)&.role == 'admin'
  end

  # An empty `phones` renders as `IN (NULL)`, which is never true, and a nil identifier
  # needs no guard of its own: `contacts.identifier = NULL` is never true either. Writing
  # that guard out is what Postgres refuses -- a bare parameter beside `IS NOT NULL` has
  # no type to infer.
  MEMBER_MATCH_SQL = <<~SQL.squish.freeze
    REPLACE(contacts.phone_number, '+', '') IN (:phones)
    OR contacts.identifier = :identifier
  SQL

  def lid_identifier(channel)
    lid = channel.try(:provider_connection).to_h['lid'].presence
    lid && "#{lid}@lid"
  end
end
