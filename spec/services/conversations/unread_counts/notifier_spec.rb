require 'rails_helper'

RSpec.describe Conversations::UnreadCounts::Notifier do
  let!(:conversation) { create(:conversation) }
  let(:refresher) { instance_double(Conversations::UnreadCounts::Refresher, perform: refresh_result) }
  let(:refresh_result) { true }

  before do
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

  context 'when cache is not ready' do
    let(:refresh_result) { false }

    it 'does not dispatch unread count changed event' do
      described_class.new(conversation).perform

      expect(Rails.configuration.dispatcher).not_to have_received(:dispatch)
    end
  end
end
