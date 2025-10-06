require 'rails_helper'

RSpec.describe Captain::Tools::HttpTool, type: :model do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:custom_tool) { create(:captain_custom_tool, account: account) }
  let(:tool) { described_class.new(assistant, custom_tool) }
  let(:tool_context) { Struct.new(:state).new({}) }

  describe '#active?' do
    it 'returns true when custom tool is enabled' do
      custom_tool.update!(enabled: true)

      expect(tool.active?).to be true
    end

    it 'returns false when custom tool is disabled' do
      custom_tool.update!(enabled: false)

      expect(tool.active?).to be false
    end
  end

  describe '#perform' do
    context 'with GET request' do
      before do
        custom_tool.update!(
          http_method: 'GET',
          endpoint_url: 'https://example.com/orders/123',
          response_template: nil
        )
        stub_request(:get, 'https://example.com/orders/123')
          .to_return(status: 200, body: '{"status": "success"}')
      end

      it 'executes GET request and returns response body' do
        result = tool.perform(tool_context)

        expect(result).to eq('{"status": "success"}')
        expect(WebMock).to have_requested(:get, 'https://example.com/orders/123')
      end
    end

    context 'with POST request' do
      before do
        custom_tool.update!(
          http_method: 'POST',
          endpoint_url: 'https://example.com/orders',
          request_template: '{"order_id": "{{ order_id }}"}',
          response_template: nil
        )
        stub_request(:post, 'https://example.com/orders')
          .with(body: '{"order_id": "123"}', headers: { 'Content-Type' => 'application/json' })
          .to_return(status: 200, body: '{"created": true}')
      end

      it 'executes POST request with rendered body' do
        result = tool.perform(tool_context, order_id: '123')

        expect(result).to eq('{"created": true}')
        expect(WebMock).to have_requested(:post, 'https://example.com/orders')
          .with(body: '{"order_id": "123"}')
      end
    end

    context 'with template variables in URL' do
      before do
        custom_tool.update!(
          endpoint_url: 'https://example.com/orders/{{ order_id }}',
          response_template: nil
        )
        stub_request(:get, 'https://example.com/orders/456')
          .to_return(status: 200, body: '{"order_id": "456"}')
      end

      it 'renders URL template with params' do
        result = tool.perform(tool_context, order_id: '456')

        expect(result).to eq('{"order_id": "456"}')
        expect(WebMock).to have_requested(:get, 'https://example.com/orders/456')
      end
    end

    context 'with bearer token authentication' do
      before do
        custom_tool.update!(
          auth_type: 'bearer',
          auth_config: { 'token' => 'secret_bearer_token' },
          endpoint_url: 'https://example.com/data',
          response_template: nil
        )
        stub_request(:get, 'https://example.com/data')
          .with(headers: { 'Authorization' => 'Bearer secret_bearer_token' })
          .to_return(status: 200, body: '{"authenticated": true}')
      end

      it 'adds Authorization header with bearer token' do
        result = tool.perform(tool_context)

        expect(result).to eq('{"authenticated": true}')
        expect(WebMock).to have_requested(:get, 'https://example.com/data')
          .with(headers: { 'Authorization' => 'Bearer secret_bearer_token' })
      end
    end

    context 'with basic authentication' do
      before do
        custom_tool.update!(
          auth_type: 'basic',
          auth_config: { 'username' => 'user123', 'password' => 'pass456' },
          endpoint_url: 'https://example.com/data',
          response_template: nil
        )
        stub_request(:get, 'https://example.com/data')
          .with(basic_auth: %w[user123 pass456])
          .to_return(status: 200, body: '{"authenticated": true}')
      end

      it 'adds basic auth credentials' do
        result = tool.perform(tool_context)

        expect(result).to eq('{"authenticated": true}')
        expect(WebMock).to have_requested(:get, 'https://example.com/data')
          .with(basic_auth: %w[user123 pass456])
      end
    end

    context 'with API key authentication' do
      before do
        custom_tool.update!(
          auth_type: 'api_key',
          auth_config: { 'key' => 'api_key_123', 'location' => 'header', 'name' => 'X-API-Key' },
          endpoint_url: 'https://example.com/data',
          response_template: nil
        )
        stub_request(:get, 'https://example.com/data')
          .with(headers: { 'X-API-Key' => 'api_key_123' })
          .to_return(status: 200, body: '{"authenticated": true}')
      end

      it 'adds API key header' do
        result = tool.perform(tool_context)

        expect(result).to eq('{"authenticated": true}')
        expect(WebMock).to have_requested(:get, 'https://example.com/data')
          .with(headers: { 'X-API-Key' => 'api_key_123' })
      end
    end

    context 'with response template' do
      before do
        custom_tool.update!(
          endpoint_url: 'https://example.com/orders/123',
          response_template: 'Order status: {{ response.status }}, ID: {{ response.order_id }}'
        )
        stub_request(:get, 'https://example.com/orders/123')
          .to_return(status: 200, body: '{"status": "shipped", "order_id": "123"}')
      end

      it 'formats response using template' do
        result = tool.perform(tool_context)

        expect(result).to eq('Order status: shipped, ID: 123')
      end
    end

    context 'when handling errors' do
      it 'returns generic error message on network failure' do
        custom_tool.update!(endpoint_url: 'https://example.com/data')
        stub_request(:get, 'https://example.com/data').to_raise(SocketError.new('Failed to connect'))

        result = tool.perform(tool_context)

        expect(result).to eq('An error occurred while executing the request')
      end

      it 'returns generic error message on timeout' do
        custom_tool.update!(endpoint_url: 'https://example.com/data')
        stub_request(:get, 'https://example.com/data').to_timeout

        result = tool.perform(tool_context)

        expect(result).to eq('An error occurred while executing the request')
      end

      it 'returns generic error message on HTTP 404' do
        custom_tool.update!(endpoint_url: 'https://example.com/data')
        stub_request(:get, 'https://example.com/data').to_return(status: 404, body: 'Not found')

        result = tool.perform(tool_context)

        expect(result).to eq('An error occurred while executing the request')
      end

      it 'returns generic error message on HTTP 500' do
        custom_tool.update!(endpoint_url: 'https://example.com/data')
        stub_request(:get, 'https://example.com/data').to_return(status: 500, body: 'Server error')

        result = tool.perform(tool_context)

        expect(result).to eq('An error occurred while executing the request')
      end

      it 'logs error details' do
        custom_tool.update!(endpoint_url: 'https://example.com/data')
        stub_request(:get, 'https://example.com/data').to_raise(StandardError.new('Test error'))

        expect(Rails.logger).to receive(:error).with(/HttpTool execution error.*Test error/)

        tool.perform(tool_context)
      end
    end

    context 'when integrating with Toolable methods' do
      it 'correctly integrates URL rendering, body rendering, auth, and response formatting' do
        custom_tool.update!(
          http_method: 'POST',
          endpoint_url: 'https://example.com/users/{{ user_id }}/orders',
          request_template: '{"product": "{{ product }}", "quantity": {{ quantity }}}',
          auth_type: 'bearer',
          auth_config: { 'token' => 'integration_token' },
          response_template: 'Created order #{{ response.order_number }} for {{ response.product }}'
        )

        stub_request(:post, 'https://example.com/users/42/orders')
          .with(
            body: '{"product": "Widget", "quantity": 5}',
            headers: {
              'Authorization' => 'Bearer integration_token',
              'Content-Type' => 'application/json'
            }
          )
          .to_return(status: 200, body: '{"order_number": "ORD-789", "product": "Widget"}')

        result = tool.perform(tool_context, user_id: '42', product: 'Widget', quantity: 5)

        expect(result).to eq('Created order #ORD-789 for Widget')
      end
    end
  end
end
