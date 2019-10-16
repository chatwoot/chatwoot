class Contact < ApplicationRecord
  include Pubsubable
  
  validates :account_id, presence: true
  validates :inbox_id, presence: true

  belongs_to :account
  belongs_to :inbox
  has_many :conversations, dependent: :destroy, foreign_key: :sender_id
  mount_uploader :avatar, AvatarUploader

  def push_event_data
    {
      id: id,
      name: name,
      thumbnail: avatar.thumb.url,
      channel: inbox.try(:channel).try(:name),
      pubsub_token: pubsub_token
    }
  end
end
