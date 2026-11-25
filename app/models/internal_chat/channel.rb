# == Schema Information
#
# Table name: internal_chat_channels
#
#  id               :bigint           not null, primary key
#  channel_type     :integer          default("public_channel"), not null
#  description      :text
#  last_activity_at :datetime         not null
#  messages_count   :integer          default(0)
#  name             :string
#  status           :integer          default("active"), not null
#  uuid             :uuid             not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#  category_id      :bigint
#  created_by_id    :bigint
#
# Indexes
#
#  idx_ic_channels_description_unaccent_trgm                    (f_unaccent(description) gin_trgm_ops) USING gin
#  idx_ic_channels_name_unaccent_trgm                           (f_unaccent((name)::text) gin_trgm_ops) USING gin
#  index_internal_chat_channels_on_account_id                   (account_id)
#  index_internal_chat_channels_on_account_id_and_category_id   (account_id,category_id)
#  index_internal_chat_channels_on_account_id_and_channel_type  (account_id,channel_type)
#  index_internal_chat_channels_on_account_id_and_status        (account_id,status)
#  index_internal_chat_channels_on_category_id                  (category_id)
#  index_internal_chat_channels_on_uuid                         (uuid) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (category_id => internal_chat_categories.id)
#  fk_rails_...  (created_by_id => users.id) ON DELETE => nullify
#
class InternalChat::Channel < ApplicationRecord
  self.table_name = 'internal_chat_channels'

  belongs_to :account
  belongs_to :category, class_name: 'InternalChat::Category', optional: true
  belongs_to :created_by, class_name: 'User', optional: true

  has_many :channel_members,
           class_name: 'InternalChat::ChannelMember',
           foreign_key: :internal_chat_channel_id,
           dependent: :destroy,
           inverse_of: :channel
  has_many :members, through: :channel_members, source: :user
  has_many :channel_teams,
           class_name: 'InternalChat::ChannelTeam',
           foreign_key: :internal_chat_channel_id,
           dependent: :destroy,
           inverse_of: :channel
  has_many :teams, through: :channel_teams
  has_many :messages,
           class_name: 'InternalChat::Message',
           foreign_key: :internal_chat_channel_id,
           dependent: :destroy,
           inverse_of: :channel
  has_many :message_attachments, through: :messages, source: :attachments
  has_many :drafts,
           class_name: 'InternalChat::Draft',
           foreign_key: :internal_chat_channel_id,
           dependent: :destroy,
           inverse_of: :channel

  enum :channel_type, { public_channel: 0, private_channel: 1, dm: 2 }, prefix: true
  enum :status, { active: 0, archived: 1 }

  validates :name, presence: true, unless: :channel_type_dm?
  validates :uuid, uniqueness: true

  before_validation :generate_uuid, on: :create
  before_validation :set_last_activity_at, on: :create

  scope :active, -> { where(status: :active) }
  scope :archived, -> { where(status: :archived) }
  scope :text_channels, -> { where.not(channel_type: :dm) }
  scope :direct_messages, -> { where(channel_type: :dm) }

  def dm?
    channel_type_dm?
  end

  def push_event_data
    {
      id: id,
      uuid: uuid,
      name: name,
      channel_type: channel_type,
      account_id: account_id,
      meta: {}
    }
  end

  private

  def generate_uuid
    self.uuid ||= SecureRandom.uuid
  end

  def set_last_activity_at
    self.last_activity_at ||= Time.current
  end
end

InternalChat::Channel.prepend_mod_with('InternalChat::Channel')
