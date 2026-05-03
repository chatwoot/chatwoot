require 'rails_helper'

RSpec.describe Whatsapp::TemplateMediaHeaderHandleService do
  describe '#generate' do
    it 'downloads media and returns the Meta resumable upload handle' do
      channel = instance_double(
        Channel::Whatsapp,
        provider_config: {
          'api_key' => 'system-token'
        }
      )
      service = described_class.new(channel)
      file = StringIO.new('png-bytes')

      file.define_singleton_method(:content_type) { 'image/png' }
      allow(file).to receive(:binmode)
      allow(file).to receive(:close)
      allow(GlobalConfigService).to receive(:load).with('WHATSAPP_APP_ID', '').and_return('app-123')
      allow(GlobalConfigService).to receive(:load).with('WHATSAPP_API_VERSION', 'v22.0').and_return('v22.0')
      allow(service).to receive(:download_media)
        .with('https://jusmonitoria.witdev.com.br/jusmonitorialogo.png')
        .and_return(file)

      stub_request(:post, 'https://graph.facebook.com/v22.0/app-123/uploads')
        .with(
          query: {
            file_name: 'jusmonitorialogo.png',
            file_length: '9',
            file_type: 'image/png'
          }
        )
        .to_return(
          status: 200,
          body: { id: 'upload:session-123' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      stub_request(:post, 'https://graph.facebook.com/v22.0/upload:session-123')
        .with(
          headers: {
            'Authorization' => 'OAuth system-token',
            'Content-Type' => 'image/png',
            'File-Offset' => '0'
          },
          body: 'png-bytes'
        )
        .to_return(
          status: 200,
          body: { h: '4::header_handle' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = service.generate(media_url: 'https://jusmonitoria.witdev.com.br/jusmonitorialogo.png')

      expect(result).to include(success: true, header_handle: '4::header_handle')
    end

    it 'falls back to provider config when WHATSAPP_APP_ID installation config is empty' do
      channel = instance_double(
        Channel::Whatsapp,
        provider_config: {
          'api_key' => 'system-token',
          'whatsapp_app_id' => 'provider-app-123'
        }
      )
      service = described_class.new(channel)

      allow(GlobalConfigService).to receive(:load).with('WHATSAPP_APP_ID', '').and_return('')

      expect(service.send(:app_id)).to eq('provider-app-123')
    end
  end
end
