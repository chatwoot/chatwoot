require 'rails_helper'

RSpec.describe Ctwa::TrackedLinkClick do
  let(:account) { create(:account) }
  let(:channel) do
    create(:channel_whatsapp, account: account, phone_number: '+15551234567', provider: 'whatsapp_cloud', validate_provider_config: false,
                              sync_templates: false)
  end
  let(:tracked_link) { create(:ctwa_tracked_link, account: account, inbox: channel.inbox) }

  describe 'validations' do
    it 'generates a valid 8-character token and default expiry on create' do
      travel_to(Time.zone.parse('2026-07-10 12:00:00 UTC')) do
        click = described_class.create!(account: account, tracked_link: tracked_link, params: { gclid: 'gclid-123' })

        expect(click.token).to match(/\A[A-Z2-9]{8}\z/)
        expect(click.expires_at).to eq(72.hours.from_now)
      end
    end

    it 'requires a globally unique token' do
      described_class.create!(account: account, tracked_link: tracked_link, token: 'ABCD2345', params: { gclid: 'gclid-123' })

      duplicate = described_class.new(account: account, tracked_link: tracked_link, token: 'ABCD2345', params: { gclid: 'other' })

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:token]).to be_present
    end

    it 'requires the token format to be 8 uppercase alphanumeric characters' do
      click = described_class.new(account: account, tracked_link: tracked_link, token: 'abc12345', params: { gclid: 'gclid-123' })

      expect(click).not_to be_valid
      expect(click.errors[:token]).to be_present
    end

    it 'normalizes params to scalar string tracking values only' do
      long_value = 'A' * 600

      click = described_class.create!(
        account: account,
        tracked_link: tracked_link,
        params: {
          gclid: 'gclid-123',
          fbclid: nil,
          ttclid: { value: 'nested' },
          utm_source: ['array'],
          utm_medium: '',
          utm_campaign: '   ',
          utm_content: long_value,
          ignored: 'drop-me'
        }
      )

      expect(click.params).to eq('gclid' => 'gclid-123', 'utm_content' => 'A' * 512)
    end

    it 'requires params to be a hash' do
      click = described_class.new(account: account, tracked_link: tracked_link, params: 'not-a-hash')

      expect(click).not_to be_valid
      expect(click.errors[:params]).to be_present
    end

    it 'truncates user agent to 255 characters' do
      click = described_class.create!(account: account, tracked_link: tracked_link, params: { gclid: 'gclid-123' }, user_agent: 'A' * 300)

      expect(click.user_agent.length).to eq(255)
    end
  end

  describe '.active' do
    it 'includes unconsumed, unexpired clicks' do
      click = described_class.create!(account: account, tracked_link: tracked_link, params: { gclid: 'gclid-123' })

      expect(described_class.active).to include(click)
    end

    it 'excludes expired clicks' do
      click = described_class.create!(
        account: account,
        tracked_link: tracked_link,
        params: { gclid: 'gclid-123' },
        expires_at: 1.minute.ago
      )

      expect(described_class.active).not_to include(click)
    end

    it 'excludes consumed clicks' do
      conversation = create(:conversation, account: account, inbox: channel.inbox)
      click = described_class.create!(
        account: account,
        tracked_link: tracked_link,
        params: { gclid: 'gclid-123' },
        conversation: conversation
      )

      expect(described_class.active).not_to include(click)
    end
  end
end
