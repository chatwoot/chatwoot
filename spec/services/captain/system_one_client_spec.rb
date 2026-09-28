require 'rails_helper'

RSpec.describe Captain::SystemOneClient do
  let(:endpoint) { 'https://openrouter.example/v1/systemone' }
  let(:state) { { conversation: { messages: [{ sender: 'customer', text: 'I want a refund' }] } } }
  let(:questions) { { 'refund' => { type: 'noul', instructions: 'Is the customer asking for a refund?' } } }

  before do
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load).with('CAPTAIN_OPENROUTER_DECISION_MODEL_ENDPOINT', nil).and_return('https://openrouter.example')
    allow(GlobalConfigService).to receive(:load).with('CAPTAIN_OPENROUTER_API_KEY', nil).and_return('secret-key')
  end

  it 'posts the state and questions to Jev and returns the answers' do
    stub = stub_request(:post, endpoint)
           .with(
             headers: { 'Authorization' => 'Bearer secret-key', 'Content-Type' => 'application/json' },
             body: { model: 'jev-latest', state: state, questions: questions }.to_json
           )
           .to_return(status: 200, body: { answers: { 'refund' => { 'noul' => 0.91 } } }.to_json,
                      headers: { 'Content-Type' => 'application/json' })

    answers = described_class.new.ask(state: state, questions: questions)

    expect(stub).to have_been_requested
    expect(answers).to eq('refund' => { 'noul' => 0.91 })
  end

  it 'raises when Jev does not answer successfully' do
    stub_request(:post, endpoint).to_return(status: 401, body: 'invalid key')

    expect { described_class.new.ask(state: state, questions: questions) }
      .to raise_error(described_class::Error, /401/)
  end

  it 'raises its own error when Jev cannot be reached' do
    stub_request(:post, endpoint).to_timeout

    expect { described_class.new.ask(state: state, questions: questions) }
      .to raise_error(described_class::Error, /Net::OpenTimeout/)
  end

  it 'raises its own error when the response has no answers' do
    stub_request(:post, endpoint).to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

    expect { described_class.new.ask(state: state, questions: questions) }
      .to raise_error(described_class::Error, /invalid response/)
  end

  it 'raises its own error when the response is not an object' do
    stub_request(:post, endpoint).to_return(status: 200, body: [].to_json, headers: { 'Content-Type' => 'application/json' })

    expect { described_class.new.ask(state: state, questions: questions) }
      .to raise_error(described_class::Error, /invalid response/)
  end

  it 'raises its own error when the answers are not an object' do
    stub_request(:post, endpoint).to_return(status: 200, body: { answers: [] }.to_json, headers: { 'Content-Type' => 'application/json' })

    expect { described_class.new.ask(state: state, questions: questions) }
      .to raise_error(described_class::Error, /invalid response/)
  end

  it 'raises its own error when the response cannot be parsed' do
    stub_request(:post, endpoint).to_return(status: 200, body: 'not json', headers: { 'Content-Type' => 'application/json' })

    expect { described_class.new.ask(state: state, questions: questions) }
      .to raise_error(described_class::Error, /invalid response/)
  end
end
