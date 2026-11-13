require 'rails_helper'

RSpec.describe Instagram::LoginConfiguration do
  before do
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load).with('INSTAGRAM_LOGIN_METHOD', nil).and_return(nil)
    allow(GlobalConfigService).to receive(:load).with('INSTAGRAM_CONFIGURATION_ID', nil).and_return('config1')
  end

  it 'defaults to Instagram Login even when a configuration ID is saved' do
    expect(described_class.login_method).to eq('instagram_login')
    expect(described_class.configuration_id).to be_nil
  end

  it 'preserves Instagram Login for installations without a configuration ID' do
    allow(GlobalConfigService).to receive(:load).with('INSTAGRAM_CONFIGURATION_ID', nil).and_return(nil)
    expect(described_class.login_method).to eq('instagram_login')
  end

  it 'uses the selected Instagram Login credentials even when Unified Login credentials remain saved' do
    allow(GlobalConfigService).to receive(:load).with('INSTAGRAM_LOGIN_METHOD', nil).and_return('instagram_login')
    allow(GlobalConfigService).to receive(:load).with('INSTAGRAM_APP_ID', '').and_return('instagram-app')
    expect(described_class.configuration_id).to be_nil
    expect(described_class.app_id).to eq('instagram-app')
  end

  it 'uses the Unified Login app ID when selected' do
    allow(GlobalConfigService).to receive(:load).with('INSTAGRAM_LOGIN_METHOD', nil).and_return('unified_login')
    allow(GlobalConfigService).to receive(:load).with('INSTAGRAM_UNIFIED_APP_ID', '').and_return('meta-app')
    expect(described_class.app_id).to eq('meta-app')
  end

  it 'rejects Unified Login with a missing configuration ID instead of falling back to Instagram Login' do
    allow(GlobalConfigService).to receive(:load).with('INSTAGRAM_LOGIN_METHOD', nil).and_return('unified_login')
    allow(GlobalConfigService).to receive(:load).with('INSTAGRAM_CONFIGURATION_ID', nil).and_return(nil)
    expect { described_class.configuration_id }.to raise_error(Instagram::UnifiedLoginService::Error, I18n.t('instagram.missing_credentials'))
  end
end
