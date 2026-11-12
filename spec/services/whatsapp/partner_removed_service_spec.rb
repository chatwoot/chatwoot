require 'rails_helper'

RSpec.describe Whatsapp::PartnerRemovedService do
  let(:waba_id) { '980198427658004' }

  # The whatsapp_cloud factory overwrites provider_config on create, so set it afterwards.
  def create_cloud_channel(provider_config)
    channel = create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
    channel.update!(provider_config: provider_config)
    channel
  end

  def embedded_signup_config(waba)
    { 'source' => 'embedded_signup', 'api_key' => 'token', 'phone_number_id' => SecureRandom.hex(4), 'business_account_id' => waba }
  end

  describe '#perform' do
    let!(:first_channel) { create_cloud_channel(embedded_signup_config(waba_id)) }
    let!(:second_channel) { create_cloud_channel(embedded_signup_config(waba_id)) }
    let!(:other_waba_channel) { create_cloud_channel(embedded_signup_config('111111111111111')) }
    let!(:manual_channel) do
      create_cloud_channel({ 'source' => 'manual_setup_v2', 'api_key' => 'own-token', 'phone_number_id' => 'manual-phone',
                             'business_account_id' => waba_id, 'app_secret' => 'secret' })
    end

    it 'prompts reauthorization for every embedded signup channel on the removed WABA' do
      described_class.new(waba_id).perform

      expect(first_channel.reauthorization_required?).to be true
      expect(second_channel.reauthorization_required?).to be true
    end

    it 'emails the account admins once per disconnected inbox' do
      expect { described_class.new(waba_id).perform }
        .to have_enqueued_mail(AdministratorNotifications::ChannelNotificationsMailer, :whatsapp_disconnect).twice
    end

    it 'leaves channels on other WABAs alone' do
      described_class.new(waba_id).perform

      expect(other_waba_channel.reauthorization_required?).to be false
    end

    # A manual channel sends with the customer's own app token, which our partner removal does not revoke.
    it 'leaves manually connected channels on the same WABA alone' do
      described_class.new(waba_id).perform

      expect(manual_channel.reauthorization_required?).to be false
    end

    it 'does not email again for a channel that already needs reauthorization' do
      first_channel.prompt_reauthorization!
      second_channel.prompt_reauthorization!

      expect { described_class.new(waba_id).perform }
        .not_to have_enqueued_mail(AdministratorNotifications::ChannelNotificationsMailer, :whatsapp_disconnect)
    end
  end
end
