# Asks the connector again for every native inbox that has a session to resume, so that none
# of them goes on with a call policy this installation no longer sends.
#
# First written for fazer-ai/chatwoot#850, when inboxes paired while the session layer asked
# the connector to refuse every call needed a new connect to stop doing it. Run again when
# calling through the connector was withdrawn: an inbox that had calling on was connected
# with `calls.answer`, and the connector keeps the policy of the last connect and stands on it
# when the session comes back, so without a new connect it would go on answering calls that
# nobody here takes. The `calling_enabled` flag such an inbox kept is cleared first, so the
# record no longer says calls are on.
#
# A connector call still ringing or under way at the upgrade is ended here too: nothing
# reads its `call.terminate` any more, so it would stay open for good, block the next call
# and come back as ringing whenever its message is loaded. Only calls of the session inboxes:
# a Cloud API call is Enterprise's, and its end still arrives through Meta.
#
# Each inbox goes through ApplyProxyJob, which sends the whole desired state and retries while
# the connector is down. They are spread a few at a time, the pacing of the
# `whatsapp:session:reassert` rake: `wa:control` is one stream for the whole fleet, and every
# account asked dials.
#
# Run again by hand: Migration::NativeCallPolicyJob.perform_now
class Migration::NativeCallPolicyJob < ApplicationJob
  queue_as :async_database_migration

  BATCH = 4
  PAUSE = 10.seconds
  END_REASON = 'connector_calling_withdrawn'.freeze

  def perform
    clear_calling_flags
    end_open_calls

    channels = Channel::Whatsapp.where(provider: 'native').select(&:resumable_session?)

    channels.each_slice(BATCH).with_index do |slice, index|
      slice.each { |channel| Whatsapp::Session::ApplyProxyJob.set(wait: index * PAUSE).perform_later(channel.id) }
    end

    Rails.logger.info("[native-call-policy] asked again inboxes=#{channels.size}")
  end

  private

  def end_open_calls
    inbox_ids = Inbox.where(channel_type: 'Channel::Whatsapp',
                            channel_id: Channel::Whatsapp.where(provider: Whatsapp::Session::PROVIDERS).select(:id)).select(:id)
    OpenCall.where(inbox_id: inbox_ids, status: %w[ringing in_progress]).find_each { |call| end_call(call) }
  end

  def end_call(call)
    call.end!(reason: END_REASON)
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.warn("[native-call-policy] call ##{call.id} left open: #{e.message}")
  end

  # Written past the callbacks: a save would run the provider-config change hooks, which
  # connect the inbox on their own, and this job already does that, paced.
  def clear_calling_flags
    Channel::Whatsapp.where(provider: Whatsapp::Session::PROVIDERS).find_each do |channel|
      next unless channel.provider_config.to_h.key?('calling_enabled')

      # rubocop:disable Rails/SkipsModelValidations
      channel.update_column(:provider_config, channel.provider_config.except('calling_enabled'))
      # rubocop:enable Rails/SkipsModelValidations
    end
  end
end
