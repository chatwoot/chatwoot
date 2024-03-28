require 'rails_helper'

# rails helper is using infer filetype to detect rspec type
# so we need to include type: :mailer to make this test work in enterprise namespace
RSpec.describe AgentNotifications::ConversationNotificationsMailer, type: :mailer do
  let(:class_instance) { described_class.new }
  let!(:account) { create(:account) }
  let(:agent) { create(:user, email: 'agent1@example.com', account: account) }
  let(:conversation) { create(:conversation, assignee: agent, account: account) }

  before do
    allow(described_class).to receive(:new).and_return(class_instance)
    allow(class_instance).to receive(:smtp_config_set_or_development?).and_return(true)
  end

  describe 'sla_missed_first_response' do
    let(:sla_policy) { create(:sla_policy, account: account) }
    let(:mail) { described_class.with(account: account).sla_missed_first_response(conversation, agent, sla_policy).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq("Conversation [ID - #{conversation.display_id}] missed SLA for first response")
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([agent.email])
    end
  end

  describe 'sla_missed_next_response' do
    let(:sla_policy) { create(:sla_policy, account: account) }
    let(:mail) { described_class.with(account: account).sla_missed_next_response(conversation, agent, sla_policy).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq("Conversation [ID - #{conversation.display_id}] missed SLA for next response")
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([agent.email])
    end
  end

  describe 'sla_missed_resolution' do
    let(:sla_policy) { create(:sla_policy, account: account) }
    let(:mail) { described_class.with(account: account).sla_missed_resolution(conversation, agent, sla_policy).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq("Conversation [ID - #{conversation.display_id}] missed SLA for resolution time")
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([agent.email])
    end
  end
end
