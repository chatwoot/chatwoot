require 'rails_helper'

RSpec.describe TriggerScheduledItemsJob do
  subject(:job) { described_class.perform_later }

  it 'triggers Sla::TriggerSlasForAccountsJob' do
    expect(Sla::TriggerSlasForAccountsJob).to receive(:perform_later).once
    described_class.perform_now
  end
end
