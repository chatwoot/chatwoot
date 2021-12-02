require 'rails_helper'
describe CampaignListener do
  let(:listener) { described_class.instance }
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account, identifier: '123') }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
  let(:conversation) { create(:conversation, contact_inbox: contact_inbox, inbox: inbox) }
  let(:automation_rule) { create(:automation_rule_staus_changes, account: account) }

  let!(:event) do
    Events::Base.new('conversation_status_changed', Time.zone.now, { conversation: conversation })
  end

  before do
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
                                        { 'action_name' => 'assign_best_agents', 'action_params' => [user.id] }
                                      ])
  end

  describe '#conversation_status_changed' do
    context 'when rule matches' do
      it 'triggers automation rule to assign team' do
        expect(conversation.team_id).not_to eq(team.id)
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

        expect(conversation.assignee).to eq(user)
      end
    end
  end
end
