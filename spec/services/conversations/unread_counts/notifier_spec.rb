require 'rails_helper'

RSpec.describe Conversations::UnreadCounts::Notifier do
  let!(:conversation) { create(:conversation) }
  let(:refresher) { instance_double(Conversations::UnreadCounts::Refresher, perform: refresh_result) }
  let(:refresh_result) { true }

  before do
    conversation.account.enable_features!(:conversation_unread_counts)
    allow(Conversations::UnreadCounts::Refresher).to receive(:new).and_return(refresher)
    allow(Rails.configuration.dispatcher).to receive(:dispatch)
  end

  it 'dispatches unread count changed event after a successful refresh' do
    described_class.new(conversation).perform

    expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(
      'conversation.unread_count_changed',
      kind_of(Time),
      conversation: conversation
    )
  end

  context 'when refresh does not change unread count memberships' do
    let(:refresh_result) { false }

    it 'does not dispatch unread count changed event' do
      described_class.new(conversation).perform

      expect(Rails.configuration.dispatcher).not_to have_received(:dispatch)
    end
  end

  context 'when conversation unread counts feature is disabled' do
    before do
      Conversations::UnreadCounts::Store.mark_base_ready!(conversation.account_id)
      Conversations::UnreadCounts::Store.mark_assignment_ready!(conversation.account_id)
      conversation.account.disable_features!(:conversation_unread_counts)
    end

    after do
      Conversations::UnreadCounts::Store.clear_account!(conversation.account_id)
    end

    it 'expires ready keys without refreshing or dispatching unread count changed event' do
      described_class.new(conversation).perform

      expect(Conversations::UnreadCounts::Refresher).not_to have_received(:new)
      expect(Conversations::UnreadCounts::Store.base_ready?(conversation.account_id)).to be(false)
      expect(Conversations::UnreadCounts::Store.assignment_ready?(conversation.account_id)).to be(false)
      expect(Rails.configuration.dispatcher).not_to have_received(:dispatch)
    end
  end
end
