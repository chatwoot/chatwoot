require 'rails_helper'

RSpec.describe Internal::ProcessStaleRedisKeysJob do
  let(:account) { create(:account) }

  describe '#perform' do
    it 'calls the RemoveStaleRedisKeysService with the correct account ID' do
      expect(Internal::RemoveStaleRedisKeysService).to receive(:new)
        .with(account_id: account.id)
        .and_call_original

      described_class.perform_now(account)
    end
  end
end
