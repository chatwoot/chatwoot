# == Schema Information
#
# Table name: contacts
#
#  id           :integer          not null, primary key
#  avatar       :string
#  email        :string
#  name         :string
#  phone_number :string
#  pubsub_token :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :integer          not null
#
# Indexes
#
#  index_contacts_on_account_id    (account_id)
#  index_contacts_on_pubsub_token  (pubsub_token) UNIQUE
#

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
