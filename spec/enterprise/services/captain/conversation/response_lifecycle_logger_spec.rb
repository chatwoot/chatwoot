require 'rails_helper'

RSpec.describe Captain::Conversation::ResponseLifecycleLogger do
  describe '.info' do
    it 'writes searchable key value lifecycle data' do
      expect(Rails.logger).to receive(:info).with(
        '[CAPTAIN][ResponseLifecycle] event=job_started account_id=1 reason=conversation_not_pending error_class=RedisClient::CannotConnectError'
      )

      described_class.info(
        :job_started,
        account_id: 1,
        reason: 'conversation not pending',
        error_class: 'RedisClient::CannotConnectError',
        ignored: nil
      )
    end
  end
end
