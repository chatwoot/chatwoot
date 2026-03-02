# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Agent::ToolRunner do
  let(:account) { create(:account) }
  let(:ai_agent) { create(:ai_agent, :tool_calling, account: account) }
  let(:conversation) { create(:conversation, account: account) }

  let!(:http_tool) do
    create(:agent_tool, :with_auth,
           ai_agent: ai_agent,
           name: 'get_order',
           url_template: 'https://api.store.com/orders/{{order_id}}',
           http_method: 'GET')
  end

  subject(:runner) { described_class.new(ai_agent: ai_agent, conversation: conversation) }

  describe '#run' do
    context 'with handoff tool' do
      it 'hands off the conversation to a human' do
        tool_call = { 'function' => { 'name' => 'handoff_to_human', 'arguments' => '{"reason": "Complex issue"}' } }
        result = runner.run(tool_call)

        expect(result.handoff?).to be true
        expect(result.content).to include('Complex issue')
      end

      it 'creates an activity message on the conversation' do
        tool_call = { 'function' => { 'name' => 'handoff_to_human', 'arguments' => '{"reason": "Needs help"}' } }

        expect { runner.run(tool_call) }.to change { conversation.messages.activity.count }.by(1)
      end
    end

    context 'with unknown tool' do
      it 'returns an error result' do
        tool_call = { 'function' => { 'name' => 'nonexistent_tool', 'arguments' => '{}' } }
        result = runner.run(tool_call)

        expect(result.content).to include('Unknown tool')
        expect(result.handoff?).to be false
      end
    end

    context 'with HTTP tool' do
      before do
        allow(Resolv).to receive(:getaddresses).with('api.store.com').and_return(['93.184.216.34'])
      end

      it 'makes an HTTP request and returns the response' do
        stub_request(:get, 'https://api.store.com/orders/123')
          .to_return(status: 200, body: '{"order_id": "123", "status": "shipped"}', headers: { 'Content-Type' => 'application/json' })

        tool_call = { 'function' => { 'name' => 'get_order', 'arguments' => '{"order_id": "123"}' } }
        result = runner.run(tool_call)

        expect(result.content).to include('shipped')
        expect(result.handoff?).to be false
      end
    end

    context 'with SSRF protection' do
      let!(:ssrf_tool) do
        # Build without validation to bypass the model-level URL check
        tool = build(:agent_tool, ai_agent: ai_agent, name: 'ssrf_attack',
                                  url_template: 'http://169.254.169.254/latest/meta-data/')
        tool.save(validate: false)
        tool
      end

      it 'blocks requests to cloud metadata endpoints' do
        tool_call = { 'function' => { 'name' => 'ssrf_attack', 'arguments' => '{}' } }
        result = runner.run(tool_call)

        expect(result.content).to include('Blocked')
        expect(result.handoff?).to be false
      end

      it 'blocks requests to private IPs via DNS rebinding' do
        tool = build(:agent_tool, ai_agent: ai_agent, name: 'dns_rebind',
                                  url_template: 'https://evil.attacker.com/steal')
        tool.save(validate: false)

        allow(Resolv).to receive(:getaddresses).with('evil.attacker.com').and_return(['10.0.0.1'])

        tool_call = { 'function' => { 'name' => 'dns_rebind', 'arguments' => '{}' } }
        result = runner.run(tool_call)

        expect(result.content).to include('Blocked')
      end
    end

    context 'with HTTP errors' do
      before do
        allow(Resolv).to receive(:getaddresses).with('api.store.com').and_return(['93.184.216.34'])
      end

      it 'returns a tool error on network failure' do
        stub_request(:get, 'https://api.store.com/orders/999')
          .to_raise(Errno::ECONNREFUSED)

        tool_call = { 'function' => { 'name' => 'get_order', 'arguments' => '{"order_id": "999"}' } }
        result = runner.run(tool_call)

        expect(result.content).to include('Tool error')
      end
    end

    context 'with long responses' do
      before do
        allow(Resolv).to receive(:getaddresses).with('api.store.com').and_return(['93.184.216.34'])
      end

      it 'truncates response bodies to 4000 characters' do
        long_body = 'x' * 5000
        stub_request(:get, 'https://api.store.com/orders/1')
          .to_return(status: 200, body: long_body)

        tool_call = { 'function' => { 'name' => 'get_order', 'arguments' => '{"order_id": "1"}' } }
        result = runner.run(tool_call)

        expect(result.content.length).to be <= 4003 # 4000 + "..."
      end
    end
  end
end
