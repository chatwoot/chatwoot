require 'rails_helper'

RSpec.describe Whatsapp::PhoneNumberReleaseService do
  let(:channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false) }
  let(:deregister_url) { %r{graph\.facebook\.com/v[\d.]+/#{channel.provider_config['phone_number_id']}/deregister\z} }

  it 'deregisters an embedded signup number' do
    stub_request(:post, deregister_url).to_return(status: 200, body: { success: true }.to_json, headers: { 'Content-Type' => 'application/json' })

    described_class.new(channel).perform

    expect(a_request(:post, deregister_url)).to have_been_made.once
  end

  it "raises with Meta's reason when Meta refuses" do
    stub_request(:post, deregister_url).to_return(
      status: 400, body: { error: { message: 'Phone number is not currently linked' } }.to_json, headers: { 'Content-Type' => 'application/json' }
    )

    expect { described_class.new(channel).perform }.to raise_error(CustomExceptions::WhatsappNumberReleaseError) { |error|
      expect(error.message).to include('Phone number is not currently linked')
    }
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
