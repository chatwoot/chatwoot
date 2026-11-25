require 'rails_helper'

RSpec.describe AccountWhatsappProviders do
  let(:account) { create(:account) }

  it 'stores the toggles in settings, keyed by name' do
    account.update!(whatsapp_native_disabled: true)

    expect(account.reload.settings['whatsapp_native_disabled']).to be(true)
  end

  it 'casts console values, which can arrive as strings' do
    account.update!(whatsapp_uazapi_disabled: '1', whatsapp_native_disabled: '1')

    expect(account.reload.whatsapp_uazapi_disabled).to be(true)
    expect(account.whatsapp_native_disabled).to be(true)
  end

  it 'offers both session providers to an account nobody has touched' do
    expect(account.whatsapp_session_provider_enabled?('uazapi')).to be(true)
    expect(account.whatsapp_session_provider_enabled?('native')).to be(true)
  end

  it 'takes native away from the account it was turned off for, and only that one' do
    account.update!(whatsapp_native_disabled: true)

    expect(account.whatsapp_session_provider_enabled?('native')).to be(false)
    expect(account.whatsapp_session_provider_enabled?('uazapi')).to be(true)
    expect(create(:account).whatsapp_session_provider_enabled?('native')).to be(true)
  end

  it 'takes uazapi away from the account it was turned off for, and leaves native alone' do
    account.update!(whatsapp_uazapi_disabled: true)

    expect(account.whatsapp_session_provider_enabled?('uazapi')).to be(false)
    expect(account.whatsapp_session_provider_enabled?('native')).to be(true)
  end

  it 'offers native again when the switch is turned back off' do
    account.update!(whatsapp_native_disabled: true)
    account.update!(whatsapp_native_disabled: false)

    expect(account.reload.whatsapp_session_provider_enabled?('native')).to be(true)
  end

  # The opt-in that came before this switch is left in the settings of the accounts it was
  # set on, either way. It no longer decides anything, and it must not stop them saving.
  [true, false].each do |old_value|
    it "ignores the old opt-in left at #{old_value} and still saves the account" do
      # written the way the old setter left it, past the accessor that no longer exists
      account.update_column(:settings, account.settings.merge('whatsapp_native_enabled' => old_value)) # rubocop:disable Rails/SkipsModelValidations

      account.reload.update!(name: 'renamed')

      expect(account.whatsapp_session_provider_enabled?('native')).to be(true)
    end
  end

  it 'never enables a provider this layer does not serve' do
    expect(account.whatsapp_session_provider_enabled?('baileys')).to be(false)
  end
end
