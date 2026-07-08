require 'rails_helper'

RSpec.describe Crm::FollowUps::ParamsResolver do
  def contact_with(zone)
    Struct.new(:additional_attributes).new({ 'timezone' => zone })
  end

  def build(attributes:, card_contact: nil, account_tz: nil)
    card = Struct.new(:contact).new(card_contact)
    account = Struct.new(:reporting_timezone).new(account_tz)
    described_class.new(account: account, user: nil, card: card, conversation: nil, attributes: attributes)
  end

  it 'honors the explicit timezone' do
    resolver = build(attributes: { timezone: 'America/Sao_Paulo' }, account_tz: 'UTC')
    expect(resolver.send(:resolved_timezone)).to eq('America/Sao_Paulo')
  end

  it 'falls back to the contact timezone' do
    resolver = build(attributes: {}, card_contact: contact_with('America/Sao_Paulo'), account_tz: 'UTC')
    expect(resolver.send(:resolved_timezone)).to eq('America/Sao_Paulo')
  end

  it 'falls back to the account timezone' do
    resolver = build(attributes: {}, account_tz: 'America/Sao_Paulo')
    expect(resolver.send(:resolved_timezone)).to eq('America/Sao_Paulo')
  end

  it 'raises when no timezone can be resolved' do
    resolver = build(attributes: {})
    expect { resolver.send(:resolved_timezone) }.to raise_error(Crm::Timezone::Resolver::Unresolvable)
  end
end
