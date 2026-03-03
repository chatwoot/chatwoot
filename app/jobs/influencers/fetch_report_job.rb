class Influencers::FetchReportJob < ApplicationJob
  queue_as :medium
  retry_on InfluencersClub::Client::ApiError, wait: :polynomially_longer, attempts: 3

  def perform(profile_id)
    profile = InfluencerProfile.find(profile_id)
    return unless profile.discovered?

    profile.update!(enrichment_pending: true)

    response = InfluencersClub::EnrichService.new.perform(username: profile.username)
    return handle_empty_report(profile) if response.blank?

    attrs = InfluencersClub::ResponseParser.parse_enrich(response)
    contact_email = attrs.delete(:_contact_email)
    profile.update!(
      attrs.merge(
        report_fetched_at: Time.current,
        status: :enriched,
        enrichment_pending: false,
        last_synced_at: Time.current
      )
    )
    profile.contact.update!(email: contact_email) if contact_email.present? && profile.contact.email.blank?

    Avatar::AvatarFromUrlJob.perform_later(profile.contact, profile.profile_picture_url) if profile.profile_picture_url.present?
    Influencers::ScoreProfileJob.perform_later(profile.id)
  rescue InfluencersClub::Client::ApiError => e
    handle_api_failure(profile, e)
    raise if retries_remaining?(e)
  end

  private

  def handle_empty_report(profile)
    Rails.logger.warn("[Influencers::FetchReportJob] Empty enrich for profile #{profile.id} (#{profile.username})")
    profile.update!(enrichment_pending: false, rejection_reason: 'Enrichment returned empty report')
  end

  def handle_api_failure(profile, error)
    reason = if error.message.include?('credits')
               'No credits remaining'
             else
               "API error: #{error.code}"
             end
    profile.update!(enrichment_pending: false, rejection_reason: "Enrich failed: #{reason}")
    Rails.logger.error("[Influencers::FetchReportJob] Failed for #{profile.username}: #{error.message}")
  end

  def retries_remaining?(_error)
    executions < 3
  end
end
