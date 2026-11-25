# Reactions are stored as ordinary message rows flagged `is_reaction`, one row per
# (target, sender), toggled instead of duplicated. This holds both halves of that:
# writing a new reaction and marking an existing one removed.
class Whatsapp::Session::Inbound::ReactionStore
  # `content_attributes` is a `store`, so it reaches Postgres as json rather than jsonb
  # and every predicate below has to cast before it can index into it.
  JSON_COLUMN = "(content_attributes#>>'{}')::jsonb".freeze

  attr_reader :inbox, :reaction, :sender

  # `sender` is the Contact that reacted, nil for a reaction sent from the phone.
  def initialize(inbox:, reaction:, sender: nil)
    @inbox = inbox
    @reaction = reaction
    @sender = sender
  end

  # True when *this sender* still has a reaction on this target. Asked before the sender
  # is resolved, which is what keeps a removal aimed at nothing from creating a contact
  # on its way to doing nothing: scoped to the target alone, somebody else's reaction
  # would answer yes and the contact would be created anyway.
  #
  # `sender` is the Contact, or nil for a reaction from the connected number, which has
  # one author on the WhatsApp side whether an agent or the phone wrote it. The caller
  # finds the Contact without creating one.
  def self.active?(inbox:, target_id:, sender:, from_me: false)
    live(rows(inbox: inbox, target_id: target_id, sender: sender, from_me: from_me)).exists?
  end

  # The same pair, deleted rows included. What tells a removal that arrived before its
  # reaction apart from one with nothing to do: the first has no row at all, the second
  # has one that is already gone.
  def self.recorded?(inbox:, target_id:, sender:, from_me: false)
    rows(inbox: inbox, target_id: target_id, sender: sender, from_me: from_me).exists?
  end

  # Every reaction row this (target, sender) pair has, in any state. The one scope the
  # three questions below are asked of, so "which rows are this pair's" is answered in a
  # single place: `sender` decides it for a contact's reaction, and `message_type` for
  # one from the connected number, which has a single author on the WhatsApp side
  # whether an agent or the phone wrote it.
  def self.rows(inbox:, target_id:, sender:, from_me:)
    scope = Message.where(inbox_id: inbox.id)
                   .where("#{JSON_COLUMN}->>'is_reaction' = 'true'")
                   .where("#{JSON_COLUMN}->>'in_reply_to_external_id' = ?", target_id)
    from_me ? scope.where(message_type: Message.message_types[:outgoing]) : scope.where(sender: sender)
  end

  # The subset that still shows an emoji on the bubble.
  def self.live(scope)
    scope.where.not(content: '').where("COALESCE(#{JSON_COLUMN}->>'deleted', 'false') != 'true'")
  end

  # nil when there was nothing to do: this reaction is older than the one already stored,
  # so applying it would put the emoji the sender swapped away from back on the bubble.
  def write(conversation)
    existing = find_existing
    return replace(existing) if existing
    return nil if removed_later?

    conversation.messages.create!(account_id: inbox.account_id, inbox_id: inbox.id, source_id: reaction.id,
                                  sender: reaction.from_me ? nil : sender,
                                  message_type: reaction.from_me ? :outgoing : :incoming,
                                  content: reaction.emoji, content_attributes: new_content_attributes)
  end

  def new_content_attributes
    {
      is_reaction: true,
      in_reply_to_external_id: reaction.target_id,
      external_created_at: created_at,
      external_sender_name: ('WhatsApp' if reaction.from_me)
    }.compact
  end

  # WhatsApp delivers a removal as a reaction with an empty emoji. The stored row is
  # emptied and flagged deleted rather than removed, so the bubble it annotates keeps
  # its history.
  #
  # A `from_me` removal reaches this from two paths and both must work: the echo of a
  # removal Chatwoot itself made (the row is already deleted, so this no-ops) and a
  # removal made on the connected phone (the row is still active, stored sender-less).
  def remove
    existing = find_existing
    return note_removal if existing.nil?

    # Merged under the row lock: the hash is read to be written back, so reading it off
    # an instance loaded earlier drops whatever another worker put there in between.
    #
    # Refused when the removal is older than the reaction stored, the same way a stale
    # swap is: a removal can be replayed late, off the ordered stream, when the message it
    # is about was waiting for its history import, and by then the sender may have reacted
    # again.
    removed = existing.with_lock do
      next false if stale?(existing)

      # Stamped with the removal's own time, which is what a reaction replayed after it
      # is compared against: see `removed_later?`.
      existing.update!(content: '', content_attributes: existing.content_attributes.merge(
        { 'deleted' => true, 'external_created_at' => created_at }.compact
      ))
      true
    end
    return nil unless removed

    Whatsapp::Session::Inbound::ChatList.refresh(existing.conversation)
    existing
  end

  # A removal with nothing active left to remove still says when the phone last took the
  # reaction back, and a reaction replayed after it has to be measured against that: kept on
  # the newest deleted row. Answers nil, which is what a removal with nothing to do is.
  def note_removal
    tombstone = latest_tombstone
    return if created_at.blank? || tombstone.nil? || tombstone.external_created_at.to_i >= created_at

    tombstone.with_lock { tombstone.update!(content_attributes: tombstone.content_attributes.merge('external_created_at' => created_at)) }
    nil
  end

  private

  def latest_tombstone
    rows = self.class.rows(inbox: inbox, target_id: reaction.target_id, sender: sender, from_me: reaction.from_me)
    rows.select { |row| row.content_attributes['deleted'] }.max_by { |row| row.external_created_at.to_i }
  end

  # WhatsApp gives a changed reaction a new id, so the same sender swapping one emoji
  # for another arrives as a fresh event rather than as an edit. One row per (target,
  # sender) is the invariant the removal path depends on: a second row would show both
  # emojis on the bubble and leave one of them behind when the reaction is taken back.
  #
  # Refused when this reaction is older than the stored one, on the provider's clock
  # rather than on arrival: arrival is the thing that is out of order. Ties pass, since
  # equal timestamps carry no order to respect, which is also what the second half of a
  # swap looks like when the provider stamps both in the same second.
  def replace(existing)
    replaced = existing.with_lock do
      next false if stale?(existing)

      existing.update!(
        source_id: reaction.id,
        content: reaction.emoji,
        content_attributes: existing.content_attributes.merge(
          { 'external_created_at' => created_at }.compact
        )
      )
      true
    end
    return nil unless replaced

    Whatsapp::Session::Inbound::ChatList.refresh(existing.conversation)
    existing
  end

  # A reaction older than a removal already applied for the same sender and target. Events
  # replayed off the ordered stream, while the message they annotate waited for its history
  # import, can run in any order, and the removal is what the phone ended on.
  def removed_later?
    return false if created_at.blank?

    rows = self.class.rows(inbox: inbox, target_id: reaction.target_id, sender: sender, from_me: reaction.from_me)
    rows.any? { |row| row.content_attributes['deleted'] && row.external_created_at.to_i > created_at }
  end

  def stale?(existing)
    stored = existing.external_created_at
    created_at.present? && stored.present? && created_at < stored.to_i
  end

  def created_at
    reaction.timestamp && (reaction.timestamp / 1000)
  end

  # Deliberately not scoped to any conversation: the original reaction may live in an
  # older or resolved thread while the inbound flow picked a different one.
  #
  # Active-only: when every match is already deleted this returns nil, so an echoed
  # removal does not re-delete the row and bump the conversation again.
  def find_existing
    matches = self.class.rows(inbox: inbox, target_id: reaction.target_id, sender: sender, from_me: reaction.from_me)

    preferred(self.class.live(matches).reorder(created_at: :desc).to_a)
  end

  # Which of them the echo belongs to, for a provider that gives it neither our reserved
  # id nor a token of our own. Two agents can each hold an outgoing reaction on one
  # target, since a row is filed per user here where WhatsApp keeps one reaction per
  # number, so the newest is a guess: writing this echo's id onto the wrong one leaves the
  # row that actually sent it without an id at all, and its retry sends a second time.
  #
  # The send that produced the echo is the one still waiting for an id, and among those
  # the one that asked for this emoji. A removal carries no emoji to match on and is
  # aimed at whatever is active, so it keeps the plain newest-first answer.
  def preferred(candidates)
    return candidates.first unless reaction.from_me && reaction.emoji.present?

    pending = candidates.select { |message| message.source_id.blank? }
    pending.find { |message| message.content == reaction.emoji } || pending.first || candidates.first
  end
end
