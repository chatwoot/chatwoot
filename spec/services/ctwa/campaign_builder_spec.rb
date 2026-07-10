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

    it 'attributes organic Meta referrals without a click id' do
      referral = {
        source_id: 'organic-post-123',
        source_type: 'post',
        source_url: 'https://fb.me/post',
        headline: 'Post orgânico'
      }

      expect(described_class.build(referral)).to include(
        'source' => 'meta_organic',
        'source_id' => 'organic-post-123',
        'source_type' => 'post',
        'source_url' => 'https://fb.me/post',
        'headline' => 'Post orgânico'
      )
    end

    it 'classifies paid click ids by source' do
      expect(described_class.build(source_id: 'google-click', gclid: 'gclid-123')).to include('source' => 'google_ads')
      expect(described_class.build(source_id: 'tiktok-click', ttclid: 'ttclid-123')).to include('source' => 'tiktok_ads')
      expect(described_class.build(source_id: 'meta-click', fbclid: 'fbclid-123')).to include('source' => 'meta_paid')
    end

    it 'keeps Meta ad referrals without a click id as CTWA' do
      expect(described_class.build(source_id: 'ad-123', source_type: 'ad')).to include('source' => 'meta_ctwa')
    end

    it 'classifies tracked link and bridge referrals as tracked links without paid click ids' do
      expect(described_class.build(source_id: 'link:ABC234', source_type: 'tracked_link')).to include('source' => 'tracked_link')
      expect(described_class.build(source_id: 'click:ABCD2345', source_type: 'bridge')).to include('source' => 'tracked_link')
    end

    it 'passes through attribution bridge keys' do
      referral = {
        source_id: 'click:ABCD2345',
        source_type: 'bridge',
        gclid: 'gclid-123',
        fbclid: 'fbclid-123',
        ttclid: 'ttclid-123',
        utm_source: 'google',
        utm_medium: 'cpc',
        utm_campaign: 'july',
        inferred: true
      }

      expect(described_class.build(referral)).to include(
        'gclid' => 'gclid-123',
        'fbclid' => 'fbclid-123',
        'ttclid' => 'ttclid-123',
        'utm_source' => 'google',
        'utm_medium' => 'cpc',
        'utm_campaign' => 'july',
        'inferred' => true
      )
    end
  end

  describe '.attribute!' do
    let(:conversation) { create(:conversation) }
    let(:iso8601_utc) { /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/ }

    let(:first_referral) do
      {
        'source_url' => 'https://fb.me/3TYpooaRT',
        'source_id' => '52558118838064',
        'source_type' => 'ad',
        'headline' => 'Diana Digital',
        'body' => 'washa data tu',
        'media_type' => 'video',
        'ctwa_clid' => 'AfhcQdP2E4A8wWpeb1FqUzUi'
      }
    end

    let(:second_referral) do
      {
        'source_url' => 'https://fb.me/other',
        'source_id' => '120252613195760416',
        'source_type' => 'ad',
        'headline' => 'Outro Anúncio',
        'body' => 'segundo clique',
        'media_type' => 'image',
        'ctwa_clid' => 'AfSECONDCLICKID'
      }
    end

    let(:organic_referral) do
      {
        'source_url' => 'https://fb.me/post',
        'source_id' => 'organic-post-123',
        'source_type' => 'post',
        'headline' => 'Post orgânico',
        'body' => 'conteúdo orgânico',
        'media_type' => 'image'
      }
    end

    it 'records the first touch as origin, slim touch and mirror in a single write' do
      described_class.attribute!(conversation, first_referral)

      attrs = conversation.reload.additional_attributes
      expect(attrs['campaign']).to include(
        'source' => 'meta_ctwa',
        'source_id' => '52558118838064',
        'headline' => 'Diana Digital',
        'body' => 'washa data tu',
        'ctwa_clid' => 'AfhcQdP2E4A8wWpeb1FqUzUi'
      )
      expect(attrs['campaign']['touched_at']).to match(iso8601_utc)
      expect(attrs['campaign_touches'].length).to eq(1)
      expect(attrs['campaign_touches'].first).not_to have_key('body')
      expect(attrs['campaign_touches'].first).to include(
        'source' => 'meta_ctwa',
        'source_id' => '52558118838064',
        'headline' => 'Diana Digital',
        'ctwa_clid' => 'AfhcQdP2E4A8wWpeb1FqUzUi'
      )
      expect(attrs['campaign_touches'].first['touched_at']).to match(iso8601_utc)
      expect(attrs['campaign_source_ids']).to eq(['52558118838064'])
    end

    it 'records an organic referral as origin, touch and mirror entry' do
      described_class.attribute!(conversation, organic_referral)

      attrs = conversation.reload.additional_attributes
      expect(attrs['campaign']).to include(
        'source' => 'meta_organic',
        'source_id' => 'organic-post-123',
        'source_type' => 'post',
        'headline' => 'Post orgânico',
        'body' => 'conteúdo orgânico'
      )
      expect(attrs['campaign_touches'].length).to eq(1)
      expect(attrs['campaign_touches'].first).not_to have_key('body')
      expect(attrs['campaign_touches'].first).to include(
        'source' => 'meta_organic',
        'source_id' => 'organic-post-123',
        'source_type' => 'post',
        'headline' => 'Post orgânico'
      )
      expect(attrs['campaign_source_ids']).to eq(['organic-post-123'])
    end

    it 'appends a second touch with a new click id and keeps the origin untouched' do
      described_class.attribute!(conversation, first_referral)
      described_class.attribute!(conversation, second_referral)

      attrs = conversation.reload.additional_attributes
      expect(attrs['campaign']['source_id']).to eq('52558118838064')
      expect(attrs['campaign_touches'].map { |touch| touch['ctwa_clid'] })
        .to eq(%w[AfhcQdP2E4A8wWpeb1FqUzUi AfSECONDCLICKID])
      expect(attrs['campaign_touches'].last).not_to have_key('body')
      expect(attrs['campaign_source_ids']).to eq(%w[52558118838064 120252613195760416])
    end

    it 'is a no-op when the same click id is redelivered' do
      described_class.attribute!(conversation, first_referral)
      described_class.attribute!(conversation, first_referral.merge('body' => 'redelivered payload'))

      attrs = conversation.reload.additional_attributes
      expect(attrs['campaign_touches'].length).to eq(1)
      expect(attrs['campaign']['body']).to eq('washa data tu')
    end

    it 'dedups an organic redelivery by source id' do
      described_class.attribute!(conversation, organic_referral)
      described_class.attribute!(conversation, organic_referral.merge('body' => 'redelivered payload'))

      attrs = conversation.reload.additional_attributes
      expect(attrs['campaign_touches'].length).to eq(1)
      expect(attrs['campaign_touches'].first).to include(
        'source' => 'meta_organic',
        'source_id' => 'organic-post-123',
        'source_type' => 'post'
      )
      expect(attrs['campaign']['body']).to eq('conteúdo orgânico')
      expect(attrs['campaign_source_ids']).to eq(['organic-post-123'])
    end

    it 'falls back to source_id dedup when the referral has no click id' do
      no_clid = first_referral.except('ctwa_clid')

      described_class.attribute!(conversation, no_clid)
      described_class.attribute!(conversation, no_clid)

      expect(conversation.reload.additional_attributes['campaign_touches'].length).to eq(1)
    end

    it 'migrates a legacy single-touch record on the next touch' do
      legacy_campaign = described_class.build(first_referral)
      conversation.update!(additional_attributes: { 'campaign' => legacy_campaign })

      described_class.attribute!(conversation, second_referral)

      attrs = conversation.reload.additional_attributes
      expect(attrs['campaign']).to include(legacy_campaign)
      expect(attrs['campaign']['touched_at']).to eq(conversation.created_at.utc.iso8601)
      expect(attrs['campaign_touches'].length).to eq(2)
      expect(attrs['campaign_touches'].first).to include(
        'source_id' => '52558118838064',
        'touched_at' => conversation.created_at.utc.iso8601
      )
      expect(attrs['campaign_touches'].first).not_to have_key('body')
      expect(attrs['campaign_source_ids']).to eq(%w[52558118838064 120252613195760416])
    end

    it 'migrates a legacy single-touch record even when the click is a duplicate redelivery' do
      legacy_campaign = described_class.build(first_referral)
      conversation.update!(additional_attributes: { 'campaign' => legacy_campaign })

      described_class.attribute!(conversation, first_referral)

      attrs = conversation.reload.additional_attributes
      expect(attrs['campaign_touches'].length).to eq(1)
      expect(attrs['campaign_touches'].first).to include('source_id' => '52558118838064')
      expect(attrs['campaign_touches'].first).not_to have_key('body')
      expect(attrs['campaign_source_ids']).to eq(['52558118838064'])
    end

    it 'stops appending at MAX_TOUCHES' do
      touches = Array.new(described_class::MAX_TOUCHES) do |index|
        { 'source' => 'meta_ctwa', 'source_id' => "ad-#{index}", 'ctwa_clid' => "clid-#{index}", 'touched_at' => '2026-07-01T00:00:00Z' }
      end
      conversation.update!(additional_attributes: { 'campaign' => touches.first, 'campaign_touches' => touches })

      described_class.attribute!(conversation, second_referral)

      expect(conversation.reload.additional_attributes['campaign_touches'].length).to eq(described_class::MAX_TOUCHES)
    end

    it 'keeps the mirror free of blanks and duplicates' do
      described_class.attribute!(conversation, 'ctwa_clid' => 'AfNOSOURCE')
      described_class.attribute!(conversation, first_referral)
      described_class.attribute!(conversation, first_referral.merge('ctwa_clid' => 'AfSAMEADNEWCLICK'))

      attrs = conversation.reload.additional_attributes
      expect(attrs['campaign_touches'].length).to eq(3)
      expect(attrs['campaign_source_ids']).to eq(['52558118838064'])
    end

    it 'keeps bridge keys in slim touches' do
      described_class.attribute!(
        conversation,
        source_id: 'click:ABCD2345',
        source_type: 'bridge',
        headline: 'QR Loja',
        gclid: 'gclid-123',
        utm_source: 'google',
        utm_medium: 'cpc',
        utm_campaign: 'july',
        inferred: true
      )

      expect(conversation.reload.additional_attributes['campaign_touches'].first).to include(
        'source' => 'google_ads',
        'source_id' => 'click:ABCD2345',
        'source_type' => 'bridge',
        'gclid' => 'gclid-123',
        'utm_source' => 'google',
        'utm_medium' => 'cpc',
        'utm_campaign' => 'july',
        'inferred' => true
      )
    end

    it 'does not create any label' do
      described_class.attribute!(conversation, first_referral)

      expect(conversation.account.labels).to be_empty
      expect(conversation.reload.label_list).to be_empty
    end

    it 'enqueues a card rebroadcast after a successful append when CRM is enabled' do
      with_modified_env CRM_KANBAN_ENABLED: 'true' do
        expect do
          described_class.attribute!(conversation, first_referral)
        end.to have_enqueued_job(Crm::Cards::RebroadcastConversationCardsJob).with(conversation.id)
      end
    end

    it 'does not enqueue a rebroadcast for a deduped touch even with CRM enabled' do
      described_class.attribute!(conversation, first_referral)

      with_modified_env CRM_KANBAN_ENABLED: 'true' do
        expect do
          described_class.attribute!(conversation, first_referral)
        end.not_to have_enqueued_job(Crm::Cards::RebroadcastConversationCardsJob)
      end
    end

    it 'does not enqueue a rebroadcast when CRM is disabled' do
      with_modified_env CRM_KANBAN_ENABLED: 'false' do
        expect do
          described_class.attribute!(conversation, first_referral)
        end.not_to have_enqueued_job(Crm::Cards::RebroadcastConversationCardsJob)
      end
    end
  end
end
