# == Schema Information
#
# Table name: conversation_pins
#
#  id              :bigint           not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  conversation_id :bigint           not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_conversation_pins_on_account_id                   (account_id)
#  index_conversation_pins_on_conversation_id              (conversation_id)
#  index_conversation_pins_on_user_id_and_conversation_id  (user_id,conversation_id) UNIQUE
#
class ConversationPin < ApplicationRecord
  MAX_PER_USER = 5

  validates :account_id, presence: true
  validates :conversation_id, presence: true
  validates :user_id, presence: true
  validates :user_id, uniqueness: { scope: [:conversation_id] }
  validate :within_limit, on: :create
  validate :conversation_not_resolved, on: :create
  validate :conversation_visible, on: :create

  belongs_to :account
  belongs_to :conversation
  belongs_to :user

  # A pin only does anything while the agent can still see the conversation, so an inbox they left, a role
  # change, or a conversation deleted but not yet reaped by `destroy_async` takes the pin out of the list
  # and out of the limit. Filtering rather than deleting covers every way visibility can change, including
  # the ones a callback would miss, and gives the pin back if access returns.
  scope :visible_to, lambda { |user, account|
    where(user: user, account_id: account.id, conversation_id: accessible_conversations(user, account).select(:id))
  }

  # The list is what a pin reorders, so its visibility rule is the one that decides which pins may exist and
  # which ones are still worth keeping. ConversationPolicy#show? is deliberately broader (it also lets an
  # agent open a team's conversation by link), and a pin on something the list never shows does nothing.
  def self.accessible_conversations(user, account)
    Conversations::PermissionFilterService.new(account.conversations, user, account).perform
  end

  # Access can be lost in more ways than a callback could follow: an inbox left, a role changed, a team or
  # custom role edited. Reconciling before the cap is what keeps a hidden pin from holding a slot forever
  # without letting the persisted set outgrow it either.
  def self.prune_hidden(user, account)
    where(user: user, account_id: account.id).where.not(id: visible_to(user, account).select(:id)).destroy_all
  end

  before_validation :ensure_account_id
  after_create_commit :dispatch_pinned_event
  after_destroy_commit :dispatch_unpinned_event

  private

  def ensure_account_id
    self.account_id = conversation&.account_id
  end

  def within_limit
    return if user_id.blank? || account_id.blank?
    return if self.class.where(user_id: user_id, account_id: account_id).count < MAX_PER_USER

    errors.add(:base, I18n.t('errors.conversation_pins.limit_reached', limit: MAX_PER_USER))
  end

  # A resolved conversation is dropped from the agent's list and loses its pins on the way out, so pinning
  # one from the resolved view would only burn a slot.
  def conversation_not_resolved
    return if conversation.blank? || !conversation.resolved?

    errors.add(:base, I18n.t('errors.conversation_pins.conversation_resolved'))
  end

  # Creating a pin the list would never show it on would leave it visible until the next reload and then
  # silently gone, so it is rejected instead.
  def conversation_visible
    return if conversation.blank? || user.blank? || account.blank?
    return if self.class.accessible_conversations(user, account).exists?(id: conversation_id)

    errors.add(:base, I18n.t('errors.conversation_pins.conversation_not_visible'))
  end

  def dispatch_pinned_event
    dispatch_event(CONVERSATION_PINNED)
  end

  def dispatch_unpinned_event
    dispatch_event(CONVERSATION_UNPINNED)
  end

  # Pass serialized data instead of ActiveRecord objects to avoid DeserializationError when the async
  # EventDispatcherJob runs after the pin (or the conversation it belongs to) has been deleted.
  def dispatch_event(event_name)
    return if conversation.blank? || user.blank?

    Rails.configuration.dispatcher.dispatch(
      event_name,
      Time.zone.now,
      conversation_pin: {
        account_id: account_id,
        user_id: user_id,
        conversation_id: conversation.display_id,
        pinned_at: created_at.to_f
      }
    )
  end
end
