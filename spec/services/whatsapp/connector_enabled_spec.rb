require 'rails_helper'

# The native channel is on unless an installation says otherwise, and the switch is read in
# five places that cannot share a constant (the database config and an initializer run
# before the app autoloads). Each reader is held to the same rule here: only `false` turns
# it off.
RSpec.describe 'WHATSAPP_CONNECTOR_ENABLED' do
  def pool(env)
    with_modified_env({ 'RAILS_MAX_THREADS' => '5', 'WHATSAPP_CONNECTOR_EVENT_SHARDS' => '16',
                        'WHATSAPP_CONNECTOR_CONSUMER' => nil }.merge(env)) do
      YAML.safe_load(ERB.new(Rails.root.join('config/database.yml').read).result, aliases: true)['default']['pool']
    end
  end

  def descriptor
    Whatsapp::Session::ProviderDescriptor.new(key: 'native', backend: 'Whatsapp::Session::Backends::Fake')
  end

  {
    'unset' => [nil, true],
    'empty' => ['', true],
    'true' => ['true', true],
    'false' => ['false', false]
  }.each do |label, (value, on)|
    context "when #{label}" do
      it "#{on ? 'turns' : 'leaves'} the integration #{on ? 'on' : 'off'}" do
        with_modified_env WHATSAPP_CONNECTOR_ENABLED: value do
          expect(Whatsapp::Connector.enabled?).to be(on)
          expect(descriptor.available?).to be(on)
        end
      end

      it "#{on ? 'reserves' : 'does not reserve'} room in the pool for the event consumer" do
        expect(pool('WHATSAPP_CONNECTOR_ENABLED' => value)).to eq(on ? 21 : 5)
      end
    end
  end

  # A sixth reader written the old way would turn the channel off where the rest call it on.
  it 'is read with the same default everywhere' do
    readers = %w[app config lib docker].flat_map { |dir| Dir[Rails.root.join(dir, '**', '*.{rb,yml,sh}')] }
    old_default = /WHATSAPP_CONNECTOR_ENABLED['"]?,\s*['"]false|WHATSAPP_CONNECTOR_ENABLED"?\s*=\s*"true"/
    offenders = readers.select { |path| File.read(path).match?(old_default) }

    expect(offenders.map { |path| Pathname(path).relative_path_from(Rails.root).to_s }).to be_empty
  end
end
