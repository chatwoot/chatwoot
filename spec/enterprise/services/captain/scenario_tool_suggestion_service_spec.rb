require 'rails_helper'

RSpec.describe Captain::ScenarioToolSuggestionService do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let!(:custom_tool) { create(:captain_custom_tool, account: account, assistant: assistant, title: 'Get Order History') }
  let(:instruction) do
    'Check their order history, then add a private note with the details. ' \
      'Finally [@Handoff to Human](tool://handoff) when they ask to hand off.'
  end
  let(:service) { described_class.new(assistant: assistant, instruction: instruction) }

  before do
    InstallationConfig.where(name: 'CAPTAIN_OPEN_AI_API_KEY').destroy_all
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    allow(account).to receive(:feature_enabled?).and_call_original
    allow(account).to receive(:feature_enabled?).with('captain_integration').and_return(true)
    allow(assistant).to receive(:account).and_return(account)
  end

  it 'sends the instruction with the built-in and custom tools of the assistant' do
    allow(service).to receive(:make_api_call).and_return(message: { 'suggestions' => [] })

    service.perform

    expect(service).to have_received(:make_api_call) do |args|
      expect(args[:feature]).to eq('scenario_tool_suggestion')
      payload = JSON.parse(args[:messages].last[:content])
      expect(payload['instructions']).to eq(instruction)
      expect(payload['available_tools'].pluck('id')).to include('add_private_note', 'handoff', custom_tool.slug)
    end
  end

  it 'keeps only suggestions for existing, unlinked tools whose phrase appears verbatim outside tool links' do
    allow(service).to receive(:make_api_call).and_return(
      message: {
        'suggestions' => [
          { 'phrase' => 'Check their order history', 'tool_id' => custom_tool.slug },
          { 'phrase' => 'add a private note', 'tool_id' => 'add_private_note' },
          { 'phrase' => 'add a private note', 'tool_id' => 'add_private_note' },
          { 'phrase' => 'hand off', 'tool_id' => 'handoff' },
          { 'phrase' => 'Handoff to Human', 'tool_id' => 'update_priority' },
          { 'phrase' => 'resolve the conversation', 'tool_id' => 'resolve_conversation' },
          { 'phrase' => 'with the details', 'tool_id' => 'refund_order' }
        ]
      }
    )

    expect(service.perform).to eq(
      suggestions: [
        {
          tool_id: custom_tool.slug,
          tool_title: 'Get Order History',
          phrase: 'Check their order history',
          replacement: "Check their order history [@Get Order History](tool://#{custom_tool.slug})"
        },
        {
          tool_id: 'add_private_note',
          tool_title: 'Add Private Note',
          phrase: 'add a private note',
          replacement: 'add a private note [@Add Private Note](tool://add_private_note)'
        }
      ]
    )
  end

  context 'when the phrase appears more than once outside tool links' do
    let(:instruction) { 'Do not add a private note for VIP customers. For everyone else, add a private note with the order number.' }

    it 'drops the suggestion, because the editor could link the wrong occurrence' do
      allow(service).to receive(:make_api_call).and_return(
        message: { 'suggestions' => [{ 'phrase' => 'add a private note', 'tool_id' => 'add_private_note' }] }
      )

      expect(service.perform).to eq(suggestions: [])
    end
  end

  it 'returns the error when the model call fails, without debiting Captain responses' do
    allow(service).to receive(:make_api_call).and_return(error: 'LLM timeout', error_code: 500)
    allow(account).to receive(:increment_response_usage)

    expect(service.perform).to eq(error: 'LLM timeout', error_code: 500)
    expect(account).not_to have_received(:increment_response_usage)
  end
end
