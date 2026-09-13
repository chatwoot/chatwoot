class Captain::AproposSession < ApplicationRecord
  self.table_name = 'captain_apropos_sessions'

  belongs_to :account
  belongs_to :user

  validates :status, inclusion: { in: %w[ready queued running failed] }

  def enqueue!(message)
    raise Captain::Apropos::Error, 'Message must contain 1 to 10000 characters' unless message.is_a?(String) && message.strip.length.between?(1,
                                                                                                                                              10_000)

    with_lock do
      raise Captain::Apropos::Error, 'A turn is already in progress' if %w[queued running].include?(status)

      update!(status: 'queued', messages: messages + [{ 'role' => 'user', 'content' => message.strip, 'turn_id' => SecureRandom.uuid }])
    end
    Captain::AproposTurnJob.perform_later(id)
  rescue ActiveJob::EnqueueError
    update!(status: 'failed')
    raise
  end

  def public_payload
    { id: id, status: status, messages: messages, trace: trace, updated_at: updated_at }
  end
end
