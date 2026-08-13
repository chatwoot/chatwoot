require 'rails_helper'

RSpec.describe Enterprise::AuditLog do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }

  describe 'ip lookup enqueue' do
    it 'enqueues the lookup job on create when remote_address is present' do
      expect do
        described_class.create!(auditable: inbox, action: 'update', associated: account, remote_address: '8.8.8.8')
      end.to have_enqueued_job(Enterprise::AuditLogIpLookupJob)
    end

    it 'does not enqueue the lookup job when remote_address is blank' do
      expect do
        described_class.create!(auditable: inbox, action: 'update', associated: account)
      end.not_to have_enqueued_job(Enterprise::AuditLogIpLookupJob)
    end
  end

  describe '#location' do
    it 'joins city and country' do
      audit = described_class.new(city: 'Berlin', country: 'Germany')
      expect(audit.location).to eq('Berlin, Germany')
    end

    it 'returns the present part when one is missing' do
      expect(described_class.new(country: 'Germany').location).to eq('Germany')
    end

    it 'returns nil when both are missing' do
      expect(described_class.new.location).to be_nil
    end

    it 'ignores blank parts instead of leaving a trailing separator' do
      expect(described_class.new(city: 'London', country: '').location).to eq('London')
      expect(described_class.new(city: '', country: '').location).to be_nil
    end
  end

  describe '#masked_remote_address' do
    it 'masks the last octet of an IPv4 address' do
      expect(described_class.new(remote_address: '203.0.113.42').masked_remote_address).to eq('203.0.113.x')
    end

    it 'keeps the first four hextets of an IPv6 address' do
      audit = described_class.new(remote_address: '2001:0db8:85a3:0000:0000:8a2e:0370:7334')
      expect(audit.masked_remote_address).to eq('2001:0db8:85a3:0000::')
    end

    it 'expands a compressed IPv6 address before masking so host bits do not leak' do
      masked = described_class.new(remote_address: '2001:db8::1').masked_remote_address
      expect(masked).to eq('2001:0db8:0000:0000::')
      expect(masked).not_to include('::1')
    end

    it 'returns nil for a blank address' do
      expect(described_class.new(remote_address: nil).masked_remote_address).to be_nil
    end

    it 'returns nil for a malformed address' do
      expect(described_class.new(remote_address: 'not-an-ip').masked_remote_address).to be_nil
    end
  end
end
