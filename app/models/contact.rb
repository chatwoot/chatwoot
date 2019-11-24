class Contact < ApplicationRecord
  include Pubsubable
  validates :account_id, presence: true

  belongs_to :account
  has_many :conversations, dependent: :destroy
  has_many :contact_inboxes, dependent: :destroy
  has_many :inboxes, through: :contact_inboxes
  mount_uploader :avatar, AvatarUploader

  def get_source_id(inbox_id)
    contact_inboxes.find_by!(inbox_id: inbox_id).source_id
  end

  def push_event_data
    {
      id: id,
      name: name,
      thumbnail: avatar.thumb.url,
      pubsub_token: pubsub_token
    }
  end
end
