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

      it 'sets human_assistance_requested flag (NOT aloo_handoff_active)' do
        tool.execute(reason: 'Customer requested human')

        # AI should only request assistance, not trigger full handoff
        # Full handoff (aloo_handoff_active) can only be triggered by human agent
        expect(conversation.reload.custom_attributes['human_assistance_requested']).to be true
        expect(conversation.reload.custom_attributes['aloo_handoff_active']).to be_nil
      end

      it 'does NOT set aloo_handoff_active (AI cannot hand off on its own)' do
        tool.execute(reason: 'Customer requested human')

        # This is critical: AI must NOT be able to stop itself from responding
        # Only human agents can trigger true handoff via AgentHandoffService
        expect(conversation.reload.custom_attributes['aloo_handoff_active']).to be_nil
      end

      it 'records assistance request timestamp' do
        freeze_time do
          tool.execute(reason: 'Customer requested human')

          expect(conversation.reload.custom_attributes['human_assistance_requested_at']).to eq(Time.current.iso8601)
        end
      end

      it 'records assistance request reason' do
        tool.execute(reason: 'Customer needs refund')

        expect(conversation.reload.custom_attributes['human_assistance_reason']).to eq('Customer needs refund')
      end

      it 'keeps conversation status unchanged (AI continues responding)' do
        original_status = conversation.status

        tool.execute(reason: 'Customer requested human')

        # Status should not change to open - AI continues in pending state
        expect(conversation.reload.status).to eq(original_status)
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

      it 'defaults invalid priority to normal and elevates to high' do
        tool.execute(reason: 'Test', priority: 'super-urgent')

        # Invalid priority defaults to 'normal', then elevated to 'high' for visibility
        expect(conversation.reload.priority).to eq('high')
      end
    end

    context 'with preferred_team parameter' do
      # NOTE: preferred_team is accepted but not currently used for assignment
      # AI cannot assign agents - it can only request human assistance
      it 'accepts preferred_team without error' do
        result = tool.execute(reason: 'Billing issue', preferred_team: 'Billing')

        expect(result[:success]).to be true
      end

      it 'does not assign conversation to any agent' do
        tool.execute(reason: 'Billing issue', preferred_team: 'Billing')

        # AI cannot assign agents - only request assistance
        expect(conversation.reload.assignee).to be_nil
      end
    end

    context 'regardless of auto_assignment setting' do
      before do
        inbox.update!(enable_auto_assignment: true)
      end

      it 'does not assign any agent (AI cannot assign)' do
        tool.execute(reason: 'Test')

        # AI can only request human assistance, not assign
        expect(conversation.reload.assignee).to be_nil
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
