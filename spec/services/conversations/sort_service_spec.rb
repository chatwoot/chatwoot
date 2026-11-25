require 'rails_helper'

RSpec.describe Conversations::SortService do
  let(:account) { create(:account) }
  let(:scope) { account.conversations }
  let(:timestamp) { Time.current.change(usec: 200) }
  let!(:empty) { create(:conversation, account: account) }
  let!(:older) { create(:conversation, account: account, last_message_at: timestamp - 0.0001.seconds) }
  let!(:first) { create(:conversation, account: account, last_message_at: timestamp) }
  let!(:second) { create(:conversation, account: account, last_message_at: timestamp) }

  it 'keeps ties stable across pages and puts missing times last in both directions' do
    account.enable_features!(:last_message_sort)
    newest = described_class.apply(scope, 'last_message_at_desc', account: account)
    oldest = described_class.apply(scope, 'last_message_at_asc', account: account)

    expect(newest.page(1).per(1)).to eq([second])
    expect(newest.page(2).per(1)).to eq([first])
    expect(newest).to eq([second, first, older, empty])
    expect(oldest).to eq([older, first, second, empty])
  end

  it 'uses the ordinary queue order until the account has the sort enabled' do
    account.disable_features!(:last_message_sort)
    expect(described_class.apply(scope, 'last_message_at_desc', account: account)).to eq(scope.sort_on_last_activity_at(:desc))
  end
end
