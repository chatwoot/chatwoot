require 'rails_helper'

RSpec.describe Whatsapp::DisplayNameService do
  let(:channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false) }
  let(:phone_id) { channel.provider_config.fetch('phone_number_id') }
  let(:health) do
    { status: 'CONNECTED', is_on_biz_app: false, verified_name: 'Mona', name_status: 'DECLINED',
      new_display_name: 'Mona Assistant', new_name_status: 'APPROVED', official_business_account: { 'oba_status' => 'NOT_STARTED' } }
  end
  let(:health_service) { instance_double(Whatsapp::HealthService, fetch_health_status: health) }
  let(:registration_url) { %r{https://graph.facebook.com/v[\d.]+/#{phone_id}/register} }
  let(:service) { described_class.new(channel) }

  before do
    channel.provider_config['verification_pin'] = '012345'
    channel.save!(validate: false)
    allow(Whatsapp::HealthService).to receive(:new).with(channel).and_return(health_service)
  end

  it 'applies the approved replacement using the stored PIN without changing webhook configuration' do
    original_config = channel.provider_config.deep_dup
    registration = stub_request(:post, registration_url)
                   .with(body: { messaging_product: 'whatsapp', pin: '012345' }.to_json)
                   .to_return(status: 200, body: { success: true }.to_json, headers: { 'Content-Type' => 'application/json' })

    service.perform(display_name: 'Mona Assistant')

    expect(registration).to have_been_requested.once
    expect(channel.reload.provider_config).to eq(original_config)
  end

  ['PENDING_REVIEW', 'DECLINED', 'EXPIRED', 'NONE', nil].each do |status|
    it "rejects a replacement with status #{status.inspect} before registration" do
      health[:new_name_status] = status
      expect { service.perform(display_name: 'Mona Assistant') }.to raise_error(ArgumentError, /no longer approved/)
      expect(a_request(:post, registration_url)).not_to have_been_made
    end
  end

  it 'rejects a different approved name rather than applying an unseen replacement' do
    health[:new_display_name] = 'Another name'
    expect { service.perform(display_name: 'Mona Assistant') }.to raise_error(ArgumentError, /has changed/)
  end

  [true, nil].each do |coexistence|
    it "does not register when coexistence is #{coexistence.inspect}" do
      health[:is_on_biz_app] = coexistence
      expect { service.perform(display_name: 'Mona Assistant') }.to raise_error(ArgumentError, /WhatsApp Business app/)
    end
  end

  it 'does not register a disconnected number' do
    health[:status] = 'DISCONNECTED'
    expect { service.perform(display_name: 'Mona Assistant') }.to raise_error(ArgumentError, /connected/)
  end

  ['APPROVED', 'PENDING', 'REJECTED', 'UNKNOWN', nil].each do |oba_status|
    it "does not register when OBA status is #{oba_status.inspect}, even with a stored PIN" do
      health[:official_business_account] = { 'oba_status' => oba_status }
      expect { service.perform(display_name: 'Mona Assistant') }.to raise_error(ArgumentError, /OBA status/)
      expect(a_request(:post, registration_url)).not_to have_been_made
    end
  end

  it 'does not register when Meta omits OBA information' do
    health.delete(:official_business_account)
    expect { service.perform(display_name: 'Mona Assistant') }.to raise_error(ArgumentError, /OBA status/)
    expect(a_request(:post, registration_url)).not_to have_been_made
  end

  it 'surfaces provider rejection without reporting a successful registration' do
    stub_request(:post, registration_url).to_return(status: 400, body: { error: { message: 'Incorrect PIN' } }.to_json)
    expect { service.perform(display_name: 'Mona Assistant') }.to raise_error(/Incorrect PIN/)
  end

  it 'rejects an unsuccessful response even with HTTP 200' do
    stub_request(:post, registration_url)
      .to_return(status: 200, body: { success: false }.to_json, headers: { 'Content-Type' => 'application/json' })
    expect { service.perform(display_name: 'Mona Assistant') }.to raise_error(ArgumentError, /did not accept/)
  end

  context 'without a stored PIN' do
    before do
      channel.provider_config.delete('verification_pin')
      channel.save!(validate: false)
    end

    it 'generates and stores a PIN only when Meta explicitly reports PIN verification disabled' do
      stub_request(:get, %r{https://graph.facebook.com/v[\d.]+/#{phone_id}\?fields=is_pin_enabled})
        .to_return(status: 200, body: { is_pin_enabled: false }.to_json, headers: { 'Content-Type' => 'application/json' })
      allow(SecureRandom).to receive(:random_number).with(900_000).and_return(123_456)
      registration = stub_request(:post, registration_url)
                     .with(body: { messaging_product: 'whatsapp', pin: '223456' }.to_json)
                     .to_return(status: 200, body: { success: true }.to_json, headers: { 'Content-Type' => 'application/json' })

      service.perform(display_name: 'Mona Assistant')

      expect(registration).to have_been_requested.once
      expect(channel.reload.provider_config['verification_pin']).to eq('223456')
    end

    it 'applies an approved name when PIN deprecation leaves a residual enabled status' do
      health.merge!(verified_name: 'Example IT Support', name_status: 'APPROVED', new_display_name: 'Example')
      original_config = channel.provider_config.deep_dup
      stub_request(:get, %r{https://graph.facebook.com/v[\d.]+/#{phone_id}\?fields=is_pin_enabled})
        .to_return(status: 200, body: { is_pin_enabled: true }.to_json, headers: { 'Content-Type' => 'application/json' })
      registration = stub_request(:post, registration_url)
                     .with { |request| JSON.parse(request.body)['pin'].match?(/\A\d{6}\z/) }
                     .to_return(status: 200, body: { success: true }.to_json, headers: { 'Content-Type' => 'application/json' })

      service.perform(display_name: 'Example')

      expect(registration).to have_been_requested.once
      expect(channel.reload.provider_config).to eq(original_config)
    end

    it 'surfaces a legacy PIN rejection without retrying or storing the generated parameter' do
      stub_request(:get, %r{https://graph.facebook.com/v[\d.]+/#{phone_id}\?fields=is_pin_enabled})
        .to_return(status: 200, body: { is_pin_enabled: true }.to_json, headers: { 'Content-Type' => 'application/json' })
      registration = stub_request(:post, registration_url)
                     .to_return(status: 400, body: { error: { message: 'Incorrect PIN', code: 133_005 } }.to_json)

      expect { service.perform(display_name: 'Mona Assistant') }.to raise_error(/Incorrect PIN/)
      expect(registration).to have_been_requested.once
      expect(channel.reload.provider_config).not_to have_key('verification_pin')
    end

    it 'does not register when Meta omits the PIN status' do
      stub_request(:get, %r{https://graph.facebook.com/v[\d.]+/#{phone_id}\?fields=is_pin_enabled})
        .to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      expect { service.perform(display_name: 'Mona Assistant') }.to raise_error(ArgumentError, /two-step verification status/)
      expect(a_request(:post, registration_url)).not_to have_been_made
    end
  end
end
