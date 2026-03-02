class Influencers::ScoreProfileJob < ApplicationJob
  queue_as :medium

  def perform(profile_id, auto_decide: false) # rubocop:disable Lint/UnusedMethodArgument
    profile = InfluencerProfile.find(profile_id)
    return if profile.accepted? || profile.contacted?

    Influencers::FqsCalculator.new(profile).perform
  end
end
