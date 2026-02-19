# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Conversations::AutoAssignService, type: :service do
  before do
    # Clear any installation config that might reference non-existent features
    InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')&.destroy
  end

  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account, status: :open) }
  let(:service) { described_class.new(conversation) }
  let!(:label1) { create(:label, title: 'billing', account: account, allow_auto_assign: true) }
  let!(:label2) { create(:label, title: 'support', account: account, allow_auto_assign: true) }
  let!(:team1) { create(:team, name: 'Support Team', description: 'Handles support', account: account, allow_auto_assign: true) }
  let!(:team2) { create(:team, name: 'Sales Team', description: 'Handles sales', account: account, allow_auto_assign: true) }

  # Helper: create an incoming message with specific content
  def create_incoming(content, conv: conversation)
    create(:message, conversation: conv, message_type: :incoming, content: content)
  end

  describe '#perform' do
    context 'with content-length threshold' do
      it 'processes a single message with 60+ characters' do
        create_incoming('I need help with my billing invoice, it shows the wrong amount charged')
        stub_agent_call(ConversationTriageAgent, content: { 'label_id' => label1.id, 'team_id' => nil })

        expect { service.perform }.to change { conversation.reload.label_list.to_a }.from([]).to(['billing'])
      end

      it 'does not process a single short message under 60 characters' do
        create_incoming('hello')

        expect(ConversationTriageAgent).not_to receive(:call)
        service.perform
      end

      it 'processes 2+ messages with combined 30+ characters' do
        create_incoming('I have a billing issue')
        create_incoming('Can you help me?')
        stub_agent_call(ConversationTriageAgent, content: { 'label_id' => label1.id, 'team_id' => nil })

        expect { service.perform }.to change { conversation.reload.label_list.to_a }.from([]).to(['billing'])
      end

      it 'does not process 2 messages with combined content under 30 characters' do
        create_incoming('hi')
        create_incoming('hello')

        expect(ConversationTriageAgent).not_to receive(:call)
        service.perform
      end

      it 'handles nil content gracefully' do
        create(:message, conversation: conversation, message_type: :incoming, content: nil)

        expect(ConversationTriageAgent).not_to receive(:call)
        service.perform
      end

      it 'only counts incoming messages for threshold' do
        create(:message, conversation: conversation, message_type: :outgoing, content: 'A' * 100)

        expect(ConversationTriageAgent).not_to receive(:call)
        service.perform
      end
    end

    context 'when conversation is not open' do
      before do
        create_incoming('I need help with my billing invoice, it shows the wrong amount charged')
        conversation.update!(status: :resolved)
      end

      it 'does not process the conversation' do
        expect(ConversationTriageAgent).not_to receive(:call)
        described_class.new(conversation).perform
      end
    end

    context 'when both label and team are already assigned (early exit)' do
      before do
        create_incoming('I need help with my billing invoice, it shows the wrong amount charged')
        conversation.label_list.add('existing-label')
        conversation.save!
        conversation.update!(team: team2)
      end

      it 'does not call the agent' do
        expect(ConversationTriageAgent).not_to receive(:call)
        described_class.new(conversation).perform
      end
    end

    context 'when only label is assigned' do
      before do
        create_incoming('I need help with my billing invoice, it shows the wrong amount charged')
        conversation.label_list.add('existing-label')
        conversation.save!
      end

      it 'still processes to assign team' do
        stub_agent_call(ConversationTriageAgent, content: { 'label_id' => nil, 'team_id' => team1.id })

        expect { described_class.new(conversation).perform }.to change { conversation.reload.team_id }.from(nil).to(team1.id)
      end
    end

    context 'when only team is assigned' do
      before do
        create_incoming('I need help with my billing invoice, it shows the wrong amount charged')
        conversation.update!(team: team2)
      end

      it 'still processes to assign label' do
        stub_agent_call(ConversationTriageAgent, content: { 'label_id' => label1.id, 'team_id' => nil })

        expect { described_class.new(conversation).perform }.to change { conversation.reload.label_list.to_a }.from([]).to(['billing'])
      end
    end

    context 'when no labels or teams have auto-assign enabled' do
      before do
        create_incoming('I need help with my billing invoice, it shows the wrong amount charged')
        label1.update!(allow_auto_assign: false)
        label2.update!(allow_auto_assign: false)
        team1.update!(allow_auto_assign: false)
        team2.update!(allow_auto_assign: false)
      end

      it 'does not process the conversation' do
        expect(ConversationTriageAgent).not_to receive(:call)
        described_class.new(conversation).perform
      end
    end

    context 'when applying suggestions' do
      before { create_incoming('I need help with my billing invoice, it shows the wrong amount charged') }

      it 'applies both label and team when suggested' do
        stub_agent_call(ConversationTriageAgent, content: { 'label_id' => label1.id, 'team_id' => team1.id })

        service.perform
        conversation.reload

        expect(conversation.label_list.to_a).to include('billing')
        expect(conversation.team_id).to eq(team1.id)
      end

      it 'only applies label when no team suggested' do
        stub_agent_call(ConversationTriageAgent, content: { 'label_id' => label1.id, 'team_id' => nil })

        service.perform
        conversation.reload

        expect(conversation.label_list.to_a).to include('billing')
        expect(conversation.team_id).to be_nil
      end

      it 'only applies team when no label suggested' do
        stub_agent_call(ConversationTriageAgent, content: { 'label_id' => nil, 'team_id' => team1.id })

        service.perform
        conversation.reload

        expect(conversation.label_list.to_a).to be_empty
        expect(conversation.team_id).to eq(team1.id)
      end

      it 'does not apply label if conversation already has labels' do
        conversation.label_list.add('existing-label')
        conversation.save!

        stub_agent_call(ConversationTriageAgent, content: { 'label_id' => label1.id, 'team_id' => team1.id })

        described_class.new(conversation).perform
        conversation.reload

        expect(conversation.label_list.to_a).not_to include('billing')
        expect(conversation.team_id).to eq(team1.id)
      end

      it 'does not apply team if conversation already has team' do
        conversation.update!(team: team2)

        stub_agent_call(ConversationTriageAgent, content: { 'label_id' => label1.id, 'team_id' => team1.id })

        service.perform
        conversation.reload

        expect(conversation.label_list.to_a).to include('billing')
        expect(conversation.team_id).to eq(team2.id)
      end
    end

    context 'when only auto-labeling is enabled' do
      before { create_incoming('I need help with my billing invoice, it shows the wrong amount charged') }

      it 'does not call agent with teams when teams disabled' do
        team1.update!(allow_auto_assign: false)
        team2.update!(allow_auto_assign: false)

        expect(ConversationTriageAgent).to receive(:call) do |args|
          expect(args[:available_teams]).to be_empty
        end.and_return(instance_double('RubyLLM::Agents::Result', success?: true, content: { 'label_id' => label1.id, 'team_id' => nil }))

        described_class.new(conversation).perform
      end
    end

    context 'when only auto-team is enabled' do
      before { create_incoming('I need help with my billing invoice, it shows the wrong amount charged') }

      it 'does not call agent with labels when labels disabled' do
        label1.update!(allow_auto_assign: false)
        label2.update!(allow_auto_assign: false)

        expect(ConversationTriageAgent).to receive(:call) do |args|
          expect(args[:available_labels]).to be_empty
        end.and_return(instance_double('RubyLLM::Agents::Result', success?: true, content: { 'label_id' => nil, 'team_id' => team1.id }))

        described_class.new(conversation).perform
      end
    end

    context 'when agent returns unsuccessful result' do
      before { create_incoming('I need help with my billing invoice, it shows the wrong amount charged') }

      it 'does not apply anything' do
        stub_agent_call(ConversationTriageAgent, success: false)

        service.perform
        conversation.reload

        expect(conversation.label_list.to_a).to be_empty
        expect(conversation.team_id).to be_nil
      end
    end

    context 'when agent returns nil for both IDs' do
      before { create_incoming('I need help with my billing invoice, it shows the wrong amount charged') }

      it 'does not apply anything' do
        stub_agent_call(ConversationTriageAgent, content: { 'label_id' => nil, 'team_id' => nil })

        service.perform
        conversation.reload

        expect(conversation.label_list.to_a).to be_empty
        expect(conversation.team_id).to be_nil
      end
    end

    context 'when suggested label does not exist' do
      before { create_incoming('I need help with my billing invoice, it shows the wrong amount charged') }

      it 'does not apply label' do
        stub_agent_call(ConversationTriageAgent, content: { 'label_id' => 999_999, 'team_id' => nil })

        service.perform
        expect(conversation.reload.label_list.to_a).to be_empty
      end
    end

    context 'when suggested team does not exist' do
      before { create_incoming('I need help with my billing invoice, it shows the wrong amount charged') }

      it 'does not apply team' do
        stub_agent_call(ConversationTriageAgent, content: { 'label_id' => nil, 'team_id' => 999_999 })

        service.perform
        expect(conversation.reload.team_id).to be_nil
      end
    end

    context 'when an error occurs' do
      before { create_incoming('I need help with my billing invoice, it shows the wrong amount charged') }

      it 'logs the error and re-raises for job retry' do
        allow(ConversationTriageAgent).to receive(:call).and_raise(StandardError.new('API Error'))

        expect(Rails.logger).to receive(:error)
          .with("Auto-classification failed for conversation #{conversation.id}: API Error")

        expect { service.perform }.to raise_error(StandardError, 'API Error')
      end
    end

    context 'when conversation was recently triaged with no new messages' do
      it 'does not process the conversation' do
        create(:message, conversation: conversation, message_type: :incoming,
                         content: 'I need help with my billing invoice, it shows the wrong amount charged',
                         created_at: 15.minutes.ago)
        conversation.update_column(:last_triaged_at, 10.minutes.ago)

        expect(ConversationTriageAgent).not_to receive(:call)
        service.perform
      end
    end

    context 'when conversation was recently triaged but has new messages' do
      it 'processes the conversation despite cooldown' do
        create_incoming('I need help with my billing invoice, it shows the wrong amount charged')
        conversation.update_column(:last_triaged_at, 10.minutes.ago)

        # New message arrives AFTER triage
        create_incoming('Actually the charge was $500 instead of $50, please fix this urgently')

        stub_agent_call(ConversationTriageAgent, content: { 'label_id' => label1.id, 'team_id' => nil })

        expect { described_class.new(conversation).perform }.to change { conversation.reload.label_list.to_a }.from([]).to(['billing'])
      end
    end

    context 'when conversation was triaged more than 30 minutes ago' do
      before { create_incoming('I need help with my billing invoice, it shows the wrong amount charged') }

      it 'processes the conversation' do
        conversation.update_column(:last_triaged_at, 31.minutes.ago)
        stub_agent_call(ConversationTriageAgent, content: { 'label_id' => label1.id, 'team_id' => nil })

        expect { service.perform }.to change { conversation.reload.label_list.to_a }.from([]).to(['billing'])
      end
    end

    context 'when conversation has never been triaged' do
      before { create_incoming('I need help with my billing invoice, it shows the wrong amount charged') }

      it 'processes the conversation' do
        expect(conversation.last_triaged_at).to be_nil
        stub_agent_call(ConversationTriageAgent, content: { 'label_id' => label1.id, 'team_id' => nil })

        expect { service.perform }.to change { conversation.reload.label_list.to_a }.from([]).to(['billing'])
      end
    end

    it 'updates last_triaged_at when processing' do
      create_incoming('I need help with my billing invoice, it shows the wrong amount charged')
      stub_agent_call(ConversationTriageAgent, content: { 'label_id' => nil, 'team_id' => nil })

      expect { service.perform }.to change { conversation.reload.last_triaged_at }.from(nil)
    end

    it 'passes metadata params to the agent' do
      create_incoming('I need help with my billing invoice, it shows the wrong amount charged')

      expect(ConversationTriageAgent).to receive(:call).with(
        hash_including(
          account_id: account.id,
          conversation_id: conversation.id,
          inbox_id: conversation.inbox_id
        )
      ).and_return(instance_double('RubyLLM::Agents::Result', success?: true, content: { 'label_id' => nil, 'team_id' => nil }))

      service.perform
    end

    context 'with Aloo::Current tenant context' do
      before { create_incoming('I need help with my billing invoice, it shows the wrong amount charged') }

      it 'sets Aloo::Current.account while calling the agent' do
        captured_account = nil
        allow(ConversationTriageAgent).to receive(:call) do
          captured_account = Aloo::Current.account
          instance_double('RubyLLM::Agents::Result', success?: true, content: { 'label_id' => nil, 'team_id' => nil })
        end

        service.perform
        expect(captured_account).to eq(account)
      end

      it 'resets Aloo::Current.account after execution' do
        stub_agent_call(ConversationTriageAgent, content: { 'label_id' => nil, 'team_id' => nil })

        service.perform
        expect(Aloo::Current.account).to be_nil
      end

      it 'resets Aloo::Current.account even when an error occurs' do
        allow(ConversationTriageAgent).to receive(:call).and_raise(StandardError.new('boom'))

        expect { service.perform }.to raise_error(StandardError, 'boom')
        expect(Aloo::Current.account).to be_nil
      end
    end
  end

  describe 'constants' do
    it 'has MIN_CONTENT_LENGTH set to 60' do
      expect(described_class::MIN_CONTENT_LENGTH).to eq(60)
    end

    it 'has MIN_CONTENT_LENGTH_MULTI set to 30' do
      expect(described_class::MIN_CONTENT_LENGTH_MULTI).to eq(30)
    end

    it 'has MIN_MESSAGES_MULTI set to 2' do
      expect(described_class::MIN_MESSAGES_MULTI).to eq(2)
    end
  end
end
