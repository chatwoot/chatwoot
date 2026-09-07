require 'rails_helper'

RSpec.describe Sla::BackfillAppliedSlaCompletedAtService do
  let(:output) { StringIO.new }
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:applied_sla) do
    create(
      :applied_sla,
      account: account,
      conversation: conversation,
      sla_status: :missed,
      created_at: 3.days.ago,
      updated_at: 1.day.ago
    )
  end
  let!(:resolution_event) do
    create(
      :reporting_event,
      account: account,
      inbox: conversation.inbox,
      conversation: conversation,
      name: 'conversation_resolved',
      event_start_time: applied_sla.created_at,
      event_end_time: 2.days.ago
    )
  end

  it 'defaults to a dry run' do
    result = described_class.new(account_id: account.id, output: output).perform

    expect(result).to include(dry_run: true, eligible: 1, matched: 1, updated: 0, skipped: 0)
    expect(applied_sla.reload.completed_at).to be_nil
  end

  it 'backfills the latest reliable resolution without changing updated_at' do
    latest_resolution = create(
      :reporting_event,
      account: account,
      inbox: conversation.inbox,
      conversation: conversation,
      name: 'conversation_resolved',
      event_start_time: applied_sla.created_at,
      event_end_time: 36.hours.ago
    )
    original_updated_at = applied_sla.updated_at

    result = described_class.new(account_id: account.id, apply: true, output: output).perform

    expect(result).to include(dry_run: false, eligible: 1, matched: 1, updated: 1, skipped: 0)
    expect(applied_sla.reload.completed_at).to eq(latest_resolution.reload.event_end_time)
    expect(applied_sla.updated_at).to eq(original_updated_at)
  end

  it 'skips records without a reliable resolution event' do
    resolution_event.destroy!

    result = described_class.new(account_id: account.id, apply: true, output: output).perform

    expect(result).to include(eligible: 1, matched: 0, updated: 0, skipped: 1)
    expect(applied_sla.reload.completed_at).to be_nil
  end

  it 'is idempotent' do
    service = described_class.new(account_id: account.id, apply: true, output: output)

    service.perform
    result = service.perform

    expect(result).to include(eligible: 0, matched: 0, updated: 0, skipped: 0)
    expect(applied_sla.reload.completed_at).to eq(resolution_event.reload.event_end_time)
  end

  it 'requires exactly one account scope' do
    expect { described_class.new(output: output).perform }
      .to raise_error(ArgumentError, 'Provide exactly one of ACCOUNT_ID or ALL_ACCOUNTS=true')
    expect { described_class.new(account_id: account.id, all_accounts: true, output: output).perform }
      .to raise_error(ArgumentError, 'Provide exactly one of ACCOUNT_ID or ALL_ACCOUNTS=true')
  end

  it 'limits account runs and requires explicit global scope for other accounts' do
    other_account = create(:account)
    other_conversation = create(:conversation, account: other_account)
    other_applied_sla = create(
      :applied_sla,
      account: other_account,
      conversation: other_conversation,
      sla_status: :missed,
      created_at: 3.days.ago,
      updated_at: 1.day.ago
    )
    other_resolution_event = create(
      :reporting_event,
      account: other_account,
      inbox: other_conversation.inbox,
      conversation: other_conversation,
      name: 'conversation_resolved',
      event_start_time: other_applied_sla.created_at,
      event_end_time: 2.days.ago
    )

    described_class.new(account_id: account.id, apply: true, output: output).perform

    expect(applied_sla.reload.completed_at).to eq(resolution_event.reload.event_end_time)
    expect(other_applied_sla.reload.completed_at).to be_nil

    described_class.new(all_accounts: true, apply: true, output: output).perform

    expect(other_applied_sla.reload.completed_at).to eq(other_resolution_event.reload.event_end_time)
  end

  it 'resumes after the supplied applied SLA id' do
    result = described_class.new(account_id: account.id, after_id: applied_sla.id, output: output).perform

    expect(result).to include(eligible: 0, processed: 0, last_id: applied_sla.id)
  end
end
