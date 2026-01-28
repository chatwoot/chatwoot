# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Conversations::AutoAssignService do
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

  def create_incoming_messages(count)
    create_list(:message, count, conversation: conversation, message_type: :incoming, content: 'Test message')
  end

  describe '#perform' do
    context 'with message count limits' do
      it 'does not process when fewer than 3 messages' do
        create_incoming_messages(2)

        expect(ConversationTriageAgent).not_to receive(:run)
        service.perform
      end

      it 'processes when exactly 3 messages' do
        create_incoming_messages(3)

        expect(ConversationTriageAgent).to receive(:run).and_return({ 'label_id' => label1.id, 'team_id' => nil })
        allow(conversation).to receive(:add_labels)

        service.perform
      end

      it 'processes when between 3 and 10 messages' do
        create_incoming_messages(7)

        expect(ConversationTriageAgent).to receive(:run).and_return({ 'label_id' => label1.id, 'team_id' => nil })
        allow(conversation).to receive(:add_labels)

        service.perform
      end

      it 'processes when exactly 10 messages' do
        create_incoming_messages(10)

        expect(ConversationTriageAgent).to receive(:run).and_return({ 'label_id' => label1.id, 'team_id' => nil })
        allow(conversation).to receive(:add_labels)

        service.perform
      end

      it 'does not process when more than 10 messages' do
        create_incoming_messages(11)

        expect(ConversationTriageAgent).not_to receive(:run)
        service.perform
      end

      it 'only counts incoming messages for threshold' do
        create_incoming_messages(2)
        create_list(:message, 5, conversation: conversation, message_type: :outgoing, content: 'Reply')

        expect(ConversationTriageAgent).not_to receive(:run)
        service.perform
      end
    end

    context 'when conversation is not open' do
      before do
        create_incoming_messages(5)
        conversation.update!(status: :resolved)
      end

      it 'does not process the conversation' do
        expect(ConversationTriageAgent).not_to receive(:run)
        described_class.new(conversation).perform
      end
    end

    context 'when already labeled and assigned' do
      before do
        create_incoming_messages(5)
        conversation.label_list.add('existing-label')
        conversation.save!
        conversation.update!(team: team2)
      end

      it 'does not process the conversation' do
        expect(ConversationTriageAgent).not_to receive(:run)
        described_class.new(conversation).perform
      end
    end

    context 'when only label is assigned' do
      before do
        create_incoming_messages(5)
        conversation.label_list.add('existing-label')
        conversation.save!
      end

      it 'still processes to assign team' do
        expect(ConversationTriageAgent).to receive(:run).and_return({ 'label_id' => nil, 'team_id' => team1.id })
        expect(conversation).to receive(:update).with(team: team1)

        described_class.new(conversation).perform
      end
    end

    context 'when only team is assigned' do
      before do
        create_incoming_messages(5)
        conversation.update!(team: team2)
      end

      it 'still processes to assign label' do
        expect(ConversationTriageAgent).to receive(:run).and_return({ 'label_id' => label1.id, 'team_id' => nil })
        expect(conversation).to receive(:add_labels).with([label1.title])

        described_class.new(conversation).perform
      end
    end

    context 'when no labels or teams have auto-assign enabled' do
      before do
        create_incoming_messages(5)
        label1.update!(allow_auto_assign: false)
        label2.update!(allow_auto_assign: false)
        team1.update!(allow_auto_assign: false)
        team2.update!(allow_auto_assign: false)
      end

      it 'does not process the conversation' do
        expect(ConversationTriageAgent).not_to receive(:run)
        described_class.new(conversation).perform
      end
    end

    context 'when applying suggestions' do
      before { create_incoming_messages(5) }

      it 'applies both label and team when suggested' do
        allow(ConversationTriageAgent).to receive(:run).and_return({
                                                                     'label_id' => label1.id,
                                                                     'team_id' => team1.id
                                                                   })

        expect(conversation).to receive(:add_labels).with([label1.title])
        expect(conversation).to receive(:update).with(team: team1)

        service.perform
      end

      it 'only applies label when no team suggested' do
        allow(ConversationTriageAgent).to receive(:run).and_return({
                                                                     'label_id' => label1.id,
                                                                     'team_id' => nil
                                                                   })

        expect(conversation).to receive(:add_labels).with([label1.title])
        expect(conversation).not_to receive(:update)

        service.perform
      end

      it 'only applies team when no label suggested' do
        allow(ConversationTriageAgent).to receive(:run).and_return({
                                                                     'label_id' => nil,
                                                                     'team_id' => team1.id
                                                                   })

        expect(conversation).not_to receive(:add_labels)
        expect(conversation).to receive(:update).with(team: team1)

        service.perform
      end

      it 'does not apply label if conversation already has labels' do
        conversation.label_list.add('existing-label')
        conversation.save!

        allow(ConversationTriageAgent).to receive(:run).and_return({
                                                                     'label_id' => label1.id,
                                                                     'team_id' => team1.id
                                                                   })

        expect(conversation).not_to receive(:add_labels)
        expect(conversation).to receive(:update).with(team: team1)

        described_class.new(conversation).perform
      end

      it 'does not apply team if conversation already has team' do
        conversation.update!(team: team2)

        allow(ConversationTriageAgent).to receive(:run).and_return({
                                                                     'label_id' => label1.id,
                                                                     'team_id' => team1.id
                                                                   })

        expect(conversation).to receive(:add_labels).with([label1.title])
        expect(conversation).not_to receive(:update)

        described_class.new(conversation).perform
      end
    end

    context 'when agent returns nil or empty results' do
      before { create_incoming_messages(5) }

      it 'does not apply anything when agent returns nil' do
        allow(ConversationTriageAgent).to receive(:run).and_return(nil)

        expect(conversation).not_to receive(:add_labels)
        expect(conversation).not_to receive(:update)

        service.perform
      end

      it 'does not apply anything when both IDs are nil' do
        allow(ConversationTriageAgent).to receive(:run).and_return({
                                                                     'label_id' => nil,
                                                                     'team_id' => nil
                                                                   })

        expect(conversation).not_to receive(:add_labels)
        expect(conversation).not_to receive(:update)

        service.perform
      end
    end

    context 'when suggested resources do not exist' do
      before { create_incoming_messages(5) }

      it 'does not apply non-existent label' do
        allow(ConversationTriageAgent).to receive(:run).and_return({
                                                                     'label_id' => 999_999,
                                                                     'team_id' => nil
                                                                   })

        expect(conversation).not_to receive(:add_labels)
        service.perform
      end

      it 'does not apply non-existent team' do
        allow(ConversationTriageAgent).to receive(:run).and_return({
                                                                     'label_id' => nil,
                                                                     'team_id' => 999_999
                                                                   })

        expect(conversation).not_to receive(:update)
        service.perform
      end
    end

    context 'when an error occurs' do
      before { create_incoming_messages(5) }

      it 'logs the error and re-raises for job retry' do
        allow(ConversationTriageAgent).to receive(:run).and_raise(StandardError.new('API Error'))

        expect(Rails.logger).to receive(:error)
          .with("Auto-classification failed for conversation #{conversation.id}: API Error")

        expect { service.perform }.to raise_error(StandardError, 'API Error')
      end
    end

    context 'logging' do
      before { create_incoming_messages(5) }

      it 'logs successful label application' do
        allow(ConversationTriageAgent).to receive(:run).and_return({ 'label_id' => label1.id, 'team_id' => nil })
        allow(conversation).to receive(:add_labels)

        expect(Rails.logger).to receive(:info).with("Auto-labeled conversation #{conversation.id} with: #{label1.title}")

        service.perform
      end

      it 'logs successful team assignment' do
        allow(ConversationTriageAgent).to receive(:run).and_return({ 'label_id' => nil, 'team_id' => team1.id })
        allow(conversation).to receive(:update)

        expect(Rails.logger).to receive(:info).with("Auto-assigned conversation #{conversation.id} to team: #{team1.name}")

        service.perform
      end
    end
  end

  describe 'constants' do
    it 'has MIN_MESSAGES set to 3' do
      expect(described_class::MIN_MESSAGES).to eq(3)
    end

    it 'has MAX_MESSAGES set to 10' do
      expect(described_class::MAX_MESSAGES).to eq(10)
    end
  end
end
