require 'rails_helper'

RSpec.describe AutomationRules::TriggerPendingExecutionsJob do
  subject(:job) { described_class.new }

  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }

  before { GlobalConfig.clear_cache }

  it 'enqueues per-row jobs for due pending rows and claims them' do
    due_row = create(:automation_rule_pending_execution, account: account, conversation: conversation, due_at: 1.minute.ago)
    future_row = create(:automation_rule_pending_execution, account: account, due_at: 1.hour.from_now)

    expect { job.perform }.to have_enqueued_job(AutomationRules::ProcessPendingExecutionJob).exactly(:once).with(due_row)
    expect(due_row.reload).to be_processing
    expect(future_row.reload).to be_pending
  end

  it 'expires rows past the due window instead of enqueuing them' do
    overdue_row = create(:automation_rule_pending_execution, account: account, conversation: conversation, due_at: 4.days.ago)

    expect { job.perform }.not_to have_enqueued_job(AutomationRules::ProcessPendingExecutionJob)
    expect(overdue_row.reload).to be_skipped
    expect(overdue_row.skip_reason).to eq('expired')
  end

  it 'reclaims stale processing rows so the next sweep retries them' do
    stale_row = travel_to(20.minutes.ago) do
      create(:automation_rule_pending_execution, account: account, conversation: conversation, status: :processing, due_at: 19.minutes.from_now)
    end

    expect { job.perform }.to have_enqueued_job(AutomationRules::ProcessPendingExecutionJob).with(stale_row)
  end

  it 'caps enqueues at the configured sweep limit and leaves overflow pending' do
    create(:installation_config, name: 'AUTOMATION_PENDING_EXECUTIONS_SWEEP_LIMIT', serialized_value: { value: 1 }.with_indifferent_access)
    create_list(:automation_rule_pending_execution, 2, account: account, due_at: 1.minute.ago)

    expect { job.perform }.to have_enqueued_job(AutomationRules::ProcessPendingExecutionJob).exactly(:once)
    expect(AutomationRulePendingExecution.pending.count).to eq(1)
  end

  it 'does nothing when the kill switch is set' do
    create(:installation_config, name: 'DISABLE_DELAYED_AUTOMATIONS', serialized_value: { value: true }.with_indifferent_access)
    GlobalConfig.clear_cache
    due_row = create(:automation_rule_pending_execution, account: account, conversation: conversation, due_at: 1.minute.ago)

    expect { job.perform }.not_to have_enqueued_job(AutomationRules::ProcessPendingExecutionJob)
    expect(due_row.reload).to be_pending
  end
end
