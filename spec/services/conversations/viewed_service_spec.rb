require 'rails_helper'

RSpec.describe Conversations::ViewedService do
  let!(:account) { create(:account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let!(:user) { create(:user, account: account) }

  describe '#perform' do
    context 'when the throttle key can be claimed' do
      before do
        allow(Redis::Alfred).to receive(:set).and_return('OK')
      end

      it 'dispatches the conversation.viewed event' do
        expect(Rails.configuration.dispatcher).to receive(:dispatch).with(
          Events::Types::CONVERSATION_VIEWED,
          instance_of(ActiveSupport::TimeWithZone),
          conversation: conversation,
          viewed_by: user
        )

        described_class.new(conversation: conversation, user: user).perform
      end

      it 'claims the throttle key atomically' do
        allow(Rails.configuration.dispatcher).to receive(:dispatch)

        expect(Redis::Alfred).to receive(:set).with(
          "conversation_viewed/#{conversation.id}/#{user.id}", true, nx: true, ex: 60
        )

        described_class.new(conversation: conversation, user: user).perform
      end
    end

    context 'when the throttle key is already claimed' do
      before do
        allow(Redis::Alfred).to receive(:set).and_return(nil)
      end

      it 'does not dispatch the event' do
        expect(Rails.configuration.dispatcher).not_to receive(:dispatch)

        described_class.new(conversation: conversation, user: user).perform
      end
    end
  end
end
