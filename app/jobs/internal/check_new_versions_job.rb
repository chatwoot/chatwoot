class Internal::CheckNewVersionsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform(refresh_billing: false)
    return unless Rails.env.production?

    @instance_info = ChatwootHub.sync_with_hub(refresh_billing: refresh_billing)
    update_version_info
  end

  private

  def update_version_info
    return if @instance_info['version'].blank?

    ::Redis::Alfred.set(::Redis::Alfred::LATEST_CHATWOOT_VERSION, @instance_info['version'])
  end
end

Internal::CheckNewVersionsJob.prepend_mod_with('Internal::CheckNewVersionsJob')
