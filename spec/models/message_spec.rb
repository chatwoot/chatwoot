# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Message do
  it { is_expected.to belong_to(:account) }
  it { is_expected.to belong_to(:inbox) }
  it { is_expected.to belong_to(:conversation) }

  describe '#reportable?' do
    let!(:account) { create(:account) }
    let!(:user) { create(:user, account: account) }
    let!(:inbox) { create(:inbox, account: account) }
    let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }

    context 'when activity message' do
      it 'set reportable as false' do
        activity_mesage = create(:message, message_type: 'activity', account: account, inbox: inbox, conversation: conversation)
        expect(activity_mesage.reportable?).to eq(false)
      end
    end

    context 'when conversation message' do
      it 'set reportable as true' do
        conversation_message = create(:message, message_type: 'outgoing', account: account, inbox: inbox, conversation: conversation)
        expect(conversation_message.reportable?).to eq(true)
      end
    end
  end
end
