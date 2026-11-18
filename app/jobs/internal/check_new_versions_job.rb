class Internal::CheckNewVersionsJob < ApplicationJob
  queue_as :scheduled_jobs

  # The fork's newest version comes from its own GitHub releases, not from Chatwoot's hub, whose
  # version is upstream's. An install running Enterprise still holds a Chatwoot plan, and that plan
  # only comes from the hub: Enterprise's override reads `@instance_info` to store it, so the hub
  # sync stays there and only there. Truthy when everything this install depends on was read.
  def perform(refresh_billing: false)
    return unless Rails.env.production?

    @instance_info = ChatwootHub.sync_with_hub(refresh_billing: refresh_billing) if ChatwootApp.enterprise?
    latest_version = fetch_latest_github_release
    ::Redis::Alfred.set(::Redis::Alfred::LATEST_CHATWOOT_VERSION, latest_version) if latest_version.present?
    return @instance_info.present? if ChatwootApp.enterprise?

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
