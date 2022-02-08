# == Schema Information
#
# Table name: mentions
#
#  id              :bigint           not null, primary key
#  mentioned_at    :datetime         not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  conversation_id :bigint           not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_mentions_on_account_id                   (account_id)
#  index_mentions_on_conversation_id              (conversation_id)
#  index_mentions_on_user_id                      (user_id)
#  index_mentions_on_user_id_and_conversation_id  (user_id,conversation_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (conversation_id => conversations.id) ON DELETE => cascade
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
class Mention < ApplicationRecord
  before_validation :ensure_account_id
  validates :mentioned_at, presence: true
  validates :account_id, presence: true
  validates :conversation_id, presence: true
  validates :user_id, presence: true
  validates :user, uniqueness: { scope: :conversation }

  belongs_to :account
  belongs_to :conversation
  belongs_to :user

  after_commit :notify_mentioned_user

  scope :latest, -> { order(mentioned_at: :desc) }

  private

  def ensure_account_id
    self.account_id = conversation&.account_id
  end

  def notify_mentioned_user
    Rails.configuration.dispatcher.dispatch(CONVERSATION_MENTIONED, Time.zone.now, user: user, conversation: conversation)
  end
end
