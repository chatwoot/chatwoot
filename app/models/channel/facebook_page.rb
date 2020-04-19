# == Schema Information
#
# Table name: channel_facebook_pages
#
#  id                :integer          not null, primary key
#  page_access_token :string           not null
#  user_access_token :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :integer          not null
#  page_id           :string           not null
#
# Indexes
#
#  index_channel_facebook_pages_on_page_id                 (page_id)
#  index_channel_facebook_pages_on_page_id_and_account_id  (page_id,account_id) UNIQUE
#

class Channel::FacebookPage < ApplicationRecord
  # FIXME: this should be removed post 1.4 release. we moved avatars to inbox
  include Avatarable

  self.table_name = 'channel_facebook_pages'

  validates :account_id, presence: true
  validates :page_id, uniqueness: { scope: :account_id }
  belongs_to :account

  has_one :inbox, as: :channel, dependent: :destroy

  before_destroy :unsubscribe

  private

  def unsubscribe
    Facebook::Messenger::Subscriptions.unsubscribe(access_token: page_access_token)
  rescue => e
    true
  end
end
