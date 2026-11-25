# == Schema Information
#
# Table name: contact_inboxes
#
#  id                          :bigint           not null, primary key
#  group_left_at               :datetime
#  hmac_verified               :boolean          default(FALSE)
#  pubsub_token                :string
#  whatsapp_missing_checked_at :datetime
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  contact_id                  :bigint
#  inbox_id                    :bigint
#  source_id                   :text             not null
#
# Indexes
#
#  index_contact_inboxes_on_contact_id              (contact_id)
#  index_contact_inboxes_on_inbox_id                (inbox_id)
#  index_contact_inboxes_on_inbox_id_and_source_id  (inbox_id,source_id) UNIQUE
#  index_contact_inboxes_on_pubsub_token            (pubsub_token) UNIQUE
#  index_contact_inboxes_on_source_id               (source_id)
#

class ContactInbox < ApplicationRecord
  include Pubsubable
  include RegexHelper
  validates :inbox_id, presence: true
  validates :contact_id, presence: true
  validates :source_id, presence: true
  validate :valid_source_id_format?

  belongs_to :contact
  belongs_to :inbox

  has_many :conversations, dependent: :destroy_async

  # A merge moves this row under a contact with its own phone, and a session inbox sends to
  # the contact's phone: the "no WhatsApp" answer was about the old one.
  before_update -> { self.whatsapp_missing_checked_at = nil }, if: :will_save_change_to_contact_id?
  # Every write of the flag goes through update!, so this is the one place the dashboard hears
  # about it, whoever wrote it: a lookup, a phone correction, a merge.
  after_update_commit :broadcast_whatsapp_missing_change, if: :saved_change_to_whatsapp_missing_checked_at?

  # contact_inboxes that are not associated with any conversation
  scope :stale_without_conversations, lambda { |time_period|
    left_joins(:conversations)
      .where('contact_inboxes.created_at < ?', time_period)
      .where(conversations: { contact_id: nil })
  }

  def webhook_data
    {
      id: id,
      contact: contact.try(:webhook_data),
      inbox: inbox.webhook_data,
      account: inbox.account.webhook_data,
      current_conversation: current_conversation.try(:webhook_data),
      source_id: source_id
    }
  end

  def anonymous_caller?
    false
  end

  def current_conversation
    conversations.last
  end

  # How long a "no WhatsApp" answer is trusted before opening the conversation asks again. A
  # number can register at any time, and the warning itself discourages the one action, a
  # send, whose delivery receipt would otherwise clear it.
  WHATSAPP_MISSING_RECHECK_AFTER = 6.hours

  # Set when the inbox's session answered that this number has no WhatsApp account, which is
  # the one state where an outgoing message gets the server's single check and then reaches
  # nobody, not even the paired phone. Cleared by a later lookup that finds the number, by
  # anything the contact sends, and by a delivery receipt.
  #
  # Marks only if nothing moved while the provider was answering: the contact still has the
  # phone that was looked up, and the flag still holds what it held before asking. A phone
  # correction, a reply or a live receipt in between outranks an answer about the past.
  #
  # The flag comparison alone cannot see evidence that arrived while nothing was flagged (the
  # clear had no row to touch), so the threads are read too.
  #
  # Evidence can still land between that read and the commit, when Message's clear finds no
  # flag to touch and takes no lock. Each side therefore writes before it reads the other:
  # Message records its evidence before clearing, and this reads the evidence again after the
  # flag is committed, so at least one of them sees the other.
  def mark_whatsapp_missing_for!(phone, flag_before:, asked_at:)
    marked_at = with_whatsapp_answer_guard(phone, flag_before) do
      next if whatsapp_presence_since?(asked_at)

      # The moment of the question, not of the answer: evidence for anything sent from then on
      # outranks this "no", including a receipt that only arrives after it was written.
      update!(whatsapp_missing_checked_at: asked_at)
      whatsapp_missing_checked_at
    end
    return if marked_at.nil?

    # After the real commit, also when a caller wraps this in its own transaction: until then
    # Message's clear cannot see the flag either.
    ActiveRecord.after_all_transactions_commit do
      clear_whatsapp_missing_for!(phone, flag_before: marked_at) if whatsapp_presence_since?(asked_at)
    end
  end

  # A "yes" goes through the same guard: an answer about a phone the contact no longer has
  # must not clear the "no" a newer lookup left for the current one.
  def clear_whatsapp_missing_for!(phone, flag_before:)
    with_whatsapp_answer_guard(phone, flag_before) { clear_whatsapp_missing! }
  end

  # The contact's row lock is what a phone correction waits on; with_lock reloads both rows.
  def with_whatsapp_answer_guard(phone, flag_before)
    contact.with_lock do
      lock!
      next unless contact.phone_number == phone && whatsapp_missing_checked_at == flag_before

      yield
    end
  end

  # How long a live receipt stays where a pending lookup can see it: well past the 90 s a
  # Baileys lookup may take, counted from the receipt.
  WHATSAPP_RECEIPT_MEMORY = 10.minutes

  # Called by Message for a receipt that proves presence, after it filtered out echoes born
  # delivered and receipts replayed by an import. The rows cannot tell those apart afterwards
  # (both are delivered with a fresh updated_at), so the receipt is kept here instead, by when
  # the answered message was sent. Receipts arrive out of order, so only a newer send moves it.
  def self.remember_whatsapp_receipt(inbox_id, contact_id, sent_at)
    key = whatsapp_receipt_key(inbox_id, contact_id)
    Redis::Alfred.with do |conn|
      # WATCH/MULTI aborts the write if another receipt moved the key in between; then read again.
      3.times do
        stored = conn.watch(key) do
          seen = conn.get(key)
          if seen.present? && seen.to_f >= sent_at.to_f
            conn.unwatch
            next :kept
          end

          conn.multi { |transaction| transaction.set(key, sent_at.to_f, ex: WHATSAPP_RECEIPT_MEMORY.to_i) }
        end
        break if stored
      end
    end
  end

  # Whether the contact wrote, or a live receipt came back for a message sent, since the given
  # moment. The same evidence Message counts when it clears the flag: an incoming message by
  # the time WhatsApp says it was sent, so an import of older history written now does not
  # count. WhatsApp stamps whole seconds, so the rows are read from the start of the second
  # asked in.
  def whatsapp_presence_since?(time)
    whatsapp_receipt_since?(time) ||
      Message.incoming.where(conversation_id: Conversation.where(inbox_id: inbox_id, contact_id: contact_id).select(:id),
                             created_at: time.change(usec: 0)..).any? do |message|
        message.whatsapp_sent_at >= time
      end
  end

  # Per contact and inbox, like the flag's clearing: a receipt on any of the contact's threads
  # here proves the phone.
  def self.whatsapp_receipt_key(inbox_id, contact_id)
    format(Redis::Alfred::WHATSAPP_RECEIPT_SEEN, inbox_id: inbox_id, contact_id: contact_id)
  end

  def whatsapp_receipt_since?(time)
    seen = Redis::Alfred.get(self.class.whatsapp_receipt_key(inbox_id, contact_id))
    seen.present? && seen.to_f >= time.to_f
  end

  def clear_whatsapp_missing!
    return if whatsapp_missing_checked_at.nil?

    update!(whatsapp_missing_checked_at: nil)
  end

  # The dashboard orders conversation snapshots by updated_at and keeps an equal one, so the
  # version moves first: an older snapshot still carrying the previous flag cannot put it
  # back. update_column, because the flag is not the conversation's own change and its
  # update callbacks have nothing to do here.
  def broadcast_whatsapp_missing_change
    conversations.find_each do |conversation|
      conversation.update_column(:updated_at, Time.current) # rubocop:disable Rails/SkipsModelValidations
      # For the dashboard alone: announcing reaches the cable push and nothing else, so no
      # automation, bot or webhook takes a number lookup for a conversation update. Tagged so
      # the open thread does not jump to the bottom: no message arrived.
      Import::SilentWrite.wrap(announce: true) do
        conversation.dispatch_conversation_updated_event(broadcast_metadata: { source: 'whatsapp_missing' })
      end
    end
  end

  def whatsapp_missing_recheck_due?
    whatsapp_missing_checked_at.present? && whatsapp_missing_checked_at <= WHATSAPP_MISSING_RECHECK_AFTER.ago
  end

  # Whether this number has left the WhatsApp group this contact is.
  #
  # It lives here rather than on the contact because a group contact is
  # account-scoped (its identifier is the group's own id) while this row is per inbox,
  # so one WhatsApp group can belong to two inboxes of the same account. It used to be a
  # boolean on the shared contact, and one number leaving marked the group as left for
  # every other number in it: the dashboard hid the composer and the group actions on
  # threads that could still send, `sync_group` returned early and stopped refreshing
  # them, and nothing on the inboxes that stayed could clear it, because only a rejoin
  # clears it and they never left.
  def group_left? = group_left_at.present? || legacy_group_left?

  def mark_group_left!
    convert_legacy_group_left!
    return if group_left_at.present?

    update!(group_left_at: Time.current)
  end

  def mark_group_rejoined!
    convert_legacy_group_left!
    return if group_left_at.nil?

    update!(group_left_at: nil)
  end

  private

  # The migration that introduced the column deleted `group_left` from every contact, so
  # a truthy one can only have been written by a worker from the release before it: the
  # rolling deploy window, where a group left through the old code would otherwise be
  # read here as still joined.
  def legacy_group_left? = contact.additional_attributes&.dig('group_left').present?

  # Reading the old boolean is a stopgap; it says "left" without saying where, and it
  # cannot survive the first write of the new shape, because a rejoin here would clear
  # this row and then read the same stale `true` straight back. So the first write
  # converts: every inbox this group is in gets stamped, which is what the boolean meant
  # account wide, and the key goes. Same reading the data migration applies, and it runs
  # at most once per contact.
  def convert_legacy_group_left!
    return unless legacy_group_left?

    contact.with_lock do
      contact.contact_inboxes.where(group_left_at: nil).update_all(group_left_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
      contact.update!(additional_attributes: (contact.additional_attributes || {}).except('group_left'))
    end
    reload
  end

  def validate_twilio_source_id
    # https://www.twilio.com/docs/glossary/what-e164#regex-matching-for-e164
    if inbox.channel.medium == 'sms' && !TWILIO_CHANNEL_SMS_REGEX.match?(source_id)
      errors.add(:source_id, "invalid source id for twilio sms inbox. valid Regex #{TWILIO_CHANNEL_SMS_REGEX}")
    elsif inbox.channel.medium == 'whatsapp' && !TWILIO_CHANNEL_WHATSAPP_REGEX.match?(source_id)
      errors.add(:source_id, "invalid source id for twilio whatsapp inbox. valid Regex #{TWILIO_CHANNEL_WHATSAPP_REGEX}")
    end
  end

  def validate_whatsapp_source_id
    return if WHATSAPP_CHANNEL_REGEX.match?(source_id)

    errors.add(:source_id, "invalid source id for whatsapp inbox. valid Regex #{WHATSAPP_CHANNEL_REGEX}")
  end

  def valid_source_id_format?
    validate_twilio_source_id if inbox.channel_type == 'Channel::TwilioSms'
    validate_whatsapp_source_id if inbox.channel_type == 'Channel::Whatsapp'
  end
end

ContactInbox.prepend_mod_with('ContactInbox')
