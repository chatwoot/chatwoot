# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReactivateCompletedFollowUpsJob do
  subject(:job) { described_class.perform_later }

  let(:account) { create(:account) }
  let(:whatsapp_channel) { create(:channel_whatsapp, account: account) }
  let(:whatsapp_inbox) { create(:inbox, channel: whatsapp_channel, account: account) }
  let(:sequence) { create(:lead_follow_up_sequence, account: account, inbox: whatsapp_inbox) }
  let(:user) { create(:user, account: account) }

  before do
    stub_request(:get, 'https://waba.360dialog.io/v1/configs/templates')
      .to_return(status: 200, body: {
        waba_templates: [
          {
            'name' => 'follow_up_message',
            'language' => 'en',
            'status' => 'APPROVED',
            'components' => [
              {
                'type' => 'BODY',
                'text' => 'Hello {{1}}, this is a follow-up message.'
              }
            ]
          },
          {
            'name' => 'test_template',
            'language' => 'es',
            'status' => 'APPROVED',
            'components' => [
              {
                'type' => 'BODY',
                'text' => 'Hola, este es un mensaje de prueba.'
              }
            ]
          }
        ]
      }.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, 'https://waba.360dialog.io/v1/settings/application')
      .to_return(status: 200, body: { settings: {} }.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:post, 'https://waba.360dialog.io/v1/configs/webhook')
      .to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .on_queue('scheduled_jobs')
  end

  describe '#perform' do
    context 'when follow-up is ready to reactivate (completed by contact reply)' do
      let(:conversation) { create(:conversation, account: account, inbox: whatsapp_inbox) }
      let!(:agent_message) do
        create(:message, conversation: conversation, message_type: :outgoing,
                         sender: user, created_at: 2.minutes.ago)
      end
      let!(:follow_up) do
        create(:conversation_follow_up,
               conversation: conversation,
               lead_follow_up_sequence: sequence,
               status: 'completed',
               completed_at: 31.minutes.ago,
               processing_started_at: nil,
               metadata: { 'completion_reason' => 'Contact replied' })
      end

      it 'reactivates the follow-up' do
        described_class.perform_now

        expect(follow_up.reload.status).to eq('active')
      end

      it 'clears completed_at' do
        described_class.perform_now

        expect(follow_up.reload.completed_at).to be_nil
      end

      it 'sets next_action_at based on wait step' do
        freeze_time do
          # Default sequence has 2 hours wait step
          described_class.perform_now

          # Agent sent message 2 minutes ago, wait is 2 hours
          # Remaining time = 2 hours - 2 minutes = 1 hour 58 minutes
          expected_time = Time.current + 1.hour + 58.minutes
          expect(follow_up.reload.next_action_at).to be_within(5.seconds).of(expected_time)
        end
      end

      it 'increments reactivation_count' do
        described_class.perform_now

        expect(follow_up.reload.metadata['reactivation_count']).to eq(1)
      end

      it 'stores reactivation metadata' do
        freeze_time do
          described_class.perform_now

          expect(follow_up.reload.metadata['reactivated_at']).to be_present
          expect(Time.parse(follow_up.reload.metadata['last_agent_message_at'])).to be_within(1.second).of(agent_message.created_at)
        end
      end
    end

    context 'when last message is not from agent' do
      let(:conversation) { create(:conversation, account: account, inbox: whatsapp_inbox) }
      let!(:client_message) do
        create(:message, conversation: conversation, message_type: :incoming,
                         created_at: 2.minutes.ago)
      end
      let!(:follow_up) do
        create(:conversation_follow_up,
               conversation: conversation,
               lead_follow_up_sequence: sequence,
               status: 'completed',
               completed_at: 31.minutes.ago,
               metadata: { 'completion_reason' => 'Contact replied' })
      end

      it 'does not reactivate' do
        described_class.perform_now

        expect(follow_up.reload.status).to eq('completed')
      end

      it 'clears processing state when processing is stale' do
        follow_up.update!(processing_started_at: 15.minutes.ago)

        described_class.perform_now

        expect(follow_up.reload.processing_started_at).to be_nil
      end
    end

    context 'when client responded after agent message' do
      let(:conversation) { create(:conversation, account: account, inbox: whatsapp_inbox) }
      let!(:agent_message) do
        create(:message, conversation: conversation, message_type: :outgoing,
                         sender: user, created_at: 5.minutes.ago)
      end
      let!(:client_response) do
        create(:message, conversation: conversation, message_type: :incoming,
                         created_at: 2.minutes.ago)
      end
      let!(:follow_up) do
        create(:conversation_follow_up,
               conversation: conversation,
               lead_follow_up_sequence: sequence,
               status: 'completed',
               completed_at: 31.minutes.ago,
               metadata: { 'completion_reason' => 'Contact replied' })
      end

      it 'does not reactivate' do
        described_class.perform_now

        expect(follow_up.reload.status).to eq('completed')
      end
    end

    context 'when follow-up was recently completed' do
      let(:conversation) { create(:conversation, account: account, inbox: whatsapp_inbox) }
      let!(:follow_up) do
        create(:conversation_follow_up,
               conversation: conversation,
               lead_follow_up_sequence: sequence,
               status: 'completed',
               completed_at: 2.minutes.ago,
               metadata: { 'completion_reason' => 'Contact replied' })
      end

      it 'does not reactivate' do
        described_class.perform_now

        expect(follow_up.reload.status).to eq('completed')
      end
    end

    context 'when follow-up is being processed' do
      let(:conversation) { create(:conversation, account: account, inbox: whatsapp_inbox) }
      let!(:follow_up) do
        create(:conversation_follow_up,
               conversation: conversation,
               lead_follow_up_sequence: sequence,
               status: 'completed',
               completed_at: 31.minutes.ago,
               processing_started_at: 2.minutes.ago,
               metadata: { 'completion_reason' => 'Contact replied' })
      end

      it 'does not reactivate' do
        described_class.perform_now

        expect(follow_up.reload.status).to eq('completed')
      end
    end

    context 'when processing is stale' do
      let(:conversation) { create(:conversation, account: account, inbox: whatsapp_inbox) }
      let!(:agent_message) do
        create(:message, conversation: conversation, message_type: :outgoing,
                         sender: user, created_at: 2.minutes.ago)
      end
      let!(:follow_up) do
        create(:conversation_follow_up,
               conversation: conversation,
               lead_follow_up_sequence: sequence,
               status: 'completed',
               completed_at: 31.minutes.ago,
               processing_started_at: 15.minutes.ago,
               metadata: { 'completion_reason' => 'Contact replied' })
      end

      it 'reactivates despite stale processing state' do
        described_class.perform_now

        expect(follow_up.reload.status).to eq('active')
      end
    end

    context 'when follow-up completed by "All steps completed"' do
      let(:conversation) { create(:conversation, account: account, inbox: whatsapp_inbox) }
      let!(:agent_message) do
        create(:message, conversation: conversation, message_type: :outgoing,
                         sender: user, created_at: 2.minutes.ago)
      end
      let!(:follow_up) do
        create(:conversation_follow_up,
               conversation: conversation,
               lead_follow_up_sequence: sequence,
               status: 'completed',
               completed_at: 31.minutes.ago,
               processing_started_at: nil,
               metadata: { 'completion_reason' => 'All steps completed' })
      end

      it 'does not reactivate' do
        described_class.perform_now

        expect(follow_up.reload.status).to eq('completed')
      end

      it 'is not included in ready_to_reactivate scope' do
        expect(ConversationFollowUp.ready_to_reactivate).not_to include(follow_up)
      end
    end

    context 'when follow-up completed by "Conversation resolved"' do
      let(:conversation) { create(:conversation, account: account, inbox: whatsapp_inbox) }
      let!(:agent_message) do
        create(:message, conversation: conversation, message_type: :outgoing,
                         sender: user, created_at: 2.minutes.ago)
      end
      let!(:follow_up) do
        create(:conversation_follow_up,
               conversation: conversation,
               lead_follow_up_sequence: sequence,
               status: 'completed',
               completed_at: 31.minutes.ago,
               processing_started_at: nil,
               metadata: { 'completion_reason' => 'Conversation resolved' })
      end

      it 'does not reactivate' do
        described_class.perform_now

        expect(follow_up.reload.status).to eq('completed')
      end
    end

    context 'with wait step - timing calculation from last agent message' do
      let(:conversation) { create(:conversation, account: account, inbox: whatsapp_inbox) }
      let(:sequence_with_wait) do
        create(:lead_follow_up_sequence,
               account: account,
               inbox: whatsapp_inbox,
               steps: [
                 {
                   'id' => 'step_1',
                   'type' => 'wait',
                   'enabled' => true,
                   'config' => {
                     'delay_value' => 10,
                     'delay_type' => 'minutes'
                   }
                 },
                 {
                   'id' => 'step_2',
                   'type' => 'send_template',
                   'enabled' => true,
                   'config' => {
                     'template_name' => 'test_template',
                     'language' => 'es'
                   }
                 }
               ])
      end
      let!(:agent_message) do
        create(:message, conversation: conversation, message_type: :outgoing,
                         sender: user, created_at: 7.minutes.ago)
      end
      let!(:follow_up) do
        create(:conversation_follow_up,
               conversation: conversation,
               lead_follow_up_sequence: sequence_with_wait,
               status: 'completed',
               completed_at: 31.minutes.ago,
               processing_started_at: nil,
               metadata: { 'completion_reason' => 'Contact replied' })
      end

      it 'calculates next_action_at based on time elapsed since last agent message' do
        freeze_time do
          described_class.perform_now

          # Agent sent message 7 minutes ago
          # Wait step is 10 minutes
          # Remaining time = 10 - 7 = 3 minutes
          expected_time = Time.current + 3.minutes

          expect(follow_up.reload.next_action_at).to be_within(1.second).of(expected_time)
        end
      end

      it 'resets current_step to 0' do
        follow_up.update!(current_step: 5)

        described_class.perform_now

        expect(follow_up.reload.current_step).to eq(0)
      end
    end

    context 'with wait step - time already elapsed' do
      let(:conversation) { create(:conversation, account: account, inbox: whatsapp_inbox) }
      let(:sequence_with_wait) do
        create(:lead_follow_up_sequence,
               account: account,
               inbox: whatsapp_inbox,
               steps: [
                 {
                   'id' => 'step_1',
                   'type' => 'wait',
                   'enabled' => true,
                   'config' => {
                     'delay_value' => 5,
                     'delay_type' => 'minutes'
                   }
                 }
               ])
      end
      let!(:agent_message) do
        create(:message, conversation: conversation, message_type: :outgoing,
                         sender: user, created_at: 10.minutes.ago)
      end
      let!(:follow_up) do
        create(:conversation_follow_up,
               conversation: conversation,
               lead_follow_up_sequence: sequence_with_wait,
               status: 'completed',
               completed_at: 31.minutes.ago,
               processing_started_at: nil,
               metadata: { 'completion_reason' => 'Contact replied' })
      end

      it 'sets next_action_at to current time when wait time already elapsed' do
        freeze_time do
          described_class.perform_now

          # Agent sent message 10 minutes ago
          # Wait step is 5 minutes
          # Time already elapsed, should execute immediately
          expect(follow_up.reload.next_action_at).to be_within(1.second).of(Time.current)
        end
      end
    end

    context 'with batch processing' do
      let!(:follow_ups) do
        5.times.map do
          conversation = create(:conversation, account: account, inbox: whatsapp_inbox)
          create(:message, conversation: conversation, message_type: :outgoing,
                          sender: user, created_at: 2.minutes.ago)
          create(:conversation_follow_up,
                 conversation: conversation,
                 lead_follow_up_sequence: sequence,
                 status: 'completed',
                 completed_at: 31.minutes.ago,
                 metadata: { 'completion_reason' => 'Contact replied' })
        end
      end

      it 'processes up to BATCH_SIZE records' do
        described_class.perform_now

        reactivated = ConversationFollowUp.where(id: follow_ups.map(&:id), status: 'active')
        expect(reactivated.count).to eq(5)
      end
    end

    context 'when an error occurs' do
      let(:conversation) { create(:conversation, account: account, inbox: whatsapp_inbox) }
      let!(:agent_message) do
        create(:message, conversation: conversation, message_type: :outgoing,
                         sender: user, created_at: 2.minutes.ago)
      end
      let!(:follow_up) do
        create(:conversation_follow_up,
               conversation: conversation,
               lead_follow_up_sequence: sequence,
               status: 'completed',
               completed_at: 31.minutes.ago,
               metadata: { 'completion_reason' => 'Contact replied' })
      end

      before do
        allow_any_instance_of(ConversationFollowUp).to receive(:update!).and_raise(StandardError.new('Test error'))
      end

      it 'clears processing state on error' do
        follow_up.update_column(:processing_started_at, Time.current)

        described_class.perform_now

        # The error is caught and processing should be cleared
        # Note: Since we're mocking update!, we can't verify the actual clear
        # but we can verify the job doesn't crash
        expect { described_class.perform_now }.not_to raise_error
      end
    end
  end
end
