# == Schema Information
#
# Table name: channel_tiktok
#
#  id                       :bigint           not null, primary key
#  access_token             :string           not null
#  expires_at               :datetime         not null
#  refresh_token            :string           not null
#  refresh_token_expires_at :datetime         not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  account_id               :integer          not null
#  business_id              :string           not null
#
# Indexes
#
#  index_channel_tiktok_on_business_id  (business_id) UNIQUE
#
class Channel::Tiktok < ApplicationRecord
  include Channelable
  include Reauthorizable
  self.table_name = 'channel_tiktok'

  AUTHORIZATION_ERROR_THRESHOLD = 1

  validates :business_id, uniqueness: true, presence: true
  validates :access_token, presence: true
  validates :refresh_token, presence: true
  validates :expires_at, presence: true
  validates :refresh_token_expires_at, presence: true

  # after_create_commit :subscribe
  # before_destroy :unsubscribe

  def name
    'Tiktok'
  end

  # def create_contact_inbox(tiktok_id, name)
  #   @contact_inbox = ::ContactInboxWithContactBuilder.new({
  #                                                           source_id: tiktok_id,
  #                                                           inbox: inbox,
  #                                                           contact_attributes: { name: name }
  #                                                         }).perform
  # end

  # def subscribe
  #   # ref https://developers.facebook.com/docs/instagram-platform/webhooks#enable-subscriptions
  #   HTTParty.post(
  #     "https://graph.instagram.com/v22.0/#{instagram_id}/subscribed_apps",
  #     query: {
  #       subscribed_fields: %w[messages message_reactions messaging_seen],
  #       access_token: access_token
  #     }
  #   )
  # rescue StandardError => e
  #   Rails.logger.debug { "Rescued: #{e.inspect}" }
  #   true
  # end

  # def unsubscribe
  #   HTTParty.delete(
  #     "https://graph.instagram.com/v22.0/#{instagram_id}/subscribed_apps",
  #     query: {
  #       access_token: access_token
  #     }
  #   )
  #   true
  # rescue StandardError => e
  #   Rails.logger.debug { "Rescued: #{e.inspect}" }
  #   true
  # end
  #
  #
  #
  def find_message(tt_conversation_id, tt_message_id)
    message = Message.find_by(source_id: tt_message_id)
    message_conversation_id = message&.conversation&.[](:additional_attributes)&.[]('conversation_id')
    return nil if message_conversation_id != tt_conversation_id

    message
  end

  def find_conversation(tt_conversation_id)
    inbox.contact_inboxes.find_by(source_id: tt_conversation_id).conversations.first
  end

  def validated_access_token
    Tiktok::TokenService.new(channel: self).access_token
  end
end
