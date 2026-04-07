class Internal::TriggerDailyScheduledItemsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    # Schedule daily deferred jobs here so each installation can spread load
    # across the day without changing its slot on deploys or restarts.
    schedule_version_check
  end

  private

  def schedule_version_check
    return unless Rails.env.production?

    Internal::CheckNewVersionsJob.set(wait_until: version_check_run_at).perform_later
  end

  def version_check_run_at
    Time.current.utc.beginning_of_day + designated_minute.minutes
  end

  def designated_minute
    @designated_minute ||= Digest::MD5.hexdigest(ChatwootHub.installation_identifier).hex % 1440
  end
end
