require 'rails_helper'

# Contract specs backed by real Click-to-WhatsApp ad payload shapes captured from
# the wild, so a provider serialization change is caught instead of trusting the
# hand-built hashes elsewhere:
# - Baileys externalAdReply field names per the WAProto + EvolutionAPI #1252;
#   mediaType is the numeric proto enum (2 = VIDEO) because our baileys-api
#   forwards the raw Baileys object via JSON.stringify (no enum->string mapping).
#   Other wrappers (EvolutionAPI) emit the string "VIDEO"; both are handled.
# - Cloud referral object per Meta's webhook docs (media_type is a lowercase string).
describe 'WhatsApp Click-to-WhatsApp referral (real payload shapes)' do # rubocop:disable RSpec/DescribeClass
  def load_fixture(name)
    JSON.parse(Rails.root.join('spec/fixtures/files/whatsapp', name).read).with_indifferent_access
  end

  describe 'Baileys externalAdReply (numeric mediaType)' do
    let(:webhook_verify_token) { 'valid_token' }
    let!(:channel) do
      create(:channel_whatsapp, provider: 'baileys', provider_config: { webhook_verify_token: webhook_verify_token },
                                validate_provider_config: false, received_messages: false)
    end

    before do
      stub_request(:get, /profile-picture-url/).to_return(status: 200, body: { data: { profilePictureUrl: nil } }.to_json)
    end

    # Scope the dedupe cleanup to this inbox so it can't wipe keys other specs
    # are using against the same Redis DB.
    after do
      Redis::Alfred.scan_each(match: "MESSAGE_SOURCE_KEY::#{channel.inbox.id}_*") { |key| Redis::Alfred.delete(key) }
    end

    it 'normalizes the real ad payload into referral (message) and entry_point (conversation)' do
      params = load_fixture('baileys_ctwa_ad.json').merge(webhookVerifyToken: webhook_verify_token)

      Whatsapp::IncomingMessageBaileysService.new(inbox: channel.inbox, params: params).perform

      message = channel.inbox.messages.last
      expect(message.content_attributes['referral']).to include(
        'source_type' => 'ad',
        'source_id' => '1120214541917380261',
        'source_url' => 'https://fb.me/criativox',
        'ctwa_clid' => 'AaRDg86i-z5_xrIOfs9Adr1example',
        'title' => 'Agende ja sua Avaliacao',
        'media_type' => 'video',
        'thumbnail_url' => 'https://scontent.xx.fbcdn.net/v/thumb.jpg'
      )
      expect(message.conversation.additional_attributes['entry_point']).to eq('source' => 'ctwa_ad', 'app' => 'facebook')
    end
  end

  describe 'Cloud referral object' do
    let!(:channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false) }

    after do
      Redis::Alfred.scan_each(match: "MESSAGE_SOURCE_KEY::#{channel.inbox.id}_*") { |key| Redis::Alfred.delete(key) }
    end

    it 'normalizes the real referral object into the message and conversation' do
      params = load_fixture('cloud_ctwa_referral.json')

      Whatsapp::IncomingMessageWhatsappCloudService.new(inbox: channel.inbox, params: params).perform

      message = channel.inbox.messages.last
      expect(message.content_attributes['referral']).to include(
        'source_type' => 'ad',
        'source_id' => '1120214541917380261',
        'ctwa_clid' => 'AaRDg86i-z5_xrIOfs9Adr1example',
        'title' => 'Agende ja sua Avaliacao',
        'media_type' => 'video',
        'thumbnail_url' => 'https://scontent.xx.fbcdn.net/v/thumb.jpg'
      )
      expect(message.conversation.additional_attributes['referral']).to include('ctwa_clid' => 'AaRDg86i-z5_xrIOfs9Adr1example')
    end
  end
end
