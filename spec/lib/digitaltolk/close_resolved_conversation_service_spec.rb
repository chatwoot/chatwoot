require 'rails_helper'

RSpec.describe Digitaltolk::CloseResolvedConversationService do
  let(:service) { described_class.new(account_id) }

  describe '#perform' do
    subject { service.perform }

    context 'when account is not present' do
      let(:account_id) { nil }

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when there are resolved email conversations' do
      let(:account) { create(:account) }
      let(:account_id) { account.id }
      let(:inbox) { create(:inbox, account: account, channel_type: channel_type) }
      let(:resolved_conversation) { create(:conversation, account: account, inbox: inbox) }

      before do
        create(:message, conversation: resolved_conversation)
        # rubocop:disable Rails/SkipsModelValidations
        resolved_conversation.update_columns(status: 'resolved', last_activity_at: last_activity_at)
        # rubocop:enable Rails/SkipsModelValidations
      end

      context 'when last activity is less than 7 days on chat conversation' do
        let(:channel_type) { 'Channel::Email' }
        let(:last_activity_at) { 6.days.ago }

        it 'does not close email conversations' do
          expect { subject }.not_to change { resolved_conversation.reload.closed }.from(false)
        end
      end

      context 'when last activity is more than 7 days on email conversation' do
        let(:channel_type) { 'Channel::Email' }
        let(:last_activity_at) { 8.days.ago }

        it 'closes email conversations' do
          expect { subject }.to change { resolved_conversation.reload.closed }.from(false).to(true)
        end
      end

      context 'when last activity is less than 1 days on chat conversation' do
        let(:channel_type) { 'Channel::WebWidget' }
        let(:last_activity_at) { 10.hours.ago }

        it 'does not close chat conversations' do
          expect { subject }.not_to change { resolved_conversation.reload.closed }.from(false)
        end
      end

      context 'when last activity is more than 1 days on chat conversation' do
        let(:channel_type) { 'Channel::WebWidget' }
        let(:last_activity_at) { 2.days.ago }

        it 'closes chat conversations' do
          expect { subject }.to change { resolved_conversation.reload.closed }.from(false).to(true)
        end
      end
    end
  end
end
