require 'rails_helper'

RSpec.describe Ctwa::CampaignBuilder do
  describe '.build' do
    it 'normalizes a WhatsApp Cloud referral (string keys, media_type)' do
      referral = {
        'source_url' => 'https://fb.me/3TYpooaRT',
        'source_id' => '52558118838064',
        'source_type' => 'ad',
        'headline' => 'Diana Digital',
        'body' => 'washa data tu',
        'media_type' => 'video',
        'ctwa_clid' => 'AfhcQdP2E4A8wWpeb1FqUzUi'
      }

      expect(described_class.build(referral)).to eq(
        'source' => 'meta_ctwa',
        'source_id' => '52558118838064',
        'source_type' => 'ad',
        'source_url' => 'https://fb.me/3TYpooaRT',
        'headline' => 'Diana Digital',
        'body' => 'washa data tu',
        'media_type' => 'video',
        'ctwa_clid' => 'AfhcQdP2E4A8wWpeb1FqUzUi'
      )
    end

    it 'falls back to Twilio media_content_type when media_type is absent' do
      referral = { source_id: '120', media_content_type: 'image/jpeg' }

      expect(described_class.build(referral)).to include('media_type' => 'image/jpeg')
    end

    it 'returns nil when the referral has no source id or click id' do
      expect(described_class.build(headline: 'no ids here')).to be_nil
    end

    it 'returns nil for a blank referral' do
      expect(described_class.build(nil)).to be_nil
      expect(described_class.build({})).to be_nil
    end

    it 'attributes on a click id alone (no source id)' do
      expect(described_class.build(ctwa_clid: 'Afxyz')).to include('source' => 'meta_ctwa', 'ctwa_clid' => 'Afxyz')
    end
  end
end
