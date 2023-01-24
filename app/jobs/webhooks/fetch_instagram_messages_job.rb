class Webhooks::FetchInstagramMessagesJob < ApplicationJob
  queue_as :default

  include HTTParty

  def perform
    story_messages = Message.where("content_attributes->>'image_type' = ?", 'story_mention')
    story_messages.each(&:validate_instagram_story)
  end
end
