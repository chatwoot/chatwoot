class Internal::CheckNewVersionsJob < ApplicationJob
  queue_as :scheduled_jobs

  # The fork reads its newest release from GitHub instead of syncing with Chatwoot's hub, so there
  # is no billing to refresh: the keyword the Super Admin refresh and Enterprise's override pass
  # (`refresh_billing:`) is taken and has nothing to act on. Truthy when the version was read.
  def perform(**)
    return unless Rails.env.production?

    latest_version = fetch_latest_github_release
    ::Redis::Alfred.set(::Redis::Alfred::LATEST_CHATWOOT_VERSION, latest_version) if latest_version.present?
    latest_version.present?
  end

  private

  def fetch_latest_github_release
    # `max_retries: 0` alongside the ceiling: `Net::HTTP` repeats an idempotent request
    # once by default, so 5 seconds was 10 against a GitHub that accepts and stalls.
    response = HTTParty.get('https://api.github.com/repos/fazer-ai/chatwoot/releases/latest', timeout: 5, max_retries: 0)
    unless response.success?
      Rails.logger.error "Failed to fetch latest GitHub release: HTTP #{response.code} - #{response.body}"
      return nil
    end

    response['tag_name']&.sub(/^v/, '')
  rescue StandardError => e
    Rails.logger.error "Failed to fetch latest GitHub release: #{e.message}"
    nil
  end
end

Internal::CheckNewVersionsJob.prepend_mod_with('Internal::CheckNewVersionsJob')
