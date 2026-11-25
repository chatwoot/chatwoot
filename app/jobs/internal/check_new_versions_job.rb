class Internal::CheckNewVersionsJob < ApplicationJob
  queue_as :scheduled_jobs

  # rise-brasil: updates for this fork are rolled out by us, so installations never look up or
  # advertise a newer upstream release. Clearing the key drops a version stored by an older build,
  # which is what the update banner, the account settings notice and the super admin brand read.
  # An install running Enterprise still holds a Chatwoot plan, which only comes from the hub:
  # Enterprise's override reads `@instance_info` to store it, so the hub sync stays.
  def perform(refresh_billing: false)
    return unless Rails.env.production?

    ::Redis::Alfred.delete(::Redis::Alfred::LATEST_CHATWOOT_VERSION)
    return true unless ChatwootApp.enterprise?

    @instance_info = ChatwootHub.sync_with_hub(refresh_billing: refresh_billing)
    @instance_info.present?
  end
end

Internal::CheckNewVersionsJob.prepend_mod_with('Internal::CheckNewVersionsJob')
