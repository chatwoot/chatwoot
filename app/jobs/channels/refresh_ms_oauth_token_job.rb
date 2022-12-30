class Channels::RefreshMsOauthTokenJob < ApplicationJob
  queue_as :low

  def perform
    Channel::Email.all.each do |inbox|
      # refresh the token here, offline access should work
    end
  end
end
