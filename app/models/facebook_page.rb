class FacebookPage < ApplicationRecord
  validates :account_id, presence: true
  validates_uniqueness_of :page_id, scope: :account_id
  mount_uploader :avatar, AvatarUploader
  belongs_to :account

  has_one :inbox, as: :channel, dependent: :destroy

  before_destroy :unsubscribe

  def name
    'Facebook'
  end

  private

  def unsubscribe
    Facebook::Messenger::Subscriptions.unsubscribe(access_token: page_access_token)
  rescue StandardError => e
    true
  end
end
