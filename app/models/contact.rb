class Contact < ApplicationRecord

  validates :account_id, presence: true
  validates :inbox_id, presence: true

  belongs_to :account
  belongs_to :inbox
  has_many :conversations, dependent: :destroy, foreign_key: :sender_id
  mount_uploader :avatar, AvatarUploader

  before_create :set_channel

  def push_event_data
    {
      id: id,
      name: name,
      thumbnail: avatar.thumb.url,
      channel: inbox.try(:channel).try(:name),
      chat_channel: chat_channel
    }
  end

  def set_channel
    begin
    self.chat_channel = SecureRandom.hex
    end while self.class.exists?(chat_channel: chat_channel)
  end
end
