class SendOnSlackJob < MutexApplicationJob
  queue_as :medium
  retry_on LockAcquisitionError, wait: 1.second, attempts: 6

  def perform(message, hook)
    with_lock(::Redis::Alfred::SLACK_MESSAGE_MUTEX, conversation_id: message.conversation_id, reference_id: hook.reference_id) do
      Integrations::Slack::SendOnSlackService.new(message: message, hook: hook).perform
    end
  end
end
