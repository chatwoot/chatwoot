# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voice::Conference::Manager do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_voice, account: account, phone_number: '+15551230011') }
  let(:conversation) do
    create(
      :conversation,
      account: account,
      inbox: channel.inbox,
      additional_attributes: { 'call_status' => call_status }
    )
  end
  let(:status_manager) { instance_double(Voice::CallStatus::Manager, process_status_update: true) }
  let(:webhook_service) { instance_double(Twilio::VoiceWebhookSetupService, perform: true) }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new).and_return(webhook_service)
    allow(Voice::CallStatus::Manager).to receive(:new).and_return(status_manager)
  end

  describe '#process' do
    context 'when an agent leaves an in-progress conference' do
      let(:call_status) { 'in-progress' }

      it 'does not mark the call as completed' do
        described_class.new(
          conversation: conversation,
          event: 'leave',
          call_sid: 'CA123',
          participant_label: 'agent'
        ).process

        expect(status_manager).not_to have_received(:process_status_update)
      end
    end

    context 'when a contact leaves an in-progress conference' do
      let(:call_status) { 'in-progress' }

      it 'marks the call as completed' do
        described_class.new(
          conversation: conversation,
          event: 'leave',
          call_sid: 'CA123',
          participant_label: 'contact'
        ).process

        expect(status_manager).to have_received(:process_status_update).with(
          'completed',
          timestamp: kind_of(Integer)
        )
      end
    end

    context 'when a contact leaves before an agent joins' do
      let(:call_status) { 'ringing' }

      it 'marks the call as no-answer' do
        described_class.new(
          conversation: conversation,
          event: 'leave',
          call_sid: 'CA123',
          participant_label: 'contact'
        ).process

        expect(status_manager).to have_received(:process_status_update).with(
          'no-answer',
          timestamp: kind_of(Integer)
        )
      end
    end
  end
end
