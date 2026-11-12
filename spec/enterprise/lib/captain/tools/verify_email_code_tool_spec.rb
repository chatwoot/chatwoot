require 'rails_helper'

RSpec.describe Captain::Tools::VerifyEmailCodeTool, type: :model do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:tool) { described_class.new(assistant) }
  let(:tool_context) { Struct.new(:state).new({ conversation: { id: conversation.id } }) }
  let(:verification) { instance_double(Captain::EmailVerification, verified_email: 'jane@example.com', attempts_left: 3, verified_ttl: 1.hour) }

  before { allow(Captain::EmailVerification).to receive(:new).with(conversation).and_return(verification) }

  it 'confirms the verified address and records it for the rest of the run' do
    allow(verification).to receive(:verify).with('482913').and_return(:verified)

    result = tool.perform(tool_context, code: '482913')

    expect(result).to start_with('Verified.').and include('jane@example.com').and include('This stays valid for 1 hour.')
    expect(tool_context.state[:verified_email]).to eq('jane@example.com')
  end

  it 'reports a wrong code with the attempts left' do
    allow(verification).to receive(:verify).and_return(:invalid_code)

    result = tool.perform(tool_context, code: '000000')

    expect(result).to include('That code is wrong. 3 attempts are left.')
    expect(tool_context.state).not_to have_key(:verified_email)
  end

  it 'reports when no attempts are left' do
    allow(verification).to receive_messages(verify: :invalid_code, attempts_left: 0)

    expect(tool.perform(tool_context, code: '000000')).to include('no attempts are left')
  end

  it 'reports a locked code' do
    allow(verification).to receive(:verify).and_return(:locked)

    expect(tool.perform(tool_context, code: '482913')).to include('Too many wrong codes were entered')
  end

  it 'reports when there is no active code' do
    allow(verification).to receive(:verify).and_return(:expired)

    expect(tool.perform(tool_context, code: '482913')).to include('There is no active code')
  end

  it 'is not available without a contact inbox' do
    expect(tool.perform(Struct.new(:state).new({}), code: '482913')).to eq('Email verification is not available in this conversation')
  end
end
