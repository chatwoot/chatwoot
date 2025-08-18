require 'rails_helper'

RSpec.describe Whatsapp::Partner::WhapiPartnerService do
  subject(:service) { described_class.new }

  describe '#fetch_projects' do
    it 'returns an array of projects when request succeeds' do
      stub_request(:get, /\/projects$/).to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: { projects: [{ id: 'proj_1', name: 'Test Project' }] }.to_json
      )

      projects = service.fetch_projects
      expect(projects).to be_an(Array)
      expect(projects.first['id']).to eq('proj_1')
    end

    it 'raises when request fails' do
      stub_request(:get, /\/projects$/).to_return(status: 500, body: 'boom')
      expect { service.fetch_projects }.to raise_error(StandardError, /fetch_projects failed/)
    end
  end

  describe '#create_channel' do
    it 'returns id and token when successful' do
      stub_request(:put, /\/channels$/).to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: { id: 'chan_1', token: 'token_1' }.to_json
      )

      resp = service.create_channel(name: 'My Channel', project_id: 'proj_1')
      expect(resp['id']).to eq('chan_1')
      expect(resp['token']).to eq('token_1')
    end

    it 'raises when response is missing id or token' do
      stub_request(:put, /\/channels$/).to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: { id: 'only_id' }.to_json
      )

      expect do
        service.create_channel(name: 'x', project_id: 'p')
      end.to raise_error(StandardError, /missing id or token/)
    end

    it 'raises when request fails' do
      stub_request(:put, /\/channels$/).to_return(status: 400, body: 'bad')
      expect do
        service.create_channel(name: 'x', project_id: 'p')
      end.to raise_error(StandardError, /create_channel failed/)
    end
  end

  describe '#update_channel_webhook' do
    it 'returns parsed response on success' do
      stub_request(:patch, /\/settings$/).to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: { ok: true }.to_json
      )

      resp = service.update_channel_webhook(channel_token: 'chan_token', webhook_url: 'https://example.com/hook')
      expect(resp).to include('ok' => true)
    end

    it 'raises when request fails' do
      stub_request(:patch, /\/settings$/).to_return(status: 401, body: 'unauth')
      expect do
        service.update_channel_webhook(channel_token: 'chan_token', webhook_url: 'https://example.com/hook')
      end.to raise_error(StandardError, /update_channel_webhook failed/)
    end
  end

  describe '#generate_qr_code' do
    it 'parses JSON response with base64 field' do
      stub_request(:get, /\/users\/login$/).to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: { qr: 'BASE64DATA', expires_in: 30 }.to_json
      )

      result = service.generate_qr_code(channel_token: 'chan_token')
      expect(result['image_base64']).to eq('BASE64DATA')
      expect(result['expires_in']).to eq(30)
    end

    it 'encodes image body when content-type is image' do
      stub_request(:get, /\/users\/login$/).to_return(
        status: 200,
        headers: { 'Content-Type' => 'image/png' },
        body: 'PNG_BYTES'
      )

      result = service.generate_qr_code(channel_token: 'chan_token')
      expect(result['image_base64']).to eq(Base64.strict_encode64('PNG_BYTES'))
    end

    it 'raises on non-success response' do
      stub_request(:get, /\/users\/login$/).to_return(status: 500, body: 'oops')
      expect { service.generate_qr_code(channel_token: 'x') }.to raise_error(StandardError, /generate_qr_code failed/)
    end
  end

  describe '#delete_channel' do
    it 'returns true on success' do
      stub_request(:delete, /\/channels\/chan_1$/).to_return(status: 200, body: '')
      expect(service.delete_channel(channel_id: 'chan_1')).to eq(true)
    end

    it 'raises when request fails' do
      stub_request(:delete, /\/channels\/chan_1$/).to_return(status: 404, body: 'not found')
      expect { service.delete_channel(channel_id: 'chan_1') }.to raise_error(StandardError, /delete_channel failed/)
    end
  end
end


