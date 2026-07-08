require 'rails_helper'

RSpec.describe Crm::Timezone::Resolver do
  def contact_with(zone)
    Struct.new(:additional_attributes).new({ 'timezone' => zone })
  end

  def account_with(zone)
    Struct.new(:reporting_timezone).new(zone)
  end

  describe '#name' do
    it 'prefers the explicit timezone over contact and account' do
      resolver = described_class.new(
        explicit: 'America/Sao_Paulo',
        contact: contact_with('Europe/Lisbon'),
        account: account_with('UTC')
      )
      expect(resolver.name).to eq('America/Sao_Paulo')
    end

    it 'falls back to the contact timezone when explicit is blank' do
      resolver = described_class.new(contact: contact_with('America/Sao_Paulo'), account: account_with('UTC'))
      expect(resolver.name).to eq('America/Sao_Paulo')
    end

    it 'falls back to the account timezone when explicit and contact are blank' do
      resolver = described_class.new(account: account_with('America/Sao_Paulo'))
      expect(resolver.name).to eq('America/Sao_Paulo')
    end

    it 'skips an invalid explicit and uses the next valid candidate' do
      resolver = described_class.new(explicit: 'Not/AZone', account: account_with('America/Sao_Paulo'))
      expect(resolver.name).to eq('America/Sao_Paulo')
    end

    it 'returns nil when every candidate is missing or invalid' do
      resolver = described_class.new(explicit: 'Not/AZone', contact: contact_with(nil), account: account_with('also bad'))
      expect(resolver.name).to be_nil
    end
  end

  describe '#name! and #zone!' do
    it 'raises Unresolvable when nothing resolves' do
      resolver = described_class.new
      expect { resolver.name! }.to raise_error(described_class::Unresolvable)
      expect { resolver.zone! }.to raise_error(described_class::Unresolvable)
    end
  end

  describe '#zone' do
    it 'anchors 08:00 local America/Sao_Paulo to 11:00 UTC (NOT 08:00)' do
      resolver = described_class.new(explicit: 'America/Sao_Paulo')
      utc = resolver.zone.parse('2026-07-08 08:00:00').utc
      expect(utc.hour).to eq(11)
    end

    it 'returns nil when unresolvable' do
      expect(described_class.new.zone).to be_nil
    end
  end
end
