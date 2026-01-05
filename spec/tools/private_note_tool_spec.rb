# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PrivateNoteTool, :aloo do
  let(:account) { create(:account) }
  let(:assistant) { create(:aloo_assistant, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }

  before do
    Aloo::Current.account = account
    Aloo::Current.assistant = assistant
    Aloo::Current.conversation = conversation
  end

  after do
    Aloo::Current.reset
  end

  describe '.description' do
    it 'describes when to use private notes' do
      expect(described_class.description).to include('private note')
      expect(described_class.description).to include('agents')
    end
  end

  describe '#execute' do
    let(:tool) { described_class.new }

    context 'with valid parameters' do
      it 'creates a private message' do
        expect do
          tool.execute(content: 'Test note content')
        end.to change { conversation.messages.where(private: true).count }.by(1)
      end

      it 'returns success response' do
        result = tool.execute(content: 'Test note content')

        expect(result[:success]).to be true
        expect(result[:data][:note_created]).to be true
      end

      it 'formats content with category prefix' do
        tool.execute(content: 'Customer seems frustrated', category: 'observation')

        note = conversation.messages.where(private: true).last
        expect(note.content).to include('**Observation:**')
        expect(note.content).to include('Customer seems frustrated')
      end

      it 'tracks execution in conversation context' do
        tool.execute(content: 'Test note')

        context = Aloo::ConversationContext.find_by(conversation: conversation)
        expect(context.tool_history).not_to be_empty
        expect(context.tool_history.last['tool']).to eq('private_note')
      end

      it 'logs execution' do
        expect_any_instance_of(described_class).to receive(:log_execution)
          .with(hash_including(content: 'Test'), anything)

        tool.execute(content: 'Test')
      end
    end

    context 'with category' do
      described_class::VALID_CATEGORIES.each do |category|
        it "accepts #{category} category" do
          result = tool.execute(content: 'Test', category: category)

          expect(result[:success]).to be true
          expect(result[:data][:category]).to eq(category)
        end
      end

      it 'defaults invalid category to general' do
        result = tool.execute(content: 'Test', category: 'invalid')

        expect(result[:success]).to be true
        expect(result[:data][:category]).to eq('general')
      end

      it 'defaults nil category to general' do
        result = tool.execute(content: 'Test', category: nil)

        expect(result[:success]).to be true
        expect(result[:data][:category]).to eq('general')
      end
    end

    context 'with different category prefixes' do
      it 'uses observation prefix' do
        tool.execute(content: 'Note', category: 'observation')
        note = conversation.messages.where(private: true).last
        expect(note.content).to start_with('**Observation:**')
      end

      it 'uses summary prefix' do
        tool.execute(content: 'Note', category: 'summary')
        note = conversation.messages.where(private: true).last
        expect(note.content).to start_with('**Summary:**')
      end

      it 'uses warning prefix' do
        tool.execute(content: 'Note', category: 'warning')
        note = conversation.messages.where(private: true).last
        expect(note.content).to start_with('**Warning:**')
      end

      it 'uses note prefix for general' do
        tool.execute(content: 'Note', category: 'general')
        note = conversation.messages.where(private: true).last
        expect(note.content).to start_with('**Note:**')
      end
    end

    context 'when error occurs' do
      before do
        allow(conversation.messages).to receive(:create!).and_raise(StandardError, 'DB error')
      end

      it 'returns error response' do
        result = tool.execute(content: 'Test')

        expect(result[:success]).to be false
        expect(result[:error]).to include('Failed to add private note')
      end
    end

    context 'without required context' do
      before do
        Aloo::Current.conversation = nil
      end

      it 'returns error response' do
        result = tool.execute(content: 'Test')

        expect(result[:success]).to be false
        expect(result[:error]).to include('Conversation context required')
      end
    end

    context 'without account context' do
      before do
        Aloo::Current.account = nil
      end

      it 'returns error response' do
        result = tool.execute(content: 'Test')

        expect(result[:success]).to be false
        expect(result[:error]).to include('Account context required')
      end
    end

    context 'without assistant context' do
      before do
        Aloo::Current.assistant = nil
      end

      it 'returns error response' do
        result = tool.execute(content: 'Test')

        expect(result[:success]).to be false
        expect(result[:error]).to include('Assistant context required')
      end
    end
  end

  describe 'message attributes' do
    let(:tool) { described_class.new }

    it 'sets message_type to activity' do
      tool.execute(content: 'Test note')

      note = conversation.messages.where(private: true).last
      expect(note.message_type).to eq('activity')
    end

    it 'sets content_attributes with note marker' do
      tool.execute(content: 'Test note', category: 'warning')

      note = conversation.messages.where(private: true).last
      expect(note.content_attributes['aloo_private_note']).to be true
      expect(note.content_attributes['note_category']).to eq('warning')
    end
  end
end
