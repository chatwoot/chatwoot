require 'rails_helper'

RSpec.describe Conversations::ViewedService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:user) { create(:user, account: account) }

  describe '#perform' do
    context 'when the conversation was not viewed within the throttle window' do
      before do
        allow(Rails.cache).to receive(:read).and_return(nil)
        allow(Rails.cache).to receive(:write)
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

      it 'stores the throttle key' do
        allow(Rails.configuration.dispatcher).to receive(:dispatch)

        expect(Rails.cache).to receive(:write).with(
          "conversation_viewed/#{conversation.id}/#{user.id}", true, expires_in: 60.seconds
        )

        described_class.new(conversation: conversation, user: user).perform
      end
    end

    context 'when the conversation was viewed within the throttle window' do
      before do
        allow(Rails.cache).to receive(:read).and_return(true)
      end

      it 'does not dispatch the event' do
        expect(Rails.configuration.dispatcher).not_to receive(:dispatch)

        described_class.new(conversation: conversation, user: user).perform
      end
    end
  end
end
