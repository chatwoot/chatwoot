class Influencers::ApifyEnrichJob < ApplicationJob
  queue_as :medium
  retry_on Apify::Client::ApiError, wait: :polynomially_longer, attempts: 3

  def perform(profile_id)
    profile = InfluencerProfile.find(profile_id)
    return if profile.apify_apify_done?

    profile.update!(apify_status: :apify_pending, apify_error: nil)
    attrs = fetch_and_parse(profile)
    return mark_failed(profile, 'Empty response from Apify') if attrs.blank?

    profile.update!(attrs.merge(apify_status: :apify_done, apify_enriched_at: Time.current, apify_error: nil))
    Avatar::AvatarFromUrlJob.perform_later(profile.contact, attrs[:profile_picture_url]) if attrs[:profile_picture_url].present?
    Influencers::DownloadMediaJob.perform_now(profile.id) # sync — CDN URLs expire quickly
    Influencers::ScoreProfileJob.perform_later(profile.id)
  rescue Apify::Client::ApiError => e
    mark_failed(profile, e.message.truncate(255))
    raise if executions < 3
  end

  private

  def fetch_and_parse(profile)
    data = Apify::Client.new.scrape_profiles([profile.username])&.first
    return nil if data.blank?

    Apify::ResponseParser.parse(data)
  end

  def mark_failed(profile, error)
    profile.update!(apify_status: :apify_failed, apify_error: error)
  end
end
