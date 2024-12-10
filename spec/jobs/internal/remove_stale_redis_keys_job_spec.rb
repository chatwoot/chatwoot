require 'rails_helper'

RSpec.describe Internal::RemoveStaleRedisKeysJob, type: :job do
  let(:account) { create(:account) }

  describe '#perform' do
    it 'enqueues ProcessStaleRedisKeysJob for the account' do
      expect(Internal::ProcessStaleRedisKeysJob).to receive(:perform_later).with(account)

      described_class.perform_now
    end
  end
end
