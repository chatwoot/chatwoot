# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ConversationTriageAgent do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let!(:label1) { create(:label, title: 'billing', account: account) }
  let!(:label2) { create(:label, title: 'technical-support', account: account) }
  let!(:team1) { create(:team, name: 'Support Team', description: 'Handles customer support', account: account) }
  let!(:team2) { create(:team, name: 'Sales Team', description: 'Handles sales inquiries', account: account) }

  let(:labels) { [{ 'id' => label1.id, 'title' => 'billing', 'description' => 'Billing related' }] }
  let(:teams) { [{ 'id' => team1.id, 'name' => 'Support Team', 'description' => 'Handles customer support' }] }

  let(:mock_chat) { double('RubyLLM Chat') }
  let(:mock_response) do
    double('Response', content: {
             'label_id' => label1.id,
             'team_id' => team1.id
           })
  end

  before do
    create_list(:message, 3, conversation: conversation, message_type: :incoming, content: 'Customer message')
  end

  def stub_llm_chain(response_content)
    content_with_indifferent_access = response_content.with_indifferent_access
    response = double('Response', content: content_with_indifferent_access)

    # Mock the schema creation
    mock_schema = double('Schema')
    allow(RubyLLM::Schema).to receive(:create).and_return(mock_schema)

    allow(RubyLLM).to receive(:chat).and_return(mock_chat)
    allow(mock_chat).to receive(:with_model).with('gpt-4o-mini').and_return(mock_chat)
    allow(mock_chat).to receive(:with_temperature).with(0.3).and_return(mock_chat)
    allow(mock_chat).to receive(:with_schema).with(mock_schema).and_return(mock_chat)
    allow(mock_chat).to receive(:ask).and_return(response)

    response
  end

  describe '.run' do
    context 'when both labels and teams are available' do
      it 'returns suggested label and team IDs' do
        stub_llm_chain({ 'label_id' => label1.id, 'team_id' => team1.id })

        result = described_class.run(conversation: conversation, labels: labels, teams: teams)

        expect(result).to eq({ 'label_id' => label1.id, 'team_id' => team1.id })
      end

      it 'calls RubyLLM with correct parameters' do
        stub_llm_chain({ 'label_id' => label1.id, 'team_id' => team1.id })

        described_class.run(conversation: conversation, labels: labels, teams: teams)

        expect(RubyLLM).to have_received(:chat)
        expect(mock_chat).to have_received(:with_model).with('gpt-4o-mini')
        expect(mock_chat).to have_received(:with_temperature).with(0.3)
        expect(mock_chat).to have_received(:with_schema)
      end
    end

    context 'when only labels are available' do
      it 'returns only label_id in suggestion' do
        stub_llm_chain({ 'label_id' => label1.id, 'team_id' => nil })

        result = described_class.run(conversation: conversation, labels: labels, teams: [])

        expect(result).to eq({ 'label_id' => label1.id, 'team_id' => nil })
      end
    end

    context 'when only teams are available' do
      it 'returns only team_id in suggestion' do
        stub_llm_chain({ 'label_id' => nil, 'team_id' => team1.id })

        result = described_class.run(conversation: conversation, labels: [], teams: teams)

        expect(result).to eq({ 'label_id' => nil, 'team_id' => team1.id })
      end
    end

    context 'when both labels and teams are empty' do
      it 'returns nil without calling API' do
        allow(RubyLLM).to receive(:chat)

        result = described_class.run(conversation: conversation, labels: [], teams: [])

        expect(result).to be_nil
        expect(RubyLLM).not_to have_received(:chat)
      end
    end

    context 'when OpenAI returns null for both' do
      it 'returns both as nil' do
        stub_llm_chain({ 'label_id' => nil, 'team_id' => nil })

        result = described_class.run(conversation: conversation, labels: labels, teams: teams)

        expect(result).to eq({ 'label_id' => nil, 'team_id' => nil })
      end
    end

    context 'when API call fails' do
      it 'logs error and returns nil' do
        allow(RubyLLM).to receive(:chat).and_raise(StandardError.new('API Error'))
        expect(Rails.logger).to receive(:error).with(/Agent execution failed/)

        result = described_class.run(conversation: conversation, labels: labels, teams: teams)

        expect(result).to be_nil
      end
    end

    context 'with label descriptions' do
      let(:labels) do
        [
          { 'id' => label1.id, 'title' => 'billing', 'description' => 'Billing and payment issues' },
          { 'id' => label2.id, 'title' => 'technical-support', 'description' => 'Technical problems' }
        ]
      end

      it 'includes descriptions in prompt' do
        stub_llm_chain({ 'label_id' => label1.id, 'team_id' => team1.id })

        described_class.run(conversation: conversation, labels: labels, teams: teams)

        expect(mock_chat).to have_received(:ask) do |prompt|
          expect(prompt).to include('Billing and payment issues')
          expect(prompt).to include('Technical problems')
        end
      end
    end

    context 'with team descriptions' do
      let(:teams) do
        [
          { 'id' => team1.id, 'name' => 'Support Team', 'description' => 'Handles customer support' },
          { 'id' => team2.id, 'name' => 'Sales Team', 'description' => 'Handles sales inquiries' }
        ]
      end

      it 'includes team descriptions in prompt' do
        stub_llm_chain({ 'label_id' => label1.id, 'team_id' => team1.id })

        described_class.run(conversation: conversation, labels: labels, teams: teams)

        expect(mock_chat).to have_received(:ask) do |prompt|
          expect(prompt).to include('Handles customer support')
          expect(prompt).to include('Handles sales inquiries')
        end
      end
    end
  end
end
