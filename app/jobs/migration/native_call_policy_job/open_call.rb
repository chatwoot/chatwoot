# The calls table, read without Enterprise's Call model, which a CE install does not load: the
# rows exist only where Enterprise once ran, and Migration::NativeCallPolicyJob has to end the
# connector's open ones either way.
class Migration::NativeCallPolicyJob::OpenCall < ApplicationRecord
  self.table_name = 'calls'
  belongs_to :message, optional: true
  # Optional: on CE nothing removes a deleted conversation's calls.
  belongs_to :conversation, optional: true

  # Ringing never answered is a missed call; one under way lasted until now. The call and what
  # shows it are written together, so a write that fails leaves the call open for the next run
  # instead of ended with a message that still rings.
  def end!(reason:)
    ended = status == 'in_progress' ? 'completed' : 'no_answer'
    duration = [(Time.current - started_at).to_i, 0].max if ended == 'completed' && started_at

    transaction do
      update!(status: ended, end_reason: reason, duration_seconds: duration)
      show_end(ended.tr('_', '-'), duration)
    end
  end

  private

  def show_end(display_status, duration)
    message&.update!(content_attributes: (message.content_attributes || {}).deep_merge(
      'data' => { 'status' => display_status, 'duration_seconds' => duration }.compact
    ))
    conversation&.update!(additional_attributes: (conversation.additional_attributes || {}).merge('call_status' => display_status))
  end
end
