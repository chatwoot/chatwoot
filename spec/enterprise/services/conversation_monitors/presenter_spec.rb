require 'rails_helper'

RSpec.describe ConversationMonitors::Presenter do
  let(:monitor) { create(:conversation_monitor, created_at: 2.days.ago) }

  before do
    travel_to(Time.utc(2026, 9, 24, 12))
    allow(ConversationMonitors::Configuration).to receive(:configured?).and_return(true)
    monitor.initial_scan.update!(enumerated_at: 1.day.ago)
  end

  it 'does not show another monitor’s queued work after this monitor already matched the conversation' do
    conversation = create(:conversation, account: monitor.account)
    work = ConversationMonitors::WorkItem.for_conversation(conversation)
    work.request!(activity_at: Time.current)
    work.update!(requested_at: 3.minutes.ago)
    monitor.evaluations.create!(account: monitor.account, conversation: conversation, status: 'matched', input_revision: work.revision)

    expect(described_class.new(monitor).as_json.dig(:processing, :state)).to eq('live')
  end

  it 'shows delayed only when queued work is eligible for this monitor' do
    conversation = create(:conversation, account: monitor.account)
    work = ConversationMonitors::WorkItem.for_conversation(conversation)
    work.request!(activity_at: Time.current)
    work.update!(requested_at: 3.minutes.ago)

    expect(described_class.new(monitor).as_json.dig(:processing, :state)).to eq('delayed')
  end

  it 'does not require attention when a conversation has no public text' do
    conversation = create(:conversation, account: monitor.account)
    monitor.evaluations.create!(account: monitor.account, conversation: conversation, status: 'error', error_code: 'no_text')

    expect(described_class.new(monitor).as_json[:processing]).to eq(state: 'live', errors: 0, error_codes: [])
  end

  it 'still requires attention for actionable errors alongside conversations with no public text' do
    no_text_conversation = create(:conversation, account: monitor.account)
    failed_conversation = create(:conversation, account: monitor.account)
    monitor.evaluations.create!(account: monitor.account, conversation: no_text_conversation, status: 'error', error_code: 'no_text')
    monitor.evaluations.create!(account: monitor.account, conversation: failed_conversation, status: 'error', error_code: 'provider_busy')

    expect(described_class.new(monitor).as_json[:processing]).to eq(state: 'needs_attention', errors: 1, error_codes: ['provider_busy'])
  end
end
