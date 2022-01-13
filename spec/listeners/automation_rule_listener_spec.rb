require 'rails_helper'
describe AutomationRuleListener do
  let(:listener) { described_class.instance }
  let!(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account, identifier: '123') }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
  let(:conversation) { create(:conversation, contact_inbox: contact_inbox, inbox: inbox, account: account) }
  let(:automation_rule) { create(:automation_rule, account: account, name: 'Test Automation Rule') }
  let(:team) { create(:team, account: account) }
  let(:user_1) { create(:user, role: 0) }
  let(:user_2) { create(:user, role: 0) }
  let!(:event) do
    Events::Base.new('conversation_status_changed', Time.zone.now, { conversation: conversation })
  end

  before do
    create(:team_member, user: user_1, team: team)
    create(:team_member, user: user_2, team: team)
    create(:account_user, user: user_2, account: account)
    create(:account_user, user: user_1, account: account)

    conversation.resolved!
    automation_rule.update!(actions:
                                      [
                                        {
                                          'action_name' => 'send_email_to_team', 'action_params' => {
                                            'message' => 'Please pay attention to this conversation, its from high priority customer',
                                            'team_ids' => [team.id]
                                          }
                                        },
                                        { 'action_name' => 'assign_team', 'action_params' => [team.id] },
                                        { 'action_name' => 'add_label', 'action_params' => %w[support priority_customer] },
                                        { 'action_name' => 'assign_best_agents', 'action_params' => [user_1.id] }
                                      ])
  end

  describe '#conversation_status_changed' do
    context 'when rule matches' do
      it 'triggers automation rule to assign team' do
        expect(conversation.team_id).not_to eq(team.id)

        automation_rule
        listener.conversation_status_changed(event)

        conversation.reload
        expect(conversation.team_id).to eq(team.id)
      end

      it 'triggers automation rule to add label' do
        expect(conversation.labels).to eq([])

        automation_rule
        listener.conversation_status_changed(event)

        conversation.reload
        expect(conversation.labels.pluck(:name)).to eq(%w[support priority_customer])
      end

      it 'triggers automation rule to assign best agents' do
        expect(conversation.assignee).to be_nil

        automation_rule
        listener.conversation_status_changed(event)

        conversation.reload

        expect(conversation.assignee).to eq(user_1)
      end
    end
  end

  describe '#message_created' do
    before do
      automation_rule.update!(
        event_name: 'message_created',
        name: 'Call actions message created',
        description: 'Add labels, assign team after message created',
        conditions: [{ 'values': ['incoming'], 'attribute_key': 'message_type', 'query_operator': nil, 'filter_operator': 'equal_to' }]
      )
    end

    let!(:message) { create(:message, account: account, conversation: conversation, message_type: 'incoming') }
    let!(:event) do
      Events::Base.new('message_created', Time.zone.now, { conversation: conversation, message: message })
    end

    context 'when rule matches' do
      it 'triggers automation rule to assign team' do
        expect(conversation.team_id).not_to eq(team.id)

        automation_rule
        listener.message_created(event)

        conversation.reload
        expect(conversation.team_id).to eq(team.id)
      end

      it 'triggers automation rule to add label' do
        expect(conversation.labels).to eq([])

        automation_rule
        listener.message_created(event)

        conversation.reload
        expect(conversation.labels.pluck(:name)).to eq(%w[support priority_customer])
      end

      it 'triggers automation rule to assign best agents' do
        expect(conversation.assignee).to be_nil

        automation_rule
        listener.message_created(event)

        conversation.reload

        expect(conversation.assignee).to eq(user_1)
      end
    end
  end
end
