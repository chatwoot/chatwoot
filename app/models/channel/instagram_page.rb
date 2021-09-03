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
#  index_channel_instagram_pages_on_page_id                 (page_id)
#  index_channel_instagram_pages_on_page_id_and_account_id  (page_id,account_id) UNIQUE
#

class Channel::InstagramPage < Channel::FacebookPage
  self.table_name = 'channel_instagram_pages'

  include Reauthorizable

  validates :account_id, presence: true
  validates :page_id, uniqueness: { scope: :account_id }
  belongs_to :account

  has_one :inbox, as: :channel, dependent: :destroy

  after_create_commit :subscribe
  before_destroy :unsubscribe

  def name
    'Instagram'
  end

  def has_24_hour_messaging_window?
    true
  end

  def subscribe
    # ref https://developers.facebook.com/docs/messenger-platform/reference/webhook-events
    access_token = page_access_token
    subscribed_fields = %w[
      messages messaging_postbacks messaging_seen messaging_handover message_reactions
    ]
    response = post '/subscribed_apps',
                    headers: { 'Content-Type' => 'application/json' },
                    body: {
                      access_token: access_token,
                      subscribed_fields: subscribed_fields
                    }.to_json
  rescue => e
    Rails.logger.debug { "Rescued: #{e.inspect}" }
    true
  end

  def unsubscribe
    response = delete '/subscribed_apps', query: {
                access_token: access_token
              }
  rescue => e
    Rails.logger.debug { "Rescued: #{e.inspect}" }
    true
  end
end
