require 'rails_helper'

RSpec.describe AppliedSla, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:sla_policy) }
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:conversation) }
  end

  describe 'push_event_data' do
    it 'returns the correct hash' do
      applied_sla = create(:applied_sla)
      expect(applied_sla.push_event_data).to eq(
        {
          id: applied_sla.id,
          sla_id: applied_sla.sla_policy_id,
          sla_status: applied_sla.sla_status,
          created_at: applied_sla.created_at.to_i,
          updated_at: applied_sla.updated_at.to_i,
          sla_description: applied_sla.sla_policy.description,
          sla_name: applied_sla.sla_policy.name,
          sla_first_response_time_threshold: applied_sla.sla_policy.first_response_time_threshold,
          sla_next_response_time_threshold: applied_sla.sla_policy.next_response_time_threshold,
          sla_only_during_business_hours: applied_sla.sla_policy.only_during_business_hours,
          sla_resolution_time_threshold: applied_sla.sla_policy.resolution_time_threshold,
          sla_frt_due_at: applied_sla.frt_due_at,
          sla_nrt_due_at: applied_sla.nrt_due_at,
          sla_rt_due_at: applied_sla.rt_due_at
        }
      )
    end
  end

  describe 'validates_factory' do
    it 'creates valid applied sla policy object' do
      applied_sla = create(:applied_sla)
      expect(applied_sla.sla_status).to eq 'active'
    end
  end

  describe '#frt_due_at' do
    it 'returns nil when first_response_time_threshold is blank' do
      applied_sla = create(:applied_sla)
      applied_sla.sla_policy.update!(first_response_time_threshold: nil)

      expect(applied_sla.frt_due_at).to be_nil
    end

    it 'returns deadline based on conversation created_at' do
      applied_sla = create(:applied_sla)
      applied_sla.sla_policy.update!(first_response_time_threshold: 3600, only_during_business_hours: false)

      expected_deadline = applied_sla.conversation.created_at.to_i + 3600
      expect(applied_sla.frt_due_at).to eq(expected_deadline)
    end
  end

  describe '#nrt_due_at' do
    it 'returns nil when next_response_time_threshold is blank' do
      applied_sla = create(:applied_sla)
      applied_sla.sla_policy.update!(next_response_time_threshold: nil)

      expect(applied_sla.nrt_due_at).to be_nil
    end

    it 'returns nil when waiting_since is blank' do
      applied_sla = create(:applied_sla)
      applied_sla.sla_policy.update!(next_response_time_threshold: 1800)
      applied_sla.conversation.update!(waiting_since: nil)

      expect(applied_sla.nrt_due_at).to be_nil
    end

    it 'returns deadline based on waiting_since' do
      applied_sla = create(:applied_sla)
      waiting_since = 2.hours.ago
      applied_sla.sla_policy.update!(next_response_time_threshold: 1800, only_during_business_hours: false)
      applied_sla.conversation.update!(waiting_since: waiting_since)

      expected_deadline = waiting_since.to_i + 1800
      expect(applied_sla.nrt_due_at).to eq(expected_deadline)
    end
  end

  describe '#rt_due_at' do
    it 'returns nil when resolution_time_threshold is blank' do
      applied_sla = create(:applied_sla)
      applied_sla.sla_policy.update!(resolution_time_threshold: nil)

      expect(applied_sla.rt_due_at).to be_nil
    end

    it 'returns deadline based on conversation created_at' do
      applied_sla = create(:applied_sla)
      applied_sla.sla_policy.update!(resolution_time_threshold: 7200, only_during_business_hours: false)

      expected_deadline = applied_sla.conversation.created_at.to_i + 7200
      expect(applied_sla.rt_due_at).to eq(expected_deadline)
    end
  end

  describe '#calculate_due_at' do
    it 'uses BusinessHoursService when only_during_business_hours is true' do
      account = create(:account)
      inbox = create(:inbox, account: account, working_hours_enabled: true)
      sla_policy = create(:sla_policy, account: account, first_response_time_threshold: 3600, only_during_business_hours: true)
      conversation = create(:conversation, account: account, inbox: inbox)
      applied_sla = create(:applied_sla, sla_policy: sla_policy, conversation: conversation, account: account)

      expect(Sla::BusinessHoursService).to receive(:new).and_call_original
      applied_sla.frt_due_at
    end

    it 'does not use BusinessHoursService when only_during_business_hours is false' do
      applied_sla = create(:applied_sla)
      applied_sla.sla_policy.update!(first_response_time_threshold: 3600, only_during_business_hours: false)

      expect(Sla::BusinessHoursService).not_to receive(:new)
      applied_sla.frt_due_at
    end
  end
end
