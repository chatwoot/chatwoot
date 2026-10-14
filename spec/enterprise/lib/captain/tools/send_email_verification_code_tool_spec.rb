require 'rails_helper'

RSpec.describe Captain::Tools::SendEmailVerificationCodeTool, type: :model do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact_inbox) { create(:contact_inbox, inbox: inbox, contact: create(:contact, account: account)) }
  let(:tool) { described_class.new(assistant) }
  let(:tool_context) { Struct.new(:state).new({ contact_inbox: { id: contact_inbox.id } }) }
  let(:verification) { instance_double(Captain::EmailVerification) }

  before { allow(Captain::EmailVerification).to receive(:new).with(contact_inbox).and_return(verification) }

  it 'tells Captain the code was emailed and what to do next' do
    allow(verification).to receive(:send_code).with('Jane@Example.com').and_return(:sent)

    result = tool.perform(tool_context, email: 'Jane@Example.com')

    expect(result).to include('A 6-digit code was emailed to jane@example.com').and include('30 minutes')
  end

  it 'tells Captain not to retry when too many codes were sent' do
    allow(verification).to receive(:send_code).and_return(:rate_limited)

    expect(tool.perform(tool_context, email: 'jane@example.com')).to include('Too many codes were sent recently')
  end

  it 'tells Captain when the address is already verified' do
    allow(verification).to receive(:send_code).and_return(:already_verified)

    expect(tool.perform(tool_context, email: 'jane@example.com')).to include('already verified').and include('No code was sent')
  end

  it 'tells Captain to offer a support agent when email cannot be sent' do
    allow(verification).to receive(:send_code).and_return(:unavailable)

    result = tool.perform(tool_context, email: 'jane@example.com')

    expect(result).to include('Email verification is not available right now').and include('support agent')
  end

  it 'asks for a correct address when the email is invalid' do
    allow(verification).to receive(:send_code).and_return(:invalid_email)

    expect(tool.perform(tool_context, email: 'nope')).to include('not a valid email address')
  end

  it 'is not available without a contact inbox' do
    expect(tool.perform(Struct.new(:state).new({}), email: 'jane@example.com')).to eq('Email verification is not available in this conversation')
  end

  it 'does not use a contact inbox from another account' do
    other_contact_inbox = create(:contact_inbox)
    context = Struct.new(:state).new({ contact_inbox: { id: other_contact_inbox.id } })

    expect(tool.perform(context, email: 'jane@example.com')).to eq('Email verification is not available in this conversation')
  end
end
