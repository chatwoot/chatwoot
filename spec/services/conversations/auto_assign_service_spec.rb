# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Conversations::AutoAssignService do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:service) { described_class.new(conversation) }
  let!(:label1) { create(:label, title: 'billing', account: account, allow_auto_assign: true) }
  let!(:label2) { create(:label, title: 'support', account: account, allow_auto_assign: true) }
  let!(:team1) { create(:team, name: 'Support Team', description: 'Handles support', account: account, allow_auto_assign: true) }
  let!(:team2) { create(:team, name: 'Sales Team', description: 'Handles sales', account: account, allow_auto_assign: true) }

  def mock_agent_result(content, success: true)
    double('AgentResult', success?: success, content: content)
  end

  before do
    create_list(:message, 3, conversation: conversation, message_type: :incoming, content: 'Test message')
  end

  describe '#perform' do
    context 'when both auto-label and auto-team are enabled' do
      it 'applies both label and team when suggested' do
        allow(ConversationTriageAgent).to receive(:call).and_return(mock_agent_result({
                                                                                        'label_id' => label1.id,
                                                                                        'team_id' => team1.id
                                                                                      }))

        expect(conversation).to receive(:add_labels).with([label1.title])
        expect(conversation).to receive(:update).with(team: team1)

        service.perform
      end

      it 'logs successful classification' do
        allow(ConversationTriageAgent).to receive(:call).and_return(mock_agent_result({
                                                                                        'label_id' => label1.id,
                                                                                        'team_id' => team1.id
                                                                                      }))
        allow(conversation).to receive(:add_labels)
        allow(conversation).to receive(:update)

        expect(Rails.logger).to receive(:info).with("Auto-labeled conversation #{conversation.id} with: #{label1.title}")
        expect(Rails.logger).to receive(:info).with("Auto-assigned conversation #{conversation.id} to team: #{team1.name}")

        service.perform
      end

      it 'allows adding labels when conversation has fewer than 3 labels' do
        conversation.label_list.add('Existing Label')
        conversation.save!

        allow(ConversationTriageAgent).to receive(:call).and_return(mock_agent_result({
                                                                                        'label_id' => label1.id,
                                                                                        'team_id' => team1.id
                                                                                      }))

        expect(conversation).to receive(:add_labels).with([label1.title])
        expect(conversation).to receive(:update).with(team: team1)

        described_class.new(conversation).perform
      end

      it 'skips label if conversation already has 3 labels' do
        conversation.label_list.add('Label1', 'Label2', 'Label3')
        conversation.save!

        allow(ConversationTriageAgent).to receive(:call).and_return(mock_agent_result({
                                                                                        'label_id' => label1.id,
                                                                                        'team_id' => team1.id
                                                                                      }))

        expect(conversation).not_to receive(:add_labels)
        expect(conversation).to receive(:update).with(team: team1)

        described_class.new(conversation).perform
      end

      it 'skips team if conversation already has team' do
        conversation.update!(team: team2)

        allow(ConversationTriageAgent).to receive(:call).and_return(mock_agent_result({
                                                                                        'label_id' => label1.id,
                                                                                        'team_id' => team1.id
                                                                                      }))

        expect(conversation).to receive(:add_labels).with([label1.title])
        expect(conversation).not_to receive(:update)

        service.perform
      end
    end

    context 'when only auto-labeling is enabled' do
      it 'only applies label' do
        allow(ConversationTriageAgent).to receive(:call).and_return(mock_agent_result({
                                                                                        'label_id' => label1.id,
                                                                                        'team_id' => nil
                                                                                      }))

        expect(conversation).to receive(:add_labels).with([label1.title])

        service.perform
      end

      it 'does not call agent with teams' do
        # Disable teams from auto-assign
        team1.update!(allow_auto_assign: false)
        team2.update!(allow_auto_assign: false)

        expect(ConversationTriageAgent).to receive(:call) do |args|
          expect(args[:available_teams]).to be_empty
        end.and_return(mock_agent_result({ 'label_id' => label1.id, 'team_id' => nil }))

        described_class.new(conversation).perform
      end
    end

    context 'when only auto-team is enabled' do
      it 'only applies team' do
        allow(ConversationTriageAgent).to receive(:call).and_return(mock_agent_result({
                                                                                        'label_id' => nil,
                                                                                        'team_id' => team1.id
                                                                                      }))

        expect(conversation).to receive(:update).with(team: team1)

        service.perform
      end

      it 'does not call agent with labels' do
        # Disable labels from auto-assign
        label1.update!(allow_auto_assign: false)
        label2.update!(allow_auto_assign: false)

        expect(ConversationTriageAgent).to receive(:call) do |args|
          expect(args[:available_labels]).to be_empty
        end.and_return(mock_agent_result({ 'label_id' => nil, 'team_id' => team1.id }))

        described_class.new(conversation).perform
      end
    end

    context 'when no labels or teams have auto-assign enabled' do
      before do
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

    context 'when message threshold is not met' do
      before do
        conversation.messages.destroy_all
        create_list(:message, 2, conversation: conversation, message_type: :incoming, content: 'Message')
      end

      it 'does not process if conversation is less than 5 minutes old' do
        expect(ConversationTriageAgent).not_to receive(:call)

        described_class.new(conversation).perform
      end

      it 'processes if conversation is older than 5 minutes and has no labels' do
        conversation.update!(created_at: 6.minutes.ago)

        allow(ConversationTriageAgent).to receive(:call).and_return(mock_agent_result({
                                                                                        'label_id' => label1.id,
                                                                                        'team_id' => nil
                                                                                      }))

        expect(conversation).to receive(:add_labels).with([label1.title])

        described_class.new(conversation).perform
      end

      it 'does not process with time threshold if conversation already has labels' do
        conversation.update!(created_at: 6.minutes.ago)
        conversation.label_list.add('Existing Label')
        conversation.save!

        expect(ConversationTriageAgent).not_to receive(:call)

        described_class.new(conversation).perform
      end
    end

    context 'when excluding already-assigned labels' do
      it 'excludes already-assigned labels from available labels' do
        conversation.label_list.add(label1.title)
        conversation.save!

        expect(ConversationTriageAgent).to receive(:call) do |args|
          label_ids = args[:available_labels].map { |l| l['id'] }
          expect(label_ids).not_to include(label1.id)
          expect(label_ids).to include(label2.id)
        end.and_return(mock_agent_result({ 'label_id' => label2.id, 'team_id' => nil }))

        expect(conversation).to receive(:add_labels).with([label2.title])

        described_class.new(conversation).perform
      end
    end

    context 'when agent returns unsuccessful result' do
      it 'does not apply anything' do
        allow(ConversationTriageAgent).to receive(:call).and_return(mock_agent_result(nil, success: false))

        expect(conversation).not_to receive(:add_labels)
        expect(conversation).not_to receive(:update)

        service.perform
      end
    end

    context 'when agent returns nil for both IDs' do
      it 'does not apply anything' do
        allow(ConversationTriageAgent).to receive(:call).and_return(mock_agent_result({
                                                                                        'label_id' => nil,
                                                                                        'team_id' => nil
                                                                                      }))

        expect(conversation).not_to receive(:add_labels)
        expect(conversation).not_to receive(:update)

        service.perform
      end
    end

    context 'when suggested label does not exist' do
      it 'does not apply label' do
        allow(ConversationTriageAgent).to receive(:call).and_return(mock_agent_result({
                                                                                        'label_id' => 999_999,
                                                                                        'team_id' => nil
                                                                                      }))

        expect(conversation).not_to receive(:add_labels)

        service.perform
      end
    end

    context 'when suggested team does not exist' do
      it 'does not apply team' do
        allow(ConversationTriageAgent).to receive(:call).and_return(mock_agent_result({
                                                                                        'label_id' => nil,
                                                                                        'team_id' => 999_999
                                                                                      }))

        expect(conversation).not_to receive(:update)

        service.perform
      end
    end

    context 'when an error occurs' do
      it 'logs the error and re-raises for job retry' do
        allow(ConversationTriageAgent).to receive(:call).and_raise(StandardError.new('API Error'))

        expect(Rails.logger).to receive(:error)
          .with("Auto-classification failed for conversation #{conversation.id}: API Error")

        expect { service.perform }.to raise_error(StandardError, 'API Error')
      end
    end

    context 'when conversation is not open' do
      before do
        allow(conversation).to receive(:open?).and_return(false)
      end

      it 'does not process the conversation' do
        expect(ConversationTriageAgent).not_to receive(:call)

        service.perform
      end
    end

    context 'when conversation was recently triaged' do
      it 'does not process the conversation' do
        conversation.update_column(:last_triaged_at, 10.minutes.ago)

        expect(ConversationTriageAgent).not_to receive(:call)

        service.perform
      end
    end

    context 'when conversation was triaged more than 30 minutes ago' do
      it 'processes the conversation' do
        conversation.update_column(:last_triaged_at, 31.minutes.ago)

        allow(ConversationTriageAgent).to receive(:call).and_return(mock_agent_result({
                                                                                        'label_id' => label1.id,
                                                                                        'team_id' => nil
                                                                                      }))

        expect(conversation).to receive(:add_labels).with([label1.title])

        service.perform
      end
    end

    context 'when conversation has never been triaged' do
      it 'processes the conversation' do
        expect(conversation.last_triaged_at).to be_nil

        allow(ConversationTriageAgent).to receive(:call).and_return(mock_agent_result({
                                                                                        'label_id' => label1.id,
                                                                                        'team_id' => nil
                                                                                      }))

        expect(conversation).to receive(:add_labels).with([label1.title])

        service.perform
      end
    end

    it 'updates last_triaged_at when processing' do
      allow(ConversationTriageAgent).to receive(:call).and_return(mock_agent_result({
                                                                                      'label_id' => nil,
                                                                                      'team_id' => nil
                                                                                    }))

      expect { service.perform }.to change { conversation.reload.last_triaged_at }.from(nil)
    end
  end
end
