class Influencers::FetchReportJob < ApplicationJob
  queue_as :medium
  retry_on InfluencersClub::Client::ApiError, wait: :polynomially_longer, attempts: 3

  def perform(profile_id)
    profile = InfluencerProfile.find(profile_id)
    return unless profile.report_pending? || profile.discovered?

    profile.update!(status: :report_pending) if profile.discovered?

    response = InfluencersClub::EnrichService.new.perform(username: profile.username)
    return handle_empty_report(profile) if response.blank?

    attrs = InfluencersClub::ResponseParser.parse_enrich(response)
    profile.update!(
      attrs.merge(
        report_fetched_at: Time.current,
        status: :report_fetched,
        last_synced_at: Time.current
      )
    )

    Avatar::AvatarFromUrlJob.perform_later(profile.contact, profile.profile_picture_url) if profile.profile_picture_url.present?
    Influencers::ScoreProfileJob.perform_later(profile.id)
  rescue InfluencersClub::Client::ApiError => e
    handle_api_failure(profile, e)
    raise if retries_remaining?(e)
  end

  private

  def handle_empty_report(profile)
    Rails.logger.warn("[Influencers::FetchReportJob] Empty enrich for profile #{profile.id} (#{profile.username})")
    profile.update!(status: :discovered, rejection_reason: 'Enrichment returned empty report')
  end

  def handle_api_failure(profile, error)
    reason = if error.message.include?('credits')
               'No credits remaining'
             else
               "API error: #{error.code}"
             end
    profile.update!(status: :discovered, rejection_reason: "Enrich failed: #{reason}")
    Rails.logger.error("[Influencers::FetchReportJob] Failed for #{profile.username}: #{error.message}")
  end

  def retries_remaining?(_error)
    executions < 3
  end
end
