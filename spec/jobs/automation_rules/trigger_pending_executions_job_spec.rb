require 'rails_helper'

RSpec.describe AutomationRules::TriggerPendingExecutionsJob do
  subject(:job) { described_class.new }

  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }

  before { account.enable_features!('delayed_automations') }

  it 'enqueues a per-row job for due pending rows but not future ones' do
    due_row = create(:automation_rule_pending_execution, account: account, conversation: conversation, due_at: 1.minute.ago)
    future_row = create(:automation_rule_pending_execution, account: account, due_at: 1.hour.from_now)

    expect { job.perform }.to have_enqueued_job(AutomationRules::ProcessPendingExecutionJob).exactly(:once)
    expect(AutomationRules::ProcessPendingExecutionJob).to have_been_enqueued.with(due_row)
    expect(AutomationRules::ProcessPendingExecutionJob).not_to have_been_enqueued.with(future_row)
  end

  it 're-enqueues stale processing rows so they get retried' do
    stale_row = travel_to(20.minutes.ago) do
      create(:automation_rule_pending_execution, account: account, conversation: conversation, status: :processing, due_at: 19.minutes.from_now)
    end

    expect { job.perform }.to have_enqueued_job(AutomationRules::ProcessPendingExecutionJob).with(stale_row)
  end

  it 'caps enqueues at the configured sweep limit' do
    create(:installation_config, name: 'AUTOMATION_PENDING_EXECUTIONS_SWEEP_LIMIT', serialized_value: { value: 1 }.with_indifferent_access)
    create_list(:automation_rule_pending_execution, 2, account: account, due_at: 1.minute.ago)

    expect { job.perform }.to have_enqueued_job(AutomationRules::ProcessPendingExecutionJob).exactly(:once)
  end

  # Nothing reclaims an `executing` row, so the sweep is the only thing that will ever look at a run
  # whose worker died holding activity it never read.
  it 'recovers an abandoned run that carries activity nobody read' do
    inactivity_rule = create(:automation_rule, account: account, event_name: 'conversation_updated',
                                               execution_delay: 60, execution_delay_trigger: 'inactivity')
    quiet, abandoned = travel_to(20.minutes.ago) do
      # last_activity_at defaults to the database clock, which travel_to does not move, so a quiet
      # conversation has to say when it went quiet.
      quiet = create(:conversation, account: account, last_activity_at: Time.current)
      [quiet, create(:automation_rule_pending_execution, account: account, conversation: quiet,
                                                         automation_rule: inactivity_rule, episode_key: 'inactivity',
                                                         status: :executing, due_at: 40.minutes.from_now)]
    end
    moved_at = 5.minutes.ago
    expect(quiet.reload.last_activity_at).to be < moved_at
    abandoned.record_activity(moved_at)

    job.perform

    expect(abandoned.reload).to be_pending
    expect(abandoned.due_at).to be_within(5.seconds).of(moved_at + 60.minutes)
  end

  it 'purges terminal rows past the retention window' do
    old_row = travel_to(31.days.ago) { create(:automation_rule_pending_execution, account: account, status: :executed) }

    job.perform

    expect { old_row.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'skips rows for accounts with delayed automations disabled so they cannot starve others' do
    enabled_row = create(:automation_rule_pending_execution, account: account, conversation: conversation, due_at: 1.minute.ago)
    disabled_account = create(:account) # delayed_automations off by default
    create(:automation_rule_pending_execution, account: disabled_account, due_at: 2.minutes.ago)

    expect { job.perform }.to have_enqueued_job(AutomationRules::ProcessPendingExecutionJob).exactly(:once)
    expect(AutomationRules::ProcessPendingExecutionJob).to have_been_enqueued.with(enabled_row)
  end
end
