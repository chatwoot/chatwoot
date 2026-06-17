require 'rails_helper'

RSpec.describe Conversations::UnreadCounts::UserFilterNotifier do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:store) { Conversations::UnreadCounts::Store }

  after do
    store.clear_all_account!(account.id)
  end

  it 'clears the user filter cache and dispatches an unread count refresh event' do
    account.enable_features!(:conversation_unread_counts)
    store.mark_filters_ready!(account.id, user.id)
    allow(Rails.configuration.dispatcher).to receive(:dispatch)

    described_class.new(account: account, user: user).perform

    expect(store.filters_ready?(account.id, user.id)).to be(false)
    expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(
      'conversation.unread_count_changed',
      kind_of(Time),
      account: account,
      user: user
    )
  end

  it 'does nothing when conversation unread counts are disabled' do
    store.mark_filters_ready!(account.id, user.id)
    allow(Rails.configuration.dispatcher).to receive(:dispatch)

    described_class.new(account: account, user: user).perform

    expect(store.filters_ready?(account.id, user.id)).to be(true)
    expect(Rails.configuration.dispatcher).not_to have_received(:dispatch)
  end
end
