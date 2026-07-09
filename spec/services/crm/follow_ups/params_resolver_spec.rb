require 'rails_helper'

RSpec.describe Crm::FollowUps::ParamsResolver do
  def contact_with(additional: nil, country_code: nil)
    Struct.new(:additional_attributes).new({ 'timezone' => additional, 'country_code' => country_code })
  end

  def build(attributes:, card_contact: nil, account_tz: nil)
    card = Struct.new(:contact).new(card_contact)
    account = Struct.new(:reporting_timezone).new(account_tz)
    described_class.new(account: account, user: nil, card: card, conversation: nil, attributes: attributes)
  end

  # Reason: an explicit tz on the follow-up payload must win over the account tz.
  it 'honors the explicit timezone' do
    resolver = build(attributes: { timezone: 'America/Sao_Paulo' }, account_tz: 'UTC')
    expect(resolver.send(:resolved_timezone)).to eq('America/Sao_Paulo')
  end

  # Reason: with no explicit tz the contact's stored tz is the next authority.
  it 'falls back to the contact timezone' do
    resolver = build(attributes: {}, card_contact: contact_with(additional: 'America/Sao_Paulo'), account_tz: 'UTC')
    expect(resolver.send(:resolved_timezone)).to eq('America/Sao_Paulo')
  end

  # Reason: a single-timezone country pins the lead's local time ahead of the
  # account default (foreigner correctness for the manual follow-up path).
  it 'derives a single-timezone country from the contact (FR -> Europe/Paris)' do
    resolver = build(attributes: {}, card_contact: contact_with(country_code: 'FR'), account_tz: 'UTC')
    expect(resolver.send(:resolved_timezone)).to eq('Europe/Paris')
  end

  # Reason: with only the account tz set, it resolves.
  it 'falls back to the account timezone' do
    resolver = build(attributes: {}, account_tz: 'America/Sao_Paulo')
    expect(resolver.send(:resolved_timezone)).to eq('America/Sao_Paulo')
  end

  # Reason (CHANGED from fail-closed): when NOTHING resolves the follow-up must
  # still get a real local wall time via the São Paulo default instead of raising
  # Unresolvable — a missing tz can no longer block creating a manual follow-up.
  it 'defaults to America/Sao_Paulo when no timezone can be resolved' do
    resolver = build(attributes: {})
    expect(resolver.send(:resolved_timezone)).to eq('America/Sao_Paulo')
  end

  # Reason: the fallback is configurable via CRM_DEFAULT_TIMEZONE (fallback only,
  # never overriding a real candidate).
  it 'uses a configured CRM_DEFAULT_TIMEZONE as the fallback when nothing resolves' do
    with_modified_env(CRM_DEFAULT_TIMEZONE: 'Europe/Lisbon') do
      resolver = build(attributes: {})
      expect(resolver.send(:resolved_timezone)).to eq('Europe/Lisbon')
    end
  end
end
