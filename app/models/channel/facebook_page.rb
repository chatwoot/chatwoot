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
#  instagram_id      :string
#  page_id           :string           not null
#
# Indexes
#
#  index_channel_facebook_pages_on_page_id                 (page_id)
#  index_channel_facebook_pages_on_page_id_and_account_id  (page_id,account_id) UNIQUE
#

class Channel::FacebookPage < ApplicationRecord
  include Channelable
  include Reauthorizable

  self.table_name = 'channel_facebook_pages'

  validates :page_id, uniqueness: { scope: :account_id }

  after_create_commit :subscribe
  before_destroy :unsubscribe

  def name
    'Facebook'
  end

  def messaging_window_enabled?
    false
  end

  def create_contact_inbox(instagram_id, name)
    @contact_inbox = ::ContactInboxWithContactBuilder.new({
                                                            source_id: instagram_id,
                                                            inbox: inbox,
                                                            contact_attributes: { name: name }
                                                          }).perform
  end

  def subscribe
    # ref https://developers.facebook.com/docs/messenger-platform/reference/webhook-events
    response = Facebook::Messenger::Subscriptions.subscribe(
      access_token: page_access_token,
      subscribed_fields: %w[
        messages message_deliveries message_echoes message_reads standby messaging_handovers
      ]
    )
  rescue => e
    Rails.logger.debug { "Rescued: #{e.inspect}" }
    true
  end

  def unsubscribe
    Facebook::Messenger::Subscriptions.unsubscribe(access_token: page_access_token)
  rescue => e
    Rails.logger.debug { "Rescued: #{e.inspect}" }
    true
  end

  # TODO: We will be removing this code after instagram_manage_insights is implemented
  def fetch_instagram_story_link(message)
    k = Koala::Facebook::API.new(page_access_token)
    result = k.get_object(message.source_id, fields: %w[story]) || {}
    story_link = result['story']['mention']['link']
    # If the story is expired then it raises the ClientError and if the story is deleted with valid story-id it responses with nil
    delete_instagram_story(message) if story_link.blank?
    story_link
  rescue Koala::Facebook::ClientError => e
    delete_instagram_story(message)
  end

  def delete_instagram_story(message)
    message.attachments.destroy_all
    message.update(content: I18n.t('conversations.messages.instagram_deleted_story_content'), content_attributes: {})
  end
end
