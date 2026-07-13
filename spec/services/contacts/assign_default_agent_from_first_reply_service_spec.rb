require 'rails_helper'

RSpec.describe Contacts::AssignDefaultAgentFromFirstReplyService do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account, assigned_agent: nil) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact, assignee: agent) }
  let(:message) do
    create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :outgoing,
                     sender: agent, private: false)
  end

  it 'assigns the sending agent as contact owner without calling private Message APIs' do
    expect { described_class.new(message: message).perform }.not_to raise_error
    expect(contact.reload.assigned_agent_id).to eq(agent.id)
  end

  it 'does not overwrite an existing assigned agent' do
    other = create(:user, account: account, role: :agent)
    contact.update!(assigned_agent: other)

    described_class.new(message: message).perform
    expect(contact.reload.assigned_agent_id).to eq(other.id)
  end
end
