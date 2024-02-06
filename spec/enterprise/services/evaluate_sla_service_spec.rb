require 'rails_helper'

RSpec.describe EvaluateSlaService do
  context 'when EvaluateSlaService is performed' do
    let!(:conversation) { create(:conversation, created_at: 2.hours.ago) }
    let!(:sla_policy) { create(:sla_policy, first_response_time_threshold: 1.hour) }
    let!(:applied_sla) { create(:applied_sla, conversation: conversation, sla_policy: sla_policy, sla_status: 'active') }

    it 'logs a warning if the first_reponse SLA is missed' do
      allow(Rails.logger).to receive(:warn)
      described_class.new(applied_sla: applied_sla).perform
      expected_log_message = "SLA missed for conversation #{conversation.id} in account #{conversation.account_id} for sla_policy #{sla_policy.id}"
      expect(Rails.logger).to have_received(:warn).with(expected_log_message)
      expect(applied_sla.reload.sla_status).to eq('missed')
    end
  end

  context 'when EvaluateSlaService is performed with a conversation having first reply' do
    let!(:conversation) { create(:conversation, created_at: 4.hours.ago, first_reply_created_at: 3.hours.ago, waiting_since: 2.hours.ago) }
    let!(:sla_policy) { create(:sla_policy, first_response_time_threshold: 30.minutes.ago, next_response_time_threshold: 1.hour) }
    let!(:applied_sla) { create(:applied_sla, conversation: conversation, sla_policy: sla_policy, sla_status: 'active') }

    it 'logs a warning if the next_repsonse SLA is missed' do
      allow(Rails.logger).to receive(:warn)
      described_class.new(applied_sla: applied_sla).perform
      expected_log_message = "SLA missed for conversation #{conversation.id} in account #{conversation.account_id} for sla_policy #{sla_policy.id}"
      expect(Rails.logger).to have_received(:warn).with(expected_log_message)
      expect(applied_sla.reload.sla_status).to eq('missed')
    end
  end

  context 'when EvaluateSlaService is performed with conversation that is resolved' do
    let!(:conversation) { create(:conversation, created_at: 6.hours.ago, updated_at: 3.hours.ago) }
    let!(:sla_policy) { create(:sla_policy, resolution_time_threshold: 1.hour) }
    let!(:applied_sla) { create(:applied_sla, conversation: conversation, sla_policy: sla_policy, sla_status: 'active') }

    it 'logs a warning if response_time SLA is missed' do
      allow(Rails.logger).to receive(:warn)
      conversation.toggle_status
      time_to_resolve = conversation.updated_at.to_i - conversation.created_at.to_i

      reporting_event = ReportingEvent.new(
        name: 'conversation_resolved',
        value: time_to_resolve,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        user_id: conversation.assignee_id,
        conversation_id: conversation.id,
        event_start_time: conversation.created_at,
        event_end_time: conversation.updated_at
      )
      reporting_event.save!

      described_class.new(applied_sla: applied_sla).perform
      expected_log_message = "SLA missed for conversation #{conversation.id} in account #{conversation.account_id} for sla_policy #{sla_policy.id}"
      expect(Rails.logger).to have_received(:warn).with(expected_log_message)
      expect(applied_sla.reload.sla_status).to eq('missed')
    end
  end

  context 'when EvaluateSlaService is performed with conversation that is resolve' do
    let!(:conversation) { create(:conversation, created_at: 6.hours.ago, updated_at: 3.hours.ago) }
    let!(:sla_policy) { create(:sla_policy, resolution_time_threshold: 24.hours) }
    let!(:applied_sla) { create(:applied_sla, conversation: conversation, sla_policy: sla_policy, sla_status: 'active') }

    it 'logs success if response_time SLA is hit' do
      allow(Rails.logger).to receive(:info)
      conversation.toggle_status
      time_to_resolve = conversation.updated_at.to_i - conversation.created_at.to_i

      reporting_event = ReportingEvent.new(
        name: 'conversation_resolved',
        value: time_to_resolve,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        user_id: conversation.assignee_id,
        conversation_id: conversation.id,
        event_start_time: conversation.created_at,
        event_end_time: conversation.updated_at
      )
      reporting_event.save!

      described_class.new(applied_sla: applied_sla).perform
      expected_log_message = "SLA hit for conversation #{conversation.id} in account #{conversation.account_id} for sla_policy #{sla_policy.id}"
      expect(Rails.logger).to have_received(:info).with(expected_log_message)
      expect(applied_sla.reload.sla_status).to eq('hit')
    end
  end
end
