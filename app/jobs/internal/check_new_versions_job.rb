class Internal::CheckNewVersionsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    latest_version = ChatwootHub.latest_version
    return unless latest_version

    ::Redis::Alfred.set(::Redis::Alfred::LATEST_CHATWOOT_VERSION, latest_version)
  end
end
