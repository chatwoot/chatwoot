require 'rails_helper'

describe Conversations::AssignmentService do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account) }
  let(:agent_bot) { create(:agent_bot, account: account) }
  let(:conversation) { create(:conversation, account: account) }

  describe '#perform' do
    context 'when assignee_id is blank and inbox has an active bot' do
      before do
        inbox = conversation.inbox
        create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
        conversation.update!(assignee: agent, assignee_agent_bot: nil)
      end

      it 'clears the human and assigns the inbox bot' do
        described_class.new(conversation: conversation, assignee_id: nil).perform

        conversation.reload
        expect(conversation.assignee_id).to be_nil
        expect(conversation.assignee_agent_bot_id).to eq(agent_bot.id)
      end
    end

    context 'when assignee_id is blank and inbox has no bot' do
      before do
        conversation.update!(assignee: agent, assignee_agent_bot: agent_bot)
      end

      it 'clears both human and bot assignees' do
        described_class.new(conversation: conversation, assignee_id: nil).perform

        conversation.reload
        expect(conversation.assignee_id).to be_nil
        expect(conversation.assignee_agent_bot_id).to be_nil
      end

      it 'preserves conversation status' do
        conversation.update!(status: :snoozed, snoozed_until: 1.day.from_now)

        described_class.new(conversation: conversation, assignee_id: nil).perform

        expect(conversation.reload.status).to eq('snoozed')
      end
    end

    context 'when assigning a user' do
      before do
        conversation.update!(
          assignee_agent_bot: agent_bot,
          assignee: nil,
          status: :pending,
          custom_attributes: {
            'panel_ia_estado' => 'solicita_ayuda',
            'panel_ia_estado_label' => 'Needs help',
            'panel_ia_updated_at' => Time.current.iso8601,
            'other_attr' => 'keep'
          }
        )
      end

      it 'sets the agent, clears agent bot and opens the conversation' do
        result = described_class.new(conversation: conversation, assignee_id: agent.id).perform

        conversation.reload
        expect(result).to eq(agent)
        expect(conversation.assignee_id).to eq(agent.id)
        expect(conversation.assignee_agent_bot_id).to be_nil
        expect(conversation.status).to eq('open')
      end

      it 'starts the waiting clock when opening a bot-owned pending conversation' do
        conversation.update!(waiting_since: nil)

        freeze_time do
          described_class.new(conversation: conversation, assignee_id: agent.id).perform

          expect(conversation.reload.waiting_since).to eq(Time.current)
        end
      end

      it 'preserves status for ordinary human assignment changes' do
        conversation.update!(assignee_agent_bot: nil, status: :resolved)

        described_class.new(conversation: conversation, assignee_id: agent.id).perform

        expect(conversation.reload.status).to eq('resolved')
      end

      it 'preserves status when taking over a bot-owned non-pending conversation' do
        conversation.update!(assignee_agent_bot: agent_bot, status: :resolved)

        described_class.new(conversation: conversation, assignee_id: agent.id).perform

        expect(conversation.reload.status).to eq('resolved')
      end

      it 'clears panel_ia state attributes and keeps other custom attributes' do
        described_class.new(conversation: conversation, assignee_id: agent.id).perform

        conversation.reload
        expect(conversation.custom_attributes).not_to have_key('panel_ia_estado')
        expect(conversation.custom_attributes).not_to have_key('panel_ia_estado_label')
        expect(conversation.custom_attributes).not_to have_key('panel_ia_updated_at')
        expect(conversation.custom_attributes['other_attr']).to eq('keep')
      end
    end

    context 'when assigning an agent bot' do
      let(:service) do
        described_class.new(
          conversation: conversation,
          assignee_id: agent_bot.id,
          assignee_type: 'AgentBot'
        )
      end

      before do
        create(:agent_bot_inbox, inbox: conversation.inbox, agent_bot: agent_bot)
        conversation.update!(
          assignee: agent,
          assignee_agent_bot: nil,
          custom_attributes: {
            'panel_ia_estado' => 'activo',
            'panel_ia_estado_label' => 'AI responding'
          }
        )
      end

      it 'sets the agent bot and clears human assignee' do
        result = service.perform

        conversation.reload
        expect(result).to eq(agent_bot)
        expect(conversation.assignee_agent_bot_id).to eq(agent_bot.id)
        expect(conversation.assignee_id).to be_nil
        expect(conversation.status).to eq('pending')
      end

      it 'marks a resolved conversation pending' do
        conversation.update!(status: :resolved)

        service.perform

        expect(conversation.reload.status).to eq('pending')
      end

      it 'marks a snoozed conversation pending and clears the snooze timestamp' do
        conversation.update!(status: :snoozed, snoozed_until: 1.day.from_now)

        service.perform

        conversation.reload
        expect(conversation.status).to eq('pending')
        expect(conversation.snoozed_until).to be_nil
      end

      it 'does not clear panel_ia state attributes' do
        service.perform

        conversation.reload
        expect(conversation.custom_attributes['panel_ia_estado']).to eq('activo')
        expect(conversation.custom_attributes['panel_ia_estado_label']).to eq('AI responding')
      end

      it 'does not assign an inactive inbox bot' do
        conversation.inbox.agent_bot_inbox.update!(status: :inactive)
        conversation.update!(assignee: agent, assignee_agent_bot: nil)

        result = service.perform

        conversation.reload
        expect(result).to be_nil
        expect(conversation.assignee_agent_bot_id).to be_nil
        expect(conversation.assignee_id).to eq(agent.id)
      end

      it 'does not assign a bot from another inbox' do
        other_bot = create(:agent_bot, account: account)
        other_service = described_class.new(
          conversation: conversation,
          assignee_id: other_bot.id,
          assignee_type: 'AgentBot'
        )

        result = other_service.perform

        conversation.reload
        expect(result).to be_nil
        expect(conversation.assignee_agent_bot_id).to be_nil
      end
    end
  end
end
