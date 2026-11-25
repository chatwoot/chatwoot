require 'rails_helper'

RSpec.describe Whatsapp::Session::Registry do
  it 'describes every provider the channel accepts' do
    expect(Channel::Whatsapp::PROVIDERS - described_class::DESCRIPTORS.keys).to be_empty
  end

  it 'serves only the new session providers' do
    expect(described_class.session_provider?('native')).to be(true)
    expect(described_class.session_provider?('uazapi')).to be(true)
    expect(described_class.session_provider?('baileys')).to be(false)
    expect(described_class.session_provider?('whatsapp_cloud')).to be(false)
  end

  # The descriptor is what the dashboard reads to decide whether to offer a feature, so
  # a capability missing here silently disables something the provider can actually do.
  it 'credits the cloud provider with the typing and read-receipt calls it implements' do
    expect(described_class.descriptor('whatsapp_cloud').capabilities).to include('typing', 'read_receipts')
    expect(Whatsapp::Providers::WhatsappCloudService.instance_methods).to include(:toggle_typing_status, :read_messages)
  end

  it 'does not credit 360dialog with them, since it implements neither' do
    expect(described_class.descriptor('default').capabilities).not_to include('typing', 'read_receipts')
  end

  it 'describes the legacy providers without serving them' do
    expect(described_class.descriptor('baileys')).to have_attributes(legacy: true, family: 'session')
    expect(described_class.descriptor('baileys').served?).to be(false)
  end

  # The badge follows the descriptor, so this is what decides whether the picker warns the
  # admin. The native connector left the beta with its 1.0.0, uazapi is still in it, and the
  # frozen providers were never in one.
  it 'marks only uazapi as beta' do
    beta = described_class.descriptors.select(&:beta?).map(&:key)

    expect(beta).to contain_exactly('uazapi')
  end

  # The settings page leaves a secret input empty and never saves an empty one, so a secret
  # proxy could be set but neither seen nor taken away again.
  it 'offers the native proxy as a masked field the settings page can clear' do
    proxy = described_class.descriptor('native').fields.find { |field| field.name == 'proxy_url' }

    expect(proxy).to have_attributes(type: 'password', required: false, secret: false)
  end

  it 'reports a provider as unavailable while its backend class is missing' do
    descriptor = Whatsapp::Session::ProviderDescriptor.new(key: 'uazapi', backend: 'Whatsapp::Session::Backends::NotShippedYet')

    expect(descriptor.available?).to be(false)
  end

  # The connector publishes the phone's history and pages it back on request, so the
  # native inbox offers both, with the same setting the other history providers show.
  it 'declares history on native, with the setting that decides the archive' do
    native = described_class.descriptor('native')

    expect(native.capabilities).to include('history_sync', 'groups', 'media_download', 'calls', 'code_pairing')
    expect(native.fields.map(&:name)).to include('history_sync')
    expect(described_class.descriptor('uazapi').capabilities).to include('history_sync')
  end

  it 'requires a deployed connector before native can be used' do
    descriptor = Whatsapp::Session::ProviderDescriptor.new(key: 'native', backend: 'Whatsapp::Session::Backends::Fake')

    with_modified_env WHATSAPP_CONNECTOR_ENABLED: 'false' do
      expect(descriptor.available?).to be(false)
    end
    with_modified_env WHATSAPP_CONNECTOR_ENABLED: 'true' do
      expect(descriptor.available?).to be(true)
    end
  end

  describe '.capabilities_for' do
    let(:channel) { create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false) }

    it 'drops the group capabilities when the instance turned groups off' do
      with_modified_env WHATSAPP_GROUPS_ENABLED: 'false', BAILEYS_WHATSAPP_GROUPS_ENABLED: 'false' do
        expect(described_class.capabilities_for(channel)).not_to include('groups', 'group_admin')
      end
    end

    it 'keeps them when groups are enabled' do
      with_modified_env WHATSAPP_GROUPS_ENABLED: 'true' do
        expect(described_class.capabilities_for(channel)).to include('groups', 'group_admin')
      end
    end

    it 'still honours the Baileys-era variable name' do
      with_modified_env BAILEYS_WHATSAPP_GROUPS_ENABLED: 'true' do
        expect(described_class.groups_enabled?).to be(true)
      end
    end

    # A compose file listing the variable with no value, or a blank field in a panel,
    # sets it to the empty string. Read as a value it takes the fallback away and the
    # deployment loses every group capability on upgrade, silently.
    it 'reads the new name left blank as not set at all' do
      with_modified_env WHATSAPP_GROUPS_ENABLED: '', BAILEYS_WHATSAPP_GROUPS_ENABLED: 'true' do
        expect(described_class.groups_enabled?).to be(true)
      end
    end

    # Two readers of one switch is how an inbox ends up advertising `groups` in its
    # capabilities while refusing to create one.
    it 'is the same answer the legacy service gives' do
      with_modified_env WHATSAPP_GROUPS_ENABLED: 'true', BAILEYS_WHATSAPP_GROUPS_ENABLED: nil do
        expect(Whatsapp::Providers::WhatsappBaileysService.groups_enabled?).to be(true)
      end

      with_modified_env WHATSAPP_GROUPS_ENABLED: 'false', BAILEYS_WHATSAPP_GROUPS_ENABLED: 'true' do
        expect(Whatsapp::Providers::WhatsappBaileysService.groups_enabled?).to be(false)
      end
    end
  end

  it 'refuses to build a backend for a provider it does not serve' do
    channel = create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false)

    expect { described_class.backend_for(channel) }.to raise_error(Whatsapp::Session::Errors::InvalidConfig)
  end
end
