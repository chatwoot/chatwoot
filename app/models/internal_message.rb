class InternalMessage < ApplicationRecord
  CONTENT_MAX_LENGTH = 10_000

  belongs_to :account
  belongs_to :internal_conversation
  belongs_to :user

  validates :content, presence: true, length: { maximum: CONTENT_MAX_LENGTH }
  validate :user_belongs_to_account
  validate :conversation_belongs_to_account

  before_validation :ensure_account_id
  after_create_commit :bump_conversation_activity, :dispatch_created_event

  def push_event_data
    {
      id: id,
      account_id: account_id,
      internal_conversation_id: internal_conversation_id,
      user_id: user_id,
      content: content,
      created_at: created_at.to_i,
      user: user&.push_event_data
    }
  end

  private

  def ensure_account_id
    self.account_id ||= internal_conversation&.account_id
  end

  def user_belongs_to_account
    return if user.blank? || account_id.blank?
    return if AccountUser.exists?(account_id: account_id, user_id: user_id)

    errors.add(:user_id, 'must be an active account user')
  end

  def conversation_belongs_to_account
    return if internal_conversation.blank? || internal_conversation.account_id == account_id

    errors.add(:internal_conversation_id, 'must belong to the same account')
  end

  def bump_conversation_activity
    internal_conversation.bump_activity!(preview: content)
  end

  def dispatch_created_event
    Rails.configuration.dispatcher.dispatch(
      Events::Types::INTERNAL_MESSAGE_CREATED,
      Time.zone.now,
      internal_message: self
    )
  end
end
