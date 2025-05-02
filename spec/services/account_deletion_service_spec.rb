require 'rails_helper'

RSpec.describe AccountDeletionService do
  let(:account) { create(:account) }

  describe '#perform' do
    it 'enqueues DeleteObjectJob with the account' do
      allow(DeleteObjectJob).to receive(:perform_later)

      described_class.new(account: account).perform

      expect(DeleteObjectJob).to have_received(:perform_later).with(account)
    end
  end
end
