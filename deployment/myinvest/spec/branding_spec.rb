require 'rails_helper'
require Rails.root.join('deployment/myinvest/bootstrap/lib/branding')

# rubocop:disable RSpec/SpecFilePathFormat
RSpec.describe Myinvest::Branding do
  expected_config = {
    'INSTALLATION_NAME' => 'MyInvest Support',
    'BRAND_NAME' => 'MyInvest Support',
    'BRAND_URL' => 'https://www.myinvest-pro.de',
    'WIDGET_BRAND_URL' => 'https://www.myinvest-pro.de',
    'TERMS_URL' => 'https://www.myinvest-pro.de/agb',
    'PRIVACY_URL' => 'https://www.myinvest-pro.de/datenschutz',
    'LOGO' => '/brand-assets/logo.svg',
    'LOGO_DARK' => '/brand-assets/logo_dark.svg',
    'LOGO_THUMBNAIL' => '/brand-assets/logo_thumbnail.png',
    'DISPLAY_MANIFEST' => false
  }.freeze

  before do
    InstallationConfig.unscoped.where(name: expected_config.keys).delete_all
  end

  it 'creates the complete locked branding configuration' do
    described_class.apply!

    configs = InstallationConfig.unscoped.where(name: expected_config.keys).index_by(&:name)
    expect(configs.transform_values(&:value)).to eq(expected_config)
    expect(configs.values).to all(be_locked)
  end

  it 'overwrites stale values and locks editable branding configuration' do
    expected_config.each_key do |name|
      InstallationConfig.create!(name: name, value: 'stale', locked: false)
    end

    described_class.apply!

    configs = InstallationConfig.unscoped.where(name: expected_config.keys).index_by(&:name)
    expect(configs.transform_values(&:value)).to eq(expected_config)
    expect(configs.values).to all(be_locked)
  end

  it 'does not write already-correct configuration' do
    described_class.apply!
    timestamps = InstallationConfig.unscoped.where(name: expected_config.keys).pluck(:name, :updated_at).to_h

    travel 1.second do
      described_class.apply!
    end

    expect(InstallationConfig.unscoped.where(name: expected_config.keys).pluck(:name, :updated_at).to_h).to eq(timestamps)
  end

  it 'leaves unrelated installation configuration unchanged' do
    unrelated = InstallationConfig.create!(name: 'UNRELATED_BRANDING_SPEC_CONFIG', value: 'keep-me', locked: false)

    described_class.apply!

    expect(unrelated.reload).to have_attributes(value: 'keep-me', locked: false)
  end

  it 'keeps the mounted premium configuration overlay aligned with the database values' do
    overlay_path = Rails.root.join('deployment/myinvest/chatwoot-config/premium_installation_config.yml')
    overlay = YAML.safe_load_file(overlay_path).index_by { |entry| entry.fetch('name') }

    expect(overlay.transform_values { |entry| entry.fetch('value') }).to eq(expected_config)
    expect(overlay.values).to all(include('locked' => true))
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
