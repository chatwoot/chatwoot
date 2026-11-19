require 'rails_helper'

describe Channel::Whatsapp do
  let(:account) { create(:account) }
  let(:channel) do
    create(:channel_whatsapp, provider: 'whatsapp_cloud', account: account, validate_provider_config: false, sync_templates: false)
  end

  before { account.enable_features!('channel_voice') }

  def save_provider_config(changes)
    channel.provider_config = channel.provider_config.merge(changes)
    channel.save!(validate: false)
  end

  # The routing validation and the template callback share one prepended hook
  it 'still rejects routing settings outside the values the inbox accepts' do
    channel.provider_config = channel.provider_config.merge('ring_step_seconds' => 5)

    expect(channel).not_to be_valid
    expect(channel.errors[:base]).to include(I18n.t('inbox.call_routing.invalid_settings', step_min: 10, step_max: 60, cooldown_max: 600))
  end

  describe 'the call permission template' do
    it 'is created once calling is turned on' do
      expect { save_provider_config('calling_enabled' => true) }
        .to have_enqueued_job(Whatsapp::CreateCallPermissionTemplateJob).with(channel)
    end

    it 'is created again when the permission request message changes' do
      save_provider_config('calling_enabled' => true, 'call_permission_template_name' => channel.call_permission_template.name)

      expect { save_provider_config('call_permission_request_body' => 'Can we call you?') }
        .to have_enqueued_job(Whatsapp::CreateCallPermissionTemplateJob)
    end

    it 'is left alone while calling is off, or once it exists' do
      expect { save_provider_config('call_permission_request_body' => 'Can we call you?') }
        .not_to have_enqueued_job(Whatsapp::CreateCallPermissionTemplateJob)

      save_provider_config('calling_enabled' => true, 'call_permission_template_name' => channel.call_permission_template.name)
      expect { channel.update!(phone_number: channel.phone_number) }.not_to have_enqueued_job(Whatsapp::CreateCallPermissionTemplateJob)
    end
  end

  describe Whatsapp::CreateCallPermissionTemplateJob do
    let(:provider_service) do
      instance_double(Whatsapp::Providers::WhatsappCloudService, call_permission_template_exists?: false, create_call_permission_template: true)
    end

    before { allow(Whatsapp::Providers::WhatsappCloudService).to receive(:new).and_return(provider_service) }

    it 'creates the template for a number with calling on' do
      channel.update_columns(provider_config: channel.provider_config.merge('calling_enabled' => true)) # rubocop:disable Rails/SkipsModelValidations

      described_class.perform_now(channel.reload)

      expect(provider_service).to have_received(:create_call_permission_template)
      expect(channel.reload.call_permission_template).to be_created
    end

    it 'does nothing once calling is turned off' do
      described_class.perform_now(channel)

      expect(provider_service).not_to have_received(:create_call_permission_template)
    end
  end
end
