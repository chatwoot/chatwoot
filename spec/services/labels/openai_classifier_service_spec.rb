# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Labels::OpenaiClassifierService do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let!(:label1) { create(:label, title: 'billing', account: account) }
  let!(:label2) { create(:label, title: 'technical-support', account: account) }
  let!(:label3) { create(:label, title: 'feature-request', account: account) }

  let(:service) { described_class.new(conversation) }
  let(:mock_chat) { double('RubyLLM Chat') }
  let(:mock_schema_chat) { double('RubyLLM Schema Chat') }

  let(:structured_response) do
    double('LabelClassificationSchema',
           content: {
             'label_id' => label1.id,
             'reasoning' => 'Customer is asking about billing issues with technical aspects'
           })
  end

  before do
    # Create incoming messages to meet threshold
    create_list(:message, 3, conversation: conversation, message_type: :incoming, content: 'Customer message')
  end

  describe '#suggest_labels' do
    context 'when all conditions are met' do
      it 'returns suggested label from OpenAI' do
        allow(RubyLLM).to receive(:chat).and_return(mock_chat)
        allow(mock_chat).to receive(:with_temperature).with(0.3).and_return(mock_chat)
        allow(mock_chat).to receive(:with_schema).with(LabelClassificationSchema).and_return(mock_schema_chat)
        allow(mock_schema_chat).to receive(:ask).and_return(structured_response)

        result = service.suggest_labels

        expect(result[:label_id]).to eq(label1.id)
        expect(result[:reasoning]).to eq('Customer is asking about billing issues with technical aspects')
      end

      it 'calls RubyLLM with correct parameters' do
        allow(RubyLLM).to receive(:chat).and_return(mock_chat)
        allow(mock_chat).to receive(:with_temperature).with(0.3).and_return(mock_chat)
        allow(mock_chat).to receive(:with_schema).with(LabelClassificationSchema).and_return(mock_schema_chat)
        allow(mock_schema_chat).to receive(:ask).and_return(structured_response)

        service.suggest_labels

        expect(RubyLLM).to have_received(:chat).with(model: 'gpt-4o-mini')
        expect(mock_chat).to have_received(:with_temperature).with(0.3)
        expect(mock_chat).to have_received(:with_schema).with(LabelClassificationSchema)
      end
    end

    context 'when conversation has fewer than 3 incoming messages' do
      before do
        conversation.messages.destroy_all
        create_list(:message, 2, conversation: conversation, message_type: :incoming, content: 'Message')
        allow(RubyLLM).to receive(:chat)
      end

      it 'returns nil label_id without calling API' do
        result = service.suggest_labels

        expect(result[:label_id]).to be_nil
        expect(RubyLLM).not_to have_received(:chat)
      end
    end

    context 'when account has no labels' do
      before do
        account.labels.destroy_all
        allow(RubyLLM).to receive(:chat)
      end

      it 'returns nil label_id without calling API' do
        result = service.suggest_labels

        expect(result[:label_id]).to be_nil
        expect(RubyLLM).not_to have_received(:chat)
      end
    end

    context 'when OpenAI returns nil label_id' do
      let(:nil_label_response) do
        double('NilLabelResponse', content: { 'label_id' => nil, 'reasoning' => nil })
      end

      it 'returns nil label_id' do
        allow(RubyLLM).to receive(:chat).and_return(mock_chat)
        allow(mock_chat).to receive(:with_temperature).with(0.3).and_return(mock_chat)
        allow(mock_chat).to receive(:with_schema).with(LabelClassificationSchema).and_return(mock_schema_chat)
        allow(mock_schema_chat).to receive(:ask).and_return(nil_label_response)

        result = service.suggest_labels

        expect(result[:label_id]).to be_nil
      end
    end

    context 'when API call fails' do
      it 'handles errors gracefully' do
        allow(RubyLLM).to receive(:chat).and_raise(StandardError.new('Connection refused'))

        expect(Rails.logger).to receive(:error).with(/OpenAI label classification failed/)

        result = service.suggest_labels

        expect(result[:label_id]).to be_nil
        expect(result[:reasoning]).to be_nil
      end

      it 'handles API error responses' do
        allow(RubyLLM).to receive(:chat).and_return(mock_chat)
        allow(mock_chat).to receive(:with_temperature).with(0.3).and_return(mock_chat)
        allow(mock_chat).to receive(:with_schema).and_raise(StandardError.new('Internal Server Error'))

        expect(Rails.logger).to receive(:error).with(/OpenAI label classification failed/)

        result = service.suggest_labels

        expect(result[:label_id]).to be_nil
      end
    end

    context 'when conversation has mixed message types' do
      before do
        conversation.messages.destroy_all
        create(:message, conversation: conversation, message_type: :incoming, content: 'Customer: I need help')
        create(:message, conversation: conversation, message_type: :outgoing, content: 'Agent: How can I help?')
        create(:message, conversation: conversation, message_type: :incoming, content: 'Customer: Billing issue')
        create(:message, conversation: conversation, message_type: :incoming, content: 'Customer: Please help')
      end

      it 'calls API with properly formatted conversation' do
        allow(RubyLLM).to receive(:chat).and_return(mock_chat)
        allow(mock_chat).to receive(:with_temperature).with(0.3).and_return(mock_chat)
        allow(mock_chat).to receive(:with_schema).with(LabelClassificationSchema).and_return(mock_schema_chat)
        allow(mock_schema_chat).to receive(:ask).and_return(structured_response)

        service.suggest_labels

        expect(RubyLLM).to have_received(:chat)
        expect(mock_schema_chat).to have_received(:ask)
      end
    end
  end
end
