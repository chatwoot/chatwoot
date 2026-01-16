# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HandoffTool, :aloo do
  let(:account) { create(:account) }
  let(:assistant) { create(:aloo_assistant, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :pending) }

  before do
    Aloo::Current.account = account
    Aloo::Current.assistant = assistant
    Aloo::Current.conversation = conversation
  end

  after do
    Aloo::Current.reset
  end

  describe '.description' do
    it 'describes when to use handoff' do
      expect(described_class.description).to include('Transfer')
      expect(described_class.description).to include('human agent')
    end
  end

  describe '#execute' do
    let(:tool) { described_class.new }

    context 'with valid context' do
      it 'validates context' do
        expect { tool.execute(reason: 'Customer requested') }.not_to raise_error
      end

      it 'normalizes priority' do
        result = tool.execute(reason: 'Test', priority: 'invalid')

        expect(result[:success]).to be true
      end

      it 'deactivates bot for conversation' do
        # The handoff flag is only set when agent_bot_inbox exists (legacy behavior)
        # Create an agent_bot_inbox to test this path
        agent_bot = create(:agent_bot, account: account)
        create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)

        tool.execute(reason: 'Customer requested human')

        expect(conversation.reload.custom_attributes['aloo_handoff_active']).to be true
      end

      it 'updates conversation status to open' do
        tool.execute(reason: 'Customer requested human')

        expect(conversation.reload.status).to eq('open')
      end

      it 'adds handoff note as private message' do
        expect do
          tool.execute(reason: 'Too complex', summary: 'Customer needs refund')
        end.to change { conversation.messages.where(private: true).count }.by(1)
      end
    end

    context 'with priority levels' do
      described_class::PRIORITY_LEVELS.each do |priority|
        it "accepts #{priority} priority" do
          result = tool.execute(reason: 'Test', priority: priority)

          expect(result[:success]).to be true
        end
      end

      it 'defaults invalid priority to normal' do
        tool.execute(reason: 'Test', priority: 'super-urgent')

        expect(conversation.reload.priority).to eq('medium')
      end
    end

    context 'with preferred_team' do
      let(:team) { create(:team, name: 'Billing', account: account) }
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:team_member, team: team, user: agent)
        create(:inbox_member, inbox: inbox, user: agent)
      end

      it 'tries to assign agent from team' do
        result = tool.execute(reason: 'Billing issue', preferred_team: 'Billing')

        expect(result[:data][:assigned_agent]).to eq(agent)
      end

      it 'handles team not found' do
        result = tool.execute(reason: 'Test', preferred_team: 'NonexistentTeam')

        expect(result[:success]).to be true
      end
    end

    context 'with auto_assignment enabled' do
      before do
        inbox.update!(enable_auto_assignment: true)
      end

      it 'does not manually assign' do
        result = tool.execute(reason: 'Test')

        expect(result[:data][:assigned_agent]).to be_nil
      end
    end

    context 'when error occurs' do
      before do
        allow(conversation).to receive(:update!).and_raise(StandardError, 'DB error')
      end

      it 'logs error and returns error response' do
        result = tool.execute(reason: 'Test')

        expect(result[:success]).to be false
        expect(result[:error]).to include('Handoff failed')
      end
    end

    context 'without required context' do
      before do
        Aloo::Current.conversation = nil
      end

      it 'returns error response' do
        result = tool.execute(reason: 'Test')

        expect(result[:success]).to be false
        expect(result[:error]).to include('Conversation context required')
      end
    end
  end

  describe 'handoff note content' do
    let(:tool) { described_class.new }

    it 'includes priority' do
      tool.execute(reason: 'Test', priority: 'urgent')

      note = conversation.messages.where(private: true).last
      expect(note.content).to include('Urgent')
    end

    it 'includes reason' do
      tool.execute(reason: 'Customer needs refund for damaged item')

      note = conversation.messages.where(private: true).last
      expect(note.content).to include('Customer needs refund')
    end

    it 'includes summary when provided' do
      tool.execute(reason: 'Test', summary: 'Customer ordered product X')

      note = conversation.messages.where(private: true).last
      expect(note.content).to include('Conversation Summary')
      expect(note.content).to include('Customer ordered product X')
    end
  end
end
