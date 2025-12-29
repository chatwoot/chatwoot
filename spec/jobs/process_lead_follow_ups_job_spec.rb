# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProcessLeadFollowUpsJob do
  subject(:job) { described_class.perform_later }

  let(:account) { create(:account) }
  let(:whatsapp_channel) { create(:channel_whatsapp, account: account) }
  let(:whatsapp_inbox) { create(:inbox, channel: whatsapp_channel, account: account) }
  let(:sequence) { create(:lead_follow_up_sequence, account: account, inbox: whatsapp_inbox) }
  let(:conversation) { create(:conversation, account: account, inbox: whatsapp_inbox) }

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .on_queue('scheduled_jobs')
  end

  describe '#perform' do
    context 'when there are pending follow-ups' do
      let!(:due_follow_up) do
        create(:conversation_follow_up,
               conversation: conversation,
               lead_follow_up_sequence: sequence,
               status: 'active',
               next_action_at: 1.hour.ago)
      end
      let!(:future_follow_up) do
        create(:conversation_follow_up,
               conversation: create(:conversation, account: account, inbox: whatsapp_inbox),
               lead_follow_up_sequence: sequence,
               status: 'active',
               next_action_at: 1.hour.from_now)
      end

      it 'processes only due follow-ups' do
        service = instance_double(LeadRetargeting::SendFollowUpService)
        allow(LeadRetargeting::SendFollowUpService).to receive(:new).with(due_follow_up).and_return(service)
        allow(service).to receive(:execute)

        described_class.perform_now

        expect(LeadRetargeting::SendFollowUpService).to have_received(:new).with(due_follow_up).once
        expect(service).to have_received(:execute).once
      end

      it 'does not process future follow-ups' do
        allow(LeadRetargeting::SendFollowUpService).to receive(:new)

        described_class.perform_now

        expect(LeadRetargeting::SendFollowUpService).not_to have_received(:new).with(future_follow_up)
      end
    end

    context 'when processing fails' do
      let!(:follow_up) do
        create(:conversation_follow_up,
               conversation: conversation,
               lead_follow_up_sequence: sequence,
               status: 'active',
               next_action_at: 1.hour.ago)
      end

      before do
        allow(LeadRetargeting::SendFollowUpService).to receive(:new).and_raise(StandardError.new('Test error'))
      end

      it 'increments retry count on failure' do
        expect do
          described_class.perform_now
        end.to change { follow_up.reload.retry_count }.from(0).to(1)
      end

      it 'marks as failed after 3 retries' do
        follow_up.update!(metadata: { 'retry_count' => 2 })

        described_class.perform_now

        expect(follow_up.reload.status).to eq('failed')
        expect(follow_up.metadata['failure_reason']).to include('Max retries exceeded')
      end

      it 'does not mark as failed before reaching max retries' do
        follow_up.update!(metadata: { 'retry_count' => 1 })

        described_class.perform_now

        expect(follow_up.reload.status).to eq('active')
      end
    end

    context 'when there are no pending follow-ups' do
      it 'does not call the service' do
        allow(LeadRetargeting::SendFollowUpService).to receive(:new)

        described_class.perform_now

        expect(LeadRetargeting::SendFollowUpService).not_to have_received(:new)
      end
    end

    context 'with batch processing' do
      let!(:follow_ups) do
        5.times.map do
          create(:conversation_follow_up,
                 conversation: create(:conversation, account: account, inbox: whatsapp_inbox),
                 lead_follow_up_sequence: sequence,
                 status: 'active',
                 next_action_at: 1.hour.ago)
        end
      end

      it 'processes all pending follow-ups' do
        services = follow_ups.map do |follow_up|
          service = instance_double(LeadRetargeting::SendFollowUpService)
          allow(LeadRetargeting::SendFollowUpService).to receive(:new).with(follow_up).and_return(service)
          allow(service).to receive(:execute)
          service
        end

        described_class.perform_now

        services.each do |service|
          expect(service).to have_received(:execute)
        end
      end
    end
  end
end
