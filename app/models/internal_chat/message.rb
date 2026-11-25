# == Schema Information
#
# Table name: internal_chat_messages
#
#  id                       :bigint           not null, primary key
#  content                  :text
#  content_attributes       :jsonb
#  content_type             :integer          default("text"), not null
#  replies_count            :integer          default(0), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  account_id               :bigint           not null
#  echo_id                  :string
#  internal_chat_channel_id :bigint           not null
#  parent_id                :bigint
#  sender_id                :bigint
#
# Indexes
#
#  idx_ic_messages_account_created                           (account_id,created_at)
#  idx_ic_messages_channel_created                           (internal_chat_channel_id,created_at)
#  idx_ic_messages_content_unaccent_trgm                     (f_unaccent(content) gin_trgm_ops) USING gin
#  index_internal_chat_messages_on_account_id                (account_id)
#  index_internal_chat_messages_on_internal_chat_channel_id  (internal_chat_channel_id)
#  index_internal_chat_messages_on_parent_id                 (parent_id)
#  index_internal_chat_messages_on_sender_id                 (sender_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#  fk_rails_...  (internal_chat_channel_id => internal_chat_channels.id)
#  fk_rails_...  (parent_id => internal_chat_messages.id)
#  fk_rails_...  (sender_id => users.id) ON DELETE => nullify
#
class InternalChat::Message < ApplicationRecord
  self.table_name = 'internal_chat_messages'

  belongs_to :account
  belongs_to :channel, class_name: 'InternalChat::Channel', foreign_key: :internal_chat_channel_id,
                       counter_cache: :messages_count, inverse_of: :messages
  belongs_to :sender, class_name: 'User', optional: true
  belongs_to :parent, class_name: 'InternalChat::Message', optional: true, inverse_of: :replies, counter_cache: :replies_count

  has_many :replies, class_name: 'InternalChat::Message', foreign_key: :parent_id,
                     dependent: :destroy, inverse_of: :parent
  has_many :attachments, class_name: 'InternalChat::MessageAttachment', foreign_key: :internal_chat_message_id,
                         dependent: :destroy, inverse_of: :message
  has_many :reactions, class_name: 'InternalChat::Reaction', foreign_key: :internal_chat_message_id,
                       dependent: :destroy, inverse_of: :message
  has_one :poll, class_name: 'InternalChat::Poll', foreign_key: :internal_chat_message_id,
                 dependent: :destroy, inverse_of: :message

  enum :content_type, { text: 0, poll: 1, system: 2 }

  attr_accessor :skip_content_validation

  validates :content, presence: true, unless: -> { skip_content_validation || !text? }
  validates :content, length: { maximum: 150_000 }

  scope :ordered, -> { order(created_at: :asc) }
  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :update_channel_activity

  def edited?
    content_attributes&.dig('edited_at').present?
  end

  def thread?
    parent_id.present?
  end

  def thread_replies_count
    replies_count
  end

  def push_event_data
    {
      id: id,
      content: content,
      content_type: content_type,
      internal_chat_channel_id: internal_chat_channel_id,
      sender: sender&.push_event_data
    }
  end

  private

  # Atomic compare-and-set so concurrent message creates can never regress
  # last_activity_at to an older timestamp.
  def update_channel_activity
    # rubocop:disable Rails/SkipsModelValidations
    InternalChat::Channel.where(id: internal_chat_channel_id)
                         .where('last_activity_at IS NULL OR last_activity_at < ?', created_at)
                         .update_all(last_activity_at: created_at)
    # rubocop:enable Rails/SkipsModelValidations
  end
end

InternalChat::Message.prepend_mod_with('InternalChat::Message')
