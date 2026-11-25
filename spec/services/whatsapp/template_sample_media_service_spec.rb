require 'rails_helper'

describe Whatsapp::TemplateSampleMediaService do
  subject(:service) { described_class.new(channel: channel, url: url) }

  let(:channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false) }
  let(:provider) { instance_double(Whatsapp::Providers::WhatsappCloudService) }
  let(:url) { 'https://scontent.whatsapp.net/v/t61.29466-34/sample_n.jpg?oh=01_Q5Aa&oe=6AA7FF50' }

  before do
    stub_request(:get, url).to_return(status: 200, body: 'image data', headers: { 'Content-Type' => 'image/jpeg' })
    allow(channel).to receive(:provider_service).and_return(provider)
    allow(provider).to receive(:upload_media).and_return('media_id')
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
  end

  it 'uploads the downloaded file and returns the media id' do
    expect(service.media_id).to eq('media_id')
    expect(provider).to have_received(:upload_media).with(anything, 'image/jpeg')
  end

  # A campaign sends the same template to every contact; re-uploading it each time would be pure waste.
  it 'uploads only once for repeated sends of the same media' do
    2.times { described_class.new(channel: channel, url: url).media_id }

    expect(provider).to have_received(:upload_media).once
  end

  it 'raises with a readable reason when the media itself is gone' do
    stub_request(:get, url).to_return(status: 404)

    expect { service.media_id }.to raise_error(CustomExceptions::Whatsapp::MediaUploadError, /Could not download/)
  end

  # A blip must stay retryable: MediaUploadError fails the message for good, so only a deterministic
  # rejection may raise it.
  it 'lets a CDN outage propagate so the job can be retried' do
    stub_request(:get, url).to_return(status: 503)

    expect { service.media_id }.to raise_error(Down::ServerError)
  end

  it 'lets a connection timeout propagate so the job can be retried' do
    stub_request(:get, url).to_timeout

    expect { service.media_id }.to raise_error(Down::TimeoutError)
  end

  it 'lets a CDN rate limit propagate so the job can be retried' do
    stub_request(:get, url).to_return(status: 429)

    expect { service.media_id }.to raise_error(Down::ClientError)
  end

  # Reauthorizing an inbox swaps the phone number id while keeping the channel record. A media id minted
  # under the old Cloud account is not addressable by the new one, so it must not be served from cache.
  it 'uploads again after the inbox is reauthorized onto another Cloud account' do
    service.media_id
    channel.provider_config = channel.provider_config.merge('phone_number_id' => 'reauthorized_id')

    described_class.new(channel: channel, url: url).media_id

    expect(provider).to have_received(:upload_media).twice
  end

  # Meta re-signs the handle on every template sync. The file behind it does not change, so a rotated
  # signature must not cost a second upload.
  it 'reuses the upload when only the signature rotated' do
    rotated = 'https://scontent.whatsapp.net/v/t61.29466-34/sample_n.jpg?oh=02_XyZz&oe=6BB80061'
    stub_request(:get, rotated).to_return(status: 200, body: 'image data', headers: { 'Content-Type' => 'image/jpeg' })

    service.media_id
    described_class.new(channel: channel, url: rotated).media_id

    expect(provider).to have_received(:upload_media).once
  end
end
