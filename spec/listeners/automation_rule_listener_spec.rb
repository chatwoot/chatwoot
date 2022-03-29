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
                                        { 'action_name' => 'send_webhook_event', 'action_params' => ['https://www.example.com'] },
                                        { 'action_name' => 'assign_best_agent', 'action_params' => [user_1.id] },
                                        { 'action_name' => 'send_email_transcript', 'action_params' => 'new_agent@example.com' },
                                        { 'action_name' => 'mute_conversation', 'action_params' => nil },
                                        { 'action_name' => 'change_status', 'action_params' => ['snoozed'] },
                                        { 'action_name' => 'send_message', 'action_params' => ['Send this message.'] }
                                      ])
  end

  describe '#conversation_status_changed' do
    context 'when rule matches' do
      it 'triggers automation rule send webhook events' do
        payload = conversation.webhook_data.merge(event: "automation_event: #{automation_rule.event_name}")

        automation_rule

        expect(TeamNotifications::AutomationNotificationMailer).to receive(:conversation_creation)

        expect(WebhookJob).to receive(:perform_later).with('https://www.example.com', payload).once

        listener.conversation_status_changed(event)
      end

      it 'triggers automation rule to assign team' do
        expect(conversation.team_id).not_to eq(team.id)

        automation_rule

        expect(TeamNotifications::AutomationNotificationMailer).to receive(:conversation_creation)

        listener.conversation_status_changed(event)

        conversation.reload
        expect(conversation.team_id).to eq(team.id)
      end

      it 'triggers automation rule to add label' do
        expect(conversation.labels).to eq([])

        automation_rule

        expect(TeamNotifications::AutomationNotificationMailer).to receive(:conversation_creation)

        listener.conversation_status_changed(event)

        conversation.reload
        expect(conversation.labels.pluck(:name)).to contain_exactly('support', 'priority_customer')
      end

      it 'triggers automation rule to assign best agents' do
        expect(conversation.assignee).to be_nil

        automation_rule

        expect(TeamNotifications::AutomationNotificationMailer).to receive(:conversation_creation)

        listener.conversation_status_changed(event)

        conversation.reload

        expect(conversation.assignee).to eq(user_1)
      end

      it 'triggers automation rule send message to the contacts' do
        expect(conversation.messages).to be_empty

        automation_rule

        expect(TeamNotifications::AutomationNotificationMailer).to receive(:conversation_creation)

        listener.conversation_status_changed(event)

        conversation.reload

        expect(conversation.messages.last.content).to eq('Send this message.')
      end

      it 'triggers automation rule changes status to snoozed' do
        expect(conversation.status).to eq('resolved')

        automation_rule

        expect(TeamNotifications::AutomationNotificationMailer).to receive(:conversation_creation)

        listener.conversation_status_changed(event)

        conversation.reload

        expect(conversation.status).to eq('snoozed')
      end

      it 'triggers automation rule send email transcript to the mentioned email' do
        mailer = double

        automation_rule

        expect(TeamNotifications::AutomationNotificationMailer).to receive(:conversation_creation)

        listener.conversation_status_changed(event)

        conversation.reload

        allow(mailer).to receive(:conversation_transcript)
      end

      it 'triggers automation rule send email to the team' do
        automation_rule

        expect(TeamNotifications::AutomationNotificationMailer).to receive(:conversation_creation)

        listener.conversation_status_changed(event)
      end
    end
  end

  describe '#conversation_updated' do
    before do
      automation_rule.update!(
        event_name: 'conversation_updated',
        name: 'Call actions conversation updated',
        description: 'Add labels, assign team after conversation updated'
      )
    end

    let!(:event) do
      Events::Base.new('conversation_updated', Time.zone.now, { conversation: conversation })
    end

    context 'when rule matches' do
      it 'triggers automation rule to assign team' do
        expect(conversation.team_id).not_to eq(team.id)

        automation_rule
        listener.conversation_updated(event)

        conversation.reload
        expect(conversation.team_id).to eq(team.id)
      end

      it 'triggers automation rule to add label' do
        expect(conversation.labels).to eq([])

        automation_rule
        listener.conversation_updated(event)

        conversation.reload
        expect(conversation.labels.pluck(:name)).to contain_exactly('support', 'priority_customer')
      end

      it 'triggers automation rule to assign best agents' do
        expect(conversation.assignee).to be_nil

        automation_rule
        listener.conversation_updated(event)

        conversation.reload

        expect(conversation.assignee).to eq(user_1)
      end

      it 'triggers automation rule send email transcript to the mentioned email' do
        mailer = double

        automation_rule

        expect(TeamNotifications::AutomationNotificationMailer).to receive(:conversation_updated)

        listener.conversation_updated(event)

        conversation.reload

        allow(mailer).to receive(:conversation_transcript)
      end

      it 'triggers automation rule send email to the team' do
        automation_rule

        expect(TeamNotifications::AutomationNotificationMailer).to receive(:conversation_updated)

        listener.conversation_updated(event)
      end

      it 'triggers automation rule send message to the contacts' do
        expect(conversation.messages).to be_empty

        automation_rule

        expect(TeamNotifications::AutomationNotificationMailer).to receive(:conversation_updated)

        listener.conversation_updated(event)

        conversation.reload

        expect(conversation.messages.last.content).to eq('Send this message.')
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

        expect(TeamNotifications::AutomationNotificationMailer).to receive(:message_created)

        listener.message_created(event)

        conversation.reload
        expect(conversation.team_id).to eq(team.id)
      end

      it 'triggers automation rule to add label' do
        expect(conversation.labels).to eq([])

        automation_rule

        expect(TeamNotifications::AutomationNotificationMailer).to receive(:message_created)

        listener.message_created(event)

        conversation.reload
        expect(conversation.labels.pluck(:name)).to contain_exactly('support', 'priority_customer')
      end

      it 'triggers automation rule to assign best agent' do
        expect(conversation.assignee).to be_nil
        automation_rule

        expect(TeamNotifications::AutomationNotificationMailer).to receive(:message_created)

        listener.message_created(event)

        conversation.reload

        expect(conversation.assignee).to eq(user_1)
      end

      it 'triggers automation rule send email transcript to the mentioned email' do
        mailer = double

        automation_rule

        expect(TeamNotifications::AutomationNotificationMailer).to receive(:message_created)

        listener.message_created(event)

        conversation.reload

        allow(mailer).to receive(:conversation_transcript)
      end
    end
  end
end
