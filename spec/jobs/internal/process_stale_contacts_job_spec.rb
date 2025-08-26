require 'rails_helper'

RSpec.describe Internal::ProcessStaleContactsJob do
  subject(:job) { described_class.perform_later }

  context 'when in cloud environment' do
    before do
      allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
    end

    it 'processes accounts based on the day of month' do
      # Set a fixed day for testing
      day_of_month = 16
      remainder = day_of_month % described_class::DISTRIBUTION_GROUPS
      allow(Date).to receive(:current).and_return(Date.new(2025, 5, day_of_month))

      # Create an account and set its ID to match today's pattern
      account = create(:account)
      allow(account).to receive(:id).and_return(remainder)

      # Mock the Account.where to return our filtered accounts
      account_relation = double
      allow(Account).to receive(:where).with("id % #{described_class::DISTRIBUTION_GROUPS} = ?", remainder).and_return(account_relation)
      allow(account_relation).to receive(:find_each).and_yield(account)

      # Mock the delay setting
      allow(Internal::RemoveStaleContactsJob).to receive(:set).and_return(Internal::RemoveStaleContactsJob)
      expect(Internal::RemoveStaleContactsJob).to receive(:perform_later).with(account)

      described_class.perform_now
    end

    it 'adds a delay between jobs' do
      day_of_month = 15
      remainder = day_of_month % described_class::DISTRIBUTION_GROUPS
      allow(Date).to receive(:current).and_return(Date.new(2025, 5, day_of_month))

      account = create(:account)

      account_relation = double
      allow(Account).to receive(:where).with("id % #{described_class::DISTRIBUTION_GROUPS} = ?", remainder).and_return(account_relation)
      allow(account_relation).to receive(:find_each).and_yield(account)

      expect(Internal::RemoveStaleContactsJob).to receive(:set) do |args|
        expect(args[:wait]).to be_between(1.minute, 10.minutes)
        Internal::RemoveStaleContactsJob
      end
      expect(Internal::RemoveStaleContactsJob).to receive(:perform_later).with(account)

      described_class.perform_now
    end
  end

  context 'when not in cloud environment' do
    it 'does not process any accounts' do
      allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)

      expect(Account).not_to receive(:where)
      expect(Internal::RemoveStaleContactsJob).not_to receive(:perform_later)

      described_class.perform_now
    end
  end
end
