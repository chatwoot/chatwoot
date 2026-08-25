require 'rails_helper'

RSpec.describe Email::SenderNameBuilder do
  let(:account) { create(:account, locale: :en) }
  let(:sender) { create(:user, account: account, ui_settings: { 'locale' => 'de' }) }
  let(:builder) do
    described_class.new(
      account: account,
      sender: sender,
      sender_email: 'care@example.com',
      sender_name: 'Ivan',
      business_name: 'Juvigo'
    )
  end

  it 'uses the user locale for the display name' do
    expect(builder.build).to eq('Ivan von Juvigo <care@example.com>')
  end

  it 'keeps the supplied email address authoritative for every supported locale' do
    I18n.available_locales.each do |locale|
      sender.update!(ui_settings: { 'locale' => locale.to_s })

      expect(Mail::Address.new(builder.build).address).to eq('care@example.com')
    end
  end

  it 'does not apply an address prefix from the localized template' do
    sender.update!(ui_settings: { 'locale' => 'sk' })

    expect(builder.build).to eq('Ivan z Juvigo <care@example.com>')
  end

  it 'falls back to the account locale when the user locale is invalid' do
    account.update!(locale: :de)
    sender.update!(ui_settings: { 'locale' => 'not-a-locale' })

    expect(builder.build).to eq('Ivan von Juvigo <care@example.com>')
  end

  context 'with production-style locale fallbacks' do
    around do |example|
      original_backend = I18n.backend
      original_fallbacks = I18n.fallbacks
      fallback_backend = I18n::Backend::Simple.new
      fallback_backend.extend(I18n::Backend::Fallbacks)
      I18n.backend = fallback_backend
      I18n.fallbacks = I18n::Locale::Fallbacks.new(I18n.default_locale)

      example.run
    ensure
      I18n.backend = original_backend
      I18n.fallbacks = original_fallbacks
    end

    it 'falls back to the account locale when the sender name translation is missing' do
      account.update!(locale: :de)
      sender.update!(ui_settings: { 'locale' => 'sr' })

      expect(builder.build).to eq('Ivan von Juvigo <care@example.com>')
    end
  end

  it 'falls back to the account locale when the sender is not a user' do
    account.update!(locale: :de)
    builder = described_class.new(
      account: account,
      sender: create(:agent_bot, account: account),
      sender_email: 'care@example.com',
      sender_name: 'Ivan',
      business_name: 'Juvigo'
    )

    expect(builder.build).to eq('Ivan von Juvigo <care@example.com>')
  end
end
