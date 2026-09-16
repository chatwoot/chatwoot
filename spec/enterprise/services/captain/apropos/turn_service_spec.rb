# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Captain::Apropos::TurnService do
  it 'passes the session and turn ids into the runtime trace context' do
    account = instance_double(Account)
    user = instance_double(User)
    session = instance_double(Captain::AproposSession, id: 22, account: account, user: user, state: {}, trace: [], reload: nil)
    runtime = instance_double(Captain::Apropos::Runtime)
    service = described_class.new(session)

    allow(service).to receive(:claim_turn) do
      service.instance_variable_set(:@turn_id, 'turn-9')
      true
    end
    allow(service).to receive(:run_agent).with(runtime).and_return('done')
    allow(service).to receive(:finish).with('ready', 'done', runtime)

    expect(Captain::Apropos::Runtime).to receive(:new).with(
      account: account,
      user: user,
      state: {},
      execution: { budget: { calls: 0, queries: 0 }, depth: 0, trace_context: { session_id: 22, turn_id: 'turn-9' } },
      on_event: be_a(Proc)
    ).and_return(runtime)

    service.perform
  end
end
