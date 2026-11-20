require 'rails_helper'

RSpec.describe Whatsapp::PhoneNumberReleaseService do
  let(:channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false) }
  let(:deregister_url) { %r{graph\.facebook\.com/v[\d.]+/#{channel.provider_config['phone_number_id']}/deregister\z} }
  let(:health_service) { instance_double(Whatsapp::HealthService) }
  let(:health_data) { { is_on_biz_app: false } }

  before do
    allow(Whatsapp::HealthService).to receive(:new).with(channel).and_return(health_service)
    allow(health_service).to receive(:fetch_health_status).and_return(health_data)
  end

  it 'deregisters an embedded signup number that Meta confirms is not on the WhatsApp Business app' do
    stub_request(:post, deregister_url).to_return(status: 200, body: { success: true }.to_json, headers: { 'Content-Type' => 'application/json' })

    described_class.new(channel).perform

    expect(a_request(:post, deregister_url)).to have_been_made.once
  end

  it 'raises when Meta refuses' do
    stub_request(:post, deregister_url).to_return(status: 400, body: { error: { message: 'Not allowed' } }.to_json)

    expect { described_class.new(channel).perform }.to raise_error(CustomExceptions::WhatsappNumberReleaseError) { |error|
      expect(error.message).to eq('Meta could not release the number, so the inbox was not deleted. Please try again.')
    }
  end

  # Meta does not allow deregistering a number that also uses the WhatsApp Business app.
  context 'when the number also uses the WhatsApp Business app' do
    let(:health_data) { { is_on_biz_app: true } }

    it 'refuses without calling deregister' do
      expect { described_class.new(channel).perform }.to raise_error(CustomExceptions::WhatsappNumberReleaseError) { |error|
        expect(error.message).to include('Settings > Account > Business Platform')
      }
      expect(a_request(:post, deregister_url)).not_to have_been_made
    end
  end

  context 'when Meta does not say whether the number uses the WhatsApp Business app' do
    let(:health_data) { { is_on_biz_app: nil } }

    it 'refuses without calling deregister' do
      expect { described_class.new(channel).perform }.to raise_error(CustomExceptions::WhatsappNumberReleaseError)
      expect(a_request(:post, deregister_url)).not_to have_been_made
    end
  end

  it 'refuses without calling deregister when the status check fails' do
    allow(health_service).to receive(:fetch_health_status).and_raise(StandardError, 'timeout')

    expect { described_class.new(channel).perform }.to raise_error(CustomExceptions::WhatsappNumberReleaseError)
    expect(a_request(:post, deregister_url)).not_to have_been_made
  end

  # The customer's own app owns a manual number; releasing it would cut off their integration.
  it 'refuses numbers that were not connected with embedded signup' do
    channel.update!(provider_config: channel.provider_config.merge('source' => 'manual_setup_v2', 'app_secret' => 'secret'))

    expect { described_class.new(channel).perform }.to raise_error(CustomExceptions::WhatsappNumberReleaseError)
    expect(a_request(:post, deregister_url)).not_to have_been_made
  end

  it 'refuses non-WhatsApp channels' do
    expect { described_class.new(create(:channel_widget)).perform }.to raise_error(CustomExceptions::WhatsappNumberReleaseError)
  end
end
