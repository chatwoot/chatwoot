class EmailInbox < ApplicationRecord

  validates :account_id, presence: true
  validates_uniqueness_of :email
  belongs_to :account
  mount_uploader :avatar, AvatarUploader

  has_one :inbox, as: :channel, dependent: :destroy

  def name
    "Email"
  end
end
