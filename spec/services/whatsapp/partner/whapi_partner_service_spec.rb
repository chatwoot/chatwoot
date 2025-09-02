require 'rails_helper'

RSpec.describe Whatsapp::Partner::WhapiPartnerService do
  subject(:service) { described_class.new }

  let(:account) { create(:account) }

  before do
    allow(Current).to receive(:account).and_return(account)
    
    # Make private methods public for testing
    described_class.class_eval do
      public :fetch_projects, :create_channel, :update_channel_webhook, 
             :generate_qr_code, :delete_channel
    end
    
    # Add WebMock stubs for WHAPI partner API endpoints
    stub_request(:get, %r{/projects$})
      .to_return(status: 200, body: '{"projects": []}', headers: { 'Content-Type' => 'application/json' })
      
    stub_request(:put, %r{/channels$})
      .to_return(status: 200, body: '{"id": "test_id", "token": "test_token"}', headers: { 'Content-Type' => 'application/json' })
      
    stub_request(:post, %r{/channels/.*/webhook$})
      .to_return(status: 200, body: '{"success": true}', headers: { 'Content-Type' => 'application/json' })
      
    stub_request(:get, %r{/channels/.*/qr$})
      .to_return(status: 200, body: '{"qr_code": "data:image/png;base64,test"}', headers: { 'Content-Type' => 'application/json' })
      
    stub_request(:delete, %r{/channels/})
      .to_return(status: 200, body: '{"success": true}', headers: { 'Content-Type' => 'application/json' })
  end

  describe '#fetch_projects' do
    it 'returns an array of projects when request succeeds' do
      stub_request(:get, %r{/projects$}).to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: { projects: [{ id: 'proj_1', name: 'Test Project' }] }.to_json
      )

      projects = service.fetch_projects
      expect(projects).to be_an(Array)
      expect(projects.first['id']).to eq('proj_1')
    end

    it 'raises when request fails' do
      stub_request(:get, %r{/projects$}).to_return(status: 500, body: 'boom')
      expect { service.fetch_projects }.to raise_error(StandardError, /fetch_projects failed/)
    end
  end

  describe '#create_channel' do
    it 'returns id and token when successful' do
      stub_request(:put, %r{/channels$}).to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: { id: 'chan_1', token: 'token_1' }.to_json
      )

      resp = service.create_channel(name: 'My Channel', project_id: 'proj_1')
      expect(resp['id']).to eq('chan_1')
      expect(resp['token']).to eq('token_1')
    end

    it 'raises when response is missing id or token' do
      stub_request(:put, %r{/channels$}).to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: { id: 'only_id' }.to_json
      )

      expect do
        service.create_channel(name: 'x', project_id: 'p')
      end.to raise_error(StandardError, /missing id or token/)
    end

    it 'raises when request fails' do
      stub_request(:put, %r{/channels$}).to_return(status: 400, body: 'bad')
      expect do
        service.create_channel(name: 'x', project_id: 'p')
      end.to raise_error(StandardError, /create_channel failed/)
    end
  end

  describe '#update_channel_webhook' do
    it 'returns parsed response on success' do
      stub_request(:patch, %r{/settings$}).to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: { ok: true }.to_json
      )

      resp = service.update_channel_webhook(channel_token: 'chan_token', webhook_url: 'https://example.com/hook')
      expect(resp).to include('ok' => true)
    end

    it 'raises when request fails' do
      stub_request(:patch, %r{/settings$}).to_return(status: 401, body: 'unauth')
      expect do
        service.update_channel_webhook(channel_token: 'chan_token', webhook_url: 'https://example.com/hook')
      end.to raise_error(StandardError, /update_channel_webhook failed/)
    end
  end

  describe '#generate_qr_code' do
    it 'parses JSON response with base64 field' do
      stub_request(:get, %r{/users/login$}).to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: { qr: 'BASE64DATA', expires_in: 30 }.to_json
      )

      result = service.generate_qr_code(channel_token: 'chan_token')
      expect(result['image_base64']).to eq('BASE64DATA')
      expect(result['expires_in']).to eq(30)
    end

    it 'encodes image body when content-type is image' do
      stub_request(:get, %r{/users/login$}).to_return(
        status: 200,
        headers: { 'Content-Type' => 'image/png' },
        body: 'PNG_BYTES'
      )

      result = service.generate_qr_code(channel_token: 'chan_token')
      expect(result['image_base64']).to eq(Base64.strict_encode64('PNG_BYTES'))
    end

    it 'raises on non-success response' do
      stub_request(:get, %r{/users/login$}).to_return(status: 500, body: 'oops')
      expect { service.generate_qr_code(channel_token: 'x') }.to raise_error(StandardError, /generate_qr_code failed/)
    end
  end

  describe '#delete_channel' do
    it 'returns true on success' do
      stub_request(:delete, %r{/channels/chan_1$}).to_return(status: 200, body: '')
      expect(service.delete_channel(channel_id: 'chan_1')).to eq(true)
    end

    it 'raises when request fails' do
      stub_request(:delete, %r{/channels/chan_1$}).to_return(status: 404, body: 'not found')
      expect { service.delete_channel(channel_id: 'chan_1') }.to raise_error(StandardError, /delete_channel failed/)
    end
  end

  describe 'rate limiting' do
    before do
      # Clear any existing rate limit counters
      Redis::Alfred.delete("whapi_external_api:fetch_projects:#{account.id}")
      Redis::Alfred.delete("whapi_external_api:create_channel:#{account.id}")
      Redis::Alfred.delete("whapi_external_api:delete_channel:#{account.id}")
      Redis::Alfred.delete("whapi_external_api:generate_qr_code:#{account.id}")
    end

    it 'enforces rate limits for fetch_projects' do
      stub_request(:get, %r{/projects$}).to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: { projects: [] }.to_json
      )

      # Make requests up to the limit
      30.times { service.fetch_projects }

      # The 31st request should be rate limited
      expect { service.fetch_projects }.to raise_error(CustomExceptions::RateLimitExceeded, /Rate limit exceeded for fetch_projects/)
    end

    it 'enforces rate limits for create_channel' do
      stub_request(:put, %r{/channels$}).to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: { id: 'chan_1', token: 'token_1' }.to_json
      )

      # Make requests up to the limit
      20.times { service.create_channel(name: 'Test Channel', project_id: 'proj_1') }

      # The 21st request should be rate limited
      expect { service.create_channel(name: 'Test Channel', project_id: 'proj_1') }.to raise_error(CustomExceptions::RateLimitExceeded, /Rate limit exceeded for create_channel/)
    end

    it 'enforces rate limits for delete_channel' do
      stub_request(:delete, %r{/channels/chan_1$}).to_return(status: 200, body: '')

      # Make requests up to the limit
      10.times { service.delete_channel(channel_id: 'chan_1') }

      # The 11th request should be rate limited
      expect { service.delete_channel(channel_id: 'chan_1') }.to raise_error(CustomExceptions::RateLimitExceeded, /Rate limit exceeded for delete_channel/)
    end

    it 'enforces rate limits for generate_qr_code' do
      stub_request(:get, %r{/users/login$}).to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: { qr: 'BASE64DATA', expires_in: 30 }.to_json
      )

      # Make requests up to the limit
      50.times { service.generate_qr_code(channel_token: 'chan_token') }

      # The 51st request should be rate limited (wrapped in StandardError by retry mechanism)
      expect { service.generate_qr_code(channel_token: 'chan_token') }.to raise_error(StandardError, /Rate limit exceeded for generate_qr_code/)
    end

    it 'does not rate limit when Current.account is nil' do
      allow(Current).to receive(:account).and_return(nil)
      stub_request(:get, %r{/projects$}).to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: { projects: [] }.to_json
      )

      # Should not raise rate limit exception when no account context
      expect { service.fetch_projects }.not_to raise_error
    end
  end
end


