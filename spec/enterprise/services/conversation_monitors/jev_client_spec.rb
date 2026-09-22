require 'rails_helper'

RSpec.describe ConversationMonitors::JevClient do
  subject(:evaluate) { client.evaluate(state: state, monitors: [monitor]) }

  let(:account) { create(:account) }
  let(:monitor) { create(:conversation_monitor, account: account) }
  let(:client) { described_class.new(account_id: account.id) }
  let(:state) { { messages: [{ speaker: 'customer', text: 'Please refund this charge.' }], truncated: false } }
  let!(:api_key) { create(:installation_config, name: 'CAPTAIN_OPENROUTER_API_KEY', value: 'openrouter-test-key') }
  let(:endpoint) { ConversationMonitors::Configuration::ENDPOINT }
  let(:response_body) do
    { id: 'gen-test', model: 'typesafe/jev-1.13-20260917', provider: 'TypeSafe',
      answers: { monitor.id.to_s => { type: 'noul', noul: 0.9 } }, usage: { input_tokens: 100, output_tokens: 10, cost: 0.00003 } }
  end

  before do
    stub_request(:post, endpoint).with(headers: { 'Authorization' => 'Bearer openrouter-test-key' })
                                 .to_return(status: 200, body: response_body.to_json)
  end

  it 'uses the shared installation credential and the OpenRouter System One contract' do
    result = evaluate

    expect(WebMock).to have_requested(:post, endpoint).with { |request|
      body = JSON.parse(request.body)
      body['model'] == 'typesafe/jev-1.13' && body['state'] == state.as_json &&
        body['questions'][monitor.id.to_s]['type'] == 'noul' &&
        body['questions'][monitor.id.to_s].dig('instructions', 'condition') == monitor.condition
    }.once
    expect(result).to include('model' => 'typesafe/jev-1.13-20260917', 'provider' => 'TypeSafe')
    expect(described_class.score(result['answers'][monitor.id.to_s])).to eq(0.9)
    expect(ConversationMonitors::Usage.new(account.id).snapshot[:used]).to eq(1)
    expect(ConversationMonitors::Configuration.model).to eq('typesafe/jev-1.13')
  end

  it 'translates existing monitor model IDs without changing their definition or historical results' do
    legacy_monitor = create(:conversation_monitor, account: account, model: 'jev-1.13.0')

    client.evaluate(state: state, monitors: [legacy_monitor])

    expect(WebMock).to have_requested(:post, endpoint).with { |request| JSON.parse(request.body)['model'] == 'typesafe/jev-1.13' }.once
    expect(legacy_monitor.reload.model).to eq('jev-1.13.0')
  end

  it 'reads changed credentials and endpoint from installation settings for subsequent calls' do
    evaluate
    custom_endpoint = 'https://openrouter.ai/api/alpha/decisions'
    api_key.update!(value: 'rotated-test-key')
    create(:installation_config, name: 'CAPTAIN_OPENROUTER_DECISION_MODEL_ENDPOINT', value: custom_endpoint)
    custom_request = stub_request(:post, custom_endpoint).with(headers: { 'Authorization' => 'Bearer rotated-test-key' })
                                                         .to_return(status: 200, body: response_body.to_json)

    client.evaluate(state: state, monitors: [monitor])

    expect(custom_request).to have_been_requested.once
    expect(WebMock).to have_requested(:post, endpoint).once
  end

  it 'does not use the old TypeSafe credential or consume credits when OpenRouter is not configured' do
    api_key.destroy!

    with_modified_env(TYPESAFE_API_KEY: 'old-typesafe-key') do
      expect { evaluate }.to raise_error(CustomExceptions::MonitorEvaluationError, 'not_configured')
    end

    expect(WebMock).not_to have_requested(:post, endpoint)
    expect(ConversationMonitors::DailyUsage.where(account: account)).not_to exist
  end

  it 'keeps provider credit exhaustion distinct from the account monthly allowance' do
    stub_request(:post, endpoint).to_return(status: 402)

    expect { evaluate }.to raise_error(CustomExceptions::MonitorEvaluationError) { |error|
      expect(error.code).to eq('provider_credits_exhausted')
      expect(error).not_to be_retryable
    }
    expect(ConversationMonitors::Usage.new(account.id).snapshot).to include(used: 1, limit_reached: false)
  end

  [400, 404, 422].each do |status|
    it "does not repeatedly retry a rejected model or request (#{status})" do
      stub_request(:post, endpoint).to_return(status: status)

      expect { evaluate }.to raise_error(CustomExceptions::MonitorEvaluationError) { |error|
        expect(error.code).to eq('invalid_request')
        expect(error).not_to be_retryable
      }
    end
  end

  it 'rejects malformed provider usage instead of accepting the classification' do
    stub_request(:post, endpoint).to_return(status: 200, body: response_body.merge(usage: { cost: 0.01 }).to_json)

    expect { evaluate }.to raise_error(CustomExceptions::MonitorEvaluationError, 'invalid_response')
  end
end
