# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Conversations::EventDataPresenter do
  let!(:presenter) { described_class.new(conversation) }
  let!(:conversation) { create(:conversation) }
  let!(:applied_sla) { create(:applied_sla, conversation: conversation) }
  let!(:sla_event) { create(:sla_event, conversation: conversation, applied_sla: applied_sla) }

  describe '#push_data' do
    context 'when the caller is anonymous' do
      let(:channel) { create(:channel_twilio_sms, :with_voice) }
      let(:contact_inbox) do
        create(:contact_inbox, inbox: channel.inbox, source_id: "anonymous:CA#{SecureRandom.hex(16)}")
      end
      let(:conversation) do
        create(:conversation, account: channel.account, inbox: channel.inbox, contact: contact_inbox.contact, contact_inbox: contact_inbox)
      end

      [true, false].each do |sla_enabled|
        it "marks live events as anonymous and non-replyable with SLA enabled: #{sla_enabled}" do
          if sla_enabled
            conversation.account.enable_features!('sla')
          else
            conversation.account.disable_features!('sla')
          end

          expect(presenter.push_data).to include(anonymous_caller: true, can_reply: false)
        end
      end
    end

    it 'keeps normal conversations replyable in live events' do
      expect(presenter.push_data).to include(anonymous_caller: false, can_reply: true)
    end

    it 'returns push event payload with applied sla & sla events if the feature is enabled' do
      conversation.account.enable_features!('sla')

      expect(presenter.push_data).to include(
        {
          applied_sla: applied_sla.push_event_data,
          sla_events: [sla_event.push_event_data]
        }
      )
    end

    it 'returns push event payload without active sla data when contact is blocked' do
      conversation.account.enable_features!('sla')
      conversation.contact.update!(blocked: true)

      expect(presenter.push_data).to include(
        {
          applied_sla: nil,
          sla_events: [],
          sla_policy_id: nil
        }
      )
    end

    it 'returns push event payload without applied sla & sla events if the feature is disabled' do
      conversation.account.disable_features!('sla')

      expect(presenter.push_data).not_to include(:applied_sla, :sla_events)
    end
  end
end
