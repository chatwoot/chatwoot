# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ConversationFollowUp do
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
          }
        ]
      }.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, 'https://waba.360dialog.io/v1/settings/application')
      .to_return(status: 200, body: { settings: {} }.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:post, 'https://waba.360dialog.io/v1/configs/webhook')
      .to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  describe 'associations' do
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to belong_to(:lead_follow_up_sequence) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_uniqueness_of(:conversation_id) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[active paused completed cancelled failed]) }
  end

  describe 'scopes' do
    let(:account) { create(:account) }
    let(:whatsapp_channel) { create(:channel_whatsapp, account: account) }
    let(:whatsapp_inbox) { create(:inbox, channel: whatsapp_channel, account: account) }
    let(:conversation) { create(:conversation, account: account, inbox: whatsapp_inbox) }
    let(:sequence) { create(:lead_follow_up_sequence, account: account, inbox: whatsapp_inbox) }

    describe '.active' do
      let!(:active_follow_up) { create(:conversation_follow_up, conversation: conversation, lead_follow_up_sequence: sequence, status: 'active') }
      let!(:completed_follow_up) do
        create(:conversation_follow_up,
               conversation: create(:conversation, account: account, inbox: whatsapp_inbox),
               lead_follow_up_sequence: sequence, status: 'completed')
      end

      it 'returns only active follow-ups' do
        expect(described_class.active).to include(active_follow_up)
        expect(described_class.active).not_to include(completed_follow_up)
      end
    end

    describe '.pending_execution' do
      let!(:due_follow_up) do
        create(:conversation_follow_up, conversation: conversation, lead_follow_up_sequence: sequence,
                                        status: 'active', next_action_at: 1.hour.ago)
      end
      let!(:future_follow_up) do
        create(:conversation_follow_up,
               conversation: create(:conversation, account: account, inbox: whatsapp_inbox),
               lead_follow_up_sequence: sequence, status: 'active', next_action_at: 1.hour.from_now)
      end

      it 'returns only follow-ups that are due' do
        expect(described_class.pending_execution).to include(due_follow_up)
        expect(described_class.pending_execution).not_to include(future_follow_up)
      end
    end

    describe '.ready_to_reactivate' do
      let!(:old_completed_by_contact_reply) do
        create(:conversation_follow_up, conversation: conversation, lead_follow_up_sequence: sequence,
                                        status: 'completed', completed_at: 31.minutes.ago, processing_started_at: nil,
                                        metadata: { 'completion_reason' => 'Contact replied' })
      end
      let!(:recent_completed_follow_up) do
        create(:conversation_follow_up,
               conversation: create(:conversation, account: account, inbox: whatsapp_inbox),
               lead_follow_up_sequence: sequence, status: 'completed', completed_at: 4.minutes.ago,
               processing_started_at: nil,
               metadata: { 'completion_reason' => 'Contact replied' })
      end
      let!(:processing_completed_follow_up) do
        create(:conversation_follow_up,
               conversation: create(:conversation, account: account, inbox: whatsapp_inbox),
               lead_follow_up_sequence: sequence, status: 'completed', completed_at: 31.minutes.ago,
               processing_started_at: 5.minutes.ago,
               metadata: { 'completion_reason' => 'Contact replied' })
      end
      let!(:stale_processing_follow_up) do
        create(:conversation_follow_up,
               conversation: create(:conversation, account: account, inbox: whatsapp_inbox),
               lead_follow_up_sequence: sequence, status: 'completed', completed_at: 31.minutes.ago,
               processing_started_at: 15.minutes.ago,
               metadata: { 'completion_reason' => 'Contact replied' })
      end
      let!(:completed_all_steps) do
        create(:conversation_follow_up,
               conversation: create(:conversation, account: account, inbox: whatsapp_inbox),
               lead_follow_up_sequence: sequence, status: 'completed', completed_at: 31.minutes.ago,
               processing_started_at: nil,
               metadata: { 'completion_reason' => 'All steps completed' })
      end
      let!(:completed_by_resolved) do
        create(:conversation_follow_up,
               conversation: create(:conversation, account: account, inbox: whatsapp_inbox),
               lead_follow_up_sequence: sequence, status: 'completed', completed_at: 31.minutes.ago,
               processing_started_at: nil,
               metadata: { 'completion_reason' => 'Conversation resolved' })
      end

      it 'returns completed follow-ups older than REACTIVATION_DELAY by contact reply' do
        expect(described_class.ready_to_reactivate).to include(old_completed_by_contact_reply)
      end

      it 'does not include recent completed follow-ups' do
        expect(described_class.ready_to_reactivate).not_to include(recent_completed_follow_up)
      end

      it 'does not include currently processing follow-ups' do
        expect(described_class.ready_to_reactivate).not_to include(processing_completed_follow_up)
      end

      it 'includes follow-ups with stale processing state' do
        expect(described_class.ready_to_reactivate).to include(stale_processing_follow_up)
      end

      it 'does not include follow-ups completed by "All steps completed"' do
        expect(described_class.ready_to_reactivate).not_to include(completed_all_steps)
      end

      it 'does not include follow-ups completed by "Conversation resolved"' do
        expect(described_class.ready_to_reactivate).not_to include(completed_by_resolved)
      end

      it 'only includes follow-ups with completion_reason "Contact replied"' do
        ready_reasons = described_class.ready_to_reactivate.pluck(:metadata).map { |m| m['completion_reason'] }.uniq
        expect(ready_reasons).to eq(['Contact replied'])
      end
    end
  end

  describe '#mark_as_completed!' do
    let(:follow_up) { create(:conversation_follow_up) }

    it 'sets status to completed' do
      follow_up.mark_as_completed!('Test reason')
      expect(follow_up.reload.status).to eq('completed')
    end

    it 'stores completion reason in metadata' do
      follow_up.mark_as_completed!('Contact replied')
      expect(follow_up.reload.metadata['completion_reason']).to eq('Contact replied')
    end

    it 'stores completed_at timestamp' do
      freeze_time do
        follow_up.mark_as_completed!('Test')
        expect(Time.parse(follow_up.reload.metadata['completed_at'])).to be_within(1.second).of(Time.current)
      end
    end
  end

  describe '#mark_as_cancelled!' do
    let(:follow_up) { create(:conversation_follow_up) }

    it 'sets status to cancelled' do
      follow_up.mark_as_cancelled!('Sequence deactivated')
      expect(follow_up.reload.status).to eq('cancelled')
    end

    it 'stores cancellation reason in metadata' do
      follow_up.mark_as_cancelled!('Sequence deactivated')
      expect(follow_up.reload.metadata['cancellation_reason']).to eq('Sequence deactivated')
    end

    it 'stores cancelled_at timestamp' do
      freeze_time do
        follow_up.mark_as_cancelled!('Test')
        expect(Time.parse(follow_up.reload.metadata['cancelled_at'])).to be_within(1.second).of(Time.current)
      end
    end
  end

  describe '#mark_as_failed!' do
    let(:follow_up) { create(:conversation_follow_up) }

    it 'sets status to failed' do
      follow_up.mark_as_failed!('Template not found')
      expect(follow_up.reload.status).to eq('failed')
    end

    it 'stores failure reason in metadata' do
      follow_up.mark_as_failed!('Template not found')
      expect(follow_up.reload.metadata['failure_reason']).to eq('Template not found')
    end

    it 'stores failed_at timestamp' do
      freeze_time do
        follow_up.mark_as_failed!('Error')
        expect(Time.parse(follow_up.reload.metadata['failed_at'])).to be_within(1.second).of(Time.current)
      end
    end
  end

  describe '#pause!' do
    let(:follow_up) { create(:conversation_follow_up, status: 'active') }

    it 'sets status to paused' do
      follow_up.pause!
      expect(follow_up.reload.status).to eq('paused')
    end
  end

  describe '#resume!' do
    let(:follow_up) { create(:conversation_follow_up, status: 'paused') }

    it 'sets status to active' do
      follow_up.resume!
      expect(follow_up.reload.status).to eq('active')
    end
  end

  describe '#increment_retry_count!' do
    let(:follow_up) { create(:conversation_follow_up) }

    context 'when retry_count does not exist' do
      it 'initializes retry_count to 1' do
        follow_up.increment_retry_count!
        expect(follow_up.reload.metadata['retry_count']).to eq(1)
      end
    end

    context 'when retry_count exists' do
      before do
        follow_up.update!(metadata: { 'retry_count' => 2 })
      end

      it 'increments retry_count' do
        follow_up.increment_retry_count!
        expect(follow_up.reload.metadata['retry_count']).to eq(3)
      end
    end
  end

  describe '#retry_count' do
    let(:follow_up) { create(:conversation_follow_up) }

    context 'when retry_count does not exist' do
      it 'returns 0' do
        expect(follow_up.retry_count).to eq(0)
      end
    end

    context 'when retry_count exists' do
      before do
        follow_up.update!(metadata: { 'retry_count' => 3 })
      end

      it 'returns the current retry count' do
        expect(follow_up.retry_count).to eq(3)
      end
    end
  end

  describe '#mark_processing!' do
    let(:follow_up) { create(:conversation_follow_up) }

    it 'sets processing_started_at to current time' do
      freeze_time do
        follow_up.mark_processing!
        expect(follow_up.reload.processing_started_at).to be_within(1.second).of(Time.current)
      end
    end
  end

  describe '#clear_processing!' do
    let(:follow_up) { create(:conversation_follow_up, :processing) }

    it 'clears processing_started_at' do
      follow_up.clear_processing!
      expect(follow_up.reload.processing_started_at).to be_nil
    end
  end

  describe '#schedule_job!' do
    let(:follow_up) { create(:conversation_follow_up, next_action_at: 10.minutes.from_now) }

    context 'when next_action_at is in the future' do
      it 'schedules a job for the future time' do
        expect {
          follow_up.schedule_job!
        }.to have_enqueued_job(ProcessSingleFollowUpJob)
          .with(follow_up.id)
          .at(follow_up.next_action_at)
      end

      it 'stores the sidekiq_job_id' do
        follow_up.schedule_job!
        expect(follow_up.reload.sidekiq_job_id).to be_present
      end
    end

    context 'when next_action_at is in the past or current time' do
      before do
        follow_up.update_column(:next_action_at, 1.minute.ago)
      end

      it 'enqueues the job immediately' do
        expect {
          follow_up.schedule_job!
        }.to have_enqueued_job(ProcessSingleFollowUpJob)
          .with(follow_up.id)
      end
    end

    context 'when next_action_at is exactly Time.current' do
      before do
        freeze_time
        follow_up.update_column(:next_action_at, Time.current)
      end

      it 'enqueues the job immediately' do
        expect {
          follow_up.schedule_job!
        }.to have_enqueued_job(ProcessSingleFollowUpJob)
          .with(follow_up.id)
      end
    end

    context 'when called with custom execute_at parameter' do
      let(:custom_time) { 1.hour.from_now }

      it 'uses the provided time instead of next_action_at' do
        expect {
          follow_up.schedule_job!(custom_time)
        }.to have_enqueued_job(ProcessSingleFollowUpJob)
          .with(follow_up.id)
          .at(custom_time)
      end
    end

    context 'when there is an existing scheduled job' do
      before do
        follow_up.schedule_job!
      end

      it 'cancels the old job before scheduling new one' do
        old_job_id = follow_up.reload.sidekiq_job_id

        follow_up.update_column(:next_action_at, 2.hours.from_now)
        follow_up.schedule_job!

        new_job_id = follow_up.reload.sidekiq_job_id
        expect(new_job_id).not_to eq(old_job_id)
      end
    end
  end

  describe '#cancel_job!' do
    let(:follow_up) { create(:conversation_follow_up, next_action_at: 10.minutes.from_now) }

    context 'when there is a scheduled job' do
      before do
        follow_up.schedule_job!
      end

      it 'clears the sidekiq_job_id' do
        follow_up.cancel_job!
        expect(follow_up.reload.sidekiq_job_id).to be_nil
      end

      it 'removes the job from Sidekiq scheduled set' do
        job_id = follow_up.reload.sidekiq_job_id
        follow_up.cancel_job!

        scheduled_set = Sidekiq::ScheduledSet.new
        expect(scheduled_set.find_job(job_id)).to be_nil
      end
    end

    context 'when there is no scheduled job' do
      it 'does not raise error' do
        expect { follow_up.cancel_job! }.not_to raise_error
      end
    end

    context 'when sidekiq_job_id is nil' do
      before do
        follow_up.update_column(:sidekiq_job_id, nil)
      end

      it 'does not raise error' do
        expect { follow_up.cancel_job! }.not_to raise_error
      end
    end
  end
end
