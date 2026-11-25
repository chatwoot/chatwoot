# == Schema Information
#
# Table name: internal_chat_drafts
#
#  id                       :bigint           not null, primary key
#  content                  :text             not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  account_id               :bigint           not null
#  internal_chat_channel_id :bigint           not null
#  parent_id                :bigint
#  user_id                  :bigint           not null
#
# Indexes
#
#  idx_ic_drafts_channel                     (internal_chat_channel_id)
#  idx_ic_drafts_user_channel_root           (user_id,internal_chat_channel_id) UNIQUE WHERE (parent_id IS NULL)
#  idx_ic_drafts_user_channel_thread         (user_id,internal_chat_channel_id,parent_id) UNIQUE WHERE (parent_id IS NOT NULL)
#  idx_ic_drafts_user_updated                (user_id,updated_at)
#  index_internal_chat_drafts_on_account_id  (account_id)
#  index_internal_chat_drafts_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (internal_chat_channel_id => internal_chat_channels.id)
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
class InternalChat::Draft < ApplicationRecord
  self.table_name = 'internal_chat_drafts'

  belongs_to :account
  belongs_to :user
  belongs_to :channel, class_name: 'InternalChat::Channel', foreign_key: :internal_chat_channel_id, inverse_of: :drafts
  belongs_to :parent, class_name: 'InternalChat::Message', optional: true

  validates :content, presence: true
  validates :user_id, uniqueness: { scope: [:internal_chat_channel_id, :parent_id] }

  scope :recent, -> { order(updated_at: :desc) }
end

InternalChat::Draft.prepend_mod_with('InternalChat::Draft')
