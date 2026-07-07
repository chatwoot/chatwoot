require 'rake'
require 'rails_helper'

RSpec.describe Rake::Task do
  let(:account) { create(:account) }
  let(:legacy_campaign) do
    {
      'source' => 'meta_ctwa',
      'source_id' => '120212345678901234',
      'source_type' => 'ad',
      'source_url' => 'https://fb.me/ad-link',
      'headline' => 'July promo',
      'body' => 'Talk to us about the July promo',
      'media_type' => 'image',
      'ctwa_clid' => 'clid-abc-123'
    }
  end

  describe 'ctwa:convert_legacy' do
    subject(:task) { described_class['ctwa:convert_legacy'] }

    before { task.reenable }

    it 'seeds the multi-touch keys from the legacy campaign hash' do
      conversation = create(:conversation, account: account, additional_attributes: { 'campaign' => legacy_campaign })

      task.invoke

      attrs = conversation.reload.additional_attributes
      expected_touch = legacy_campaign.slice(*Ctwa::CampaignBuilder::TOUCH_KEYS)
                                      .merge('touched_at' => conversation.created_at.utc.iso8601)
      expect(attrs['campaign_touches']).to eq([expected_touch])
      expect(attrs['campaign_source_ids']).to eq([legacy_campaign['source_id']])
      expect(attrs['campaign']).to eq(legacy_campaign.merge('touched_at' => conversation.created_at.utc.iso8601))
    end

    it 'keeps the slim touch free of the ad body' do
      conversation = create(:conversation, account: account, additional_attributes: { 'campaign' => legacy_campaign })

      task.invoke

      expect(conversation.reload.additional_attributes['campaign_touches'].first).not_to have_key('body')
    end

    it 'is a no-op on already converted conversations' do
      converted_attributes = {
        'campaign' => legacy_campaign.merge('touched_at' => '2026-07-01T10:00:00Z'),
        'campaign_touches' => [legacy_campaign.except('body').merge('touched_at' => '2026-07-01T10:00:00Z')],
        'campaign_source_ids' => [legacy_campaign['source_id']]
      }
      conversation = create(:conversation, account: account, additional_attributes: converted_attributes)

      task.invoke

      expect(conversation.reload.additional_attributes).to eq(converted_attributes)
    end

    it 'is idempotent when re-run' do
      conversation = create(:conversation, account: account, additional_attributes: { 'campaign' => legacy_campaign })

      task.invoke
      first_pass = conversation.reload.additional_attributes
      task.reenable
      task.invoke

      expect(conversation.reload.additional_attributes).to eq(first_pass)
    end

    it 'does not touch conversations without campaign data' do
      conversation = create(:conversation, account: account, additional_attributes: { 'referer' => 'https://example.com' })

      task.invoke

      expect(conversation.reload.additional_attributes).to eq('referer' => 'https://example.com')
    end
  end

  describe 'ctwa:remove_meta_ctwa_label' do
    subject(:task) { described_class['ctwa:remove_meta_ctwa_label'] }

    let!(:ctwa_conversation) do
      conversation = create(:conversation, account: account, additional_attributes: { 'campaign' => legacy_campaign })
      conversation.update_labels(['meta_ctwa'])
      conversation
    end

    before do
      create(:label, account: account, title: 'meta_ctwa')
      task.reenable
    end

    it 'does not change anything by default (DRY_RUN safety)' do
      with_modified_env DRY_RUN: nil, ACCOUNT_IDS: nil do
        task.invoke
      end

      expect(ctwa_conversation.reload.label_list).to include('meta_ctwa')
      expect(account.labels.exists?(title: 'meta_ctwa')).to be(true)
    end

    it 'removes the tag from campaign conversations and clears the cached label list' do
      with_modified_env DRY_RUN: '0', ACCOUNT_IDS: nil do
        task.invoke
      end

      ctwa_conversation.reload
      expect(ctwa_conversation.label_list).not_to include('meta_ctwa')
      expect(ctwa_conversation.cached_label_list.to_s).not_to include('meta_ctwa')
    end

    it 'preserves a manually applied label on a conversation without campaign and keeps the Label record' do
      manual_conversation = create(:conversation, account: account)
      manual_conversation.update_labels(['meta_ctwa'])

      with_modified_env DRY_RUN: '0', ACCOUNT_IDS: nil do
        task.invoke
      end

      expect(manual_conversation.reload.label_list).to include('meta_ctwa')
      expect(ctwa_conversation.reload.label_list).not_to include('meta_ctwa')
      expect(account.labels.exists?(title: 'meta_ctwa')).to be(true)
    end

    it 'deletes the Label record only when no tagging remains in the account' do
      with_modified_env DRY_RUN: '0', ACCOUNT_IDS: nil do
        task.invoke
      end

      expect(account.labels.exists?(title: 'meta_ctwa')).to be(false)
    end

    it 'aborts without touching anything when a custom view references meta_ctwa' do
      create(:custom_filter, account: account, user: create(:user, account: account), query: { labels: ['meta_ctwa'] })

      with_modified_env DRY_RUN: '0', ACCOUNT_IDS: nil do
        expect { task.invoke }.to raise_error(SystemExit)
      end

      expect(ctwa_conversation.reload.label_list).to include('meta_ctwa')
      expect(account.labels.exists?(title: 'meta_ctwa')).to be(true)
    end

    it 'aborts when an automation rule references meta_ctwa' do
      create(:automation_rule, account: account, actions: [{ 'action_name' => 'add_label', 'action_params' => ['meta_ctwa'] }])

      with_modified_env DRY_RUN: '0', ACCOUNT_IDS: nil do
        expect { task.invoke }.to raise_error(SystemExit)
      end

      expect(ctwa_conversation.reload.label_list).to include('meta_ctwa')
    end

    it 'limits the cleanup to the accounts given in ACCOUNT_IDS' do
      other_account = create(:account)
      create(:label, account: other_account, title: 'meta_ctwa')
      other_conversation = create(:conversation, account: other_account, additional_attributes: { 'campaign' => legacy_campaign })
      other_conversation.update_labels(['meta_ctwa'])

      with_modified_env DRY_RUN: '0', ACCOUNT_IDS: account.id.to_s do
        task.invoke
      end

      expect(ctwa_conversation.reload.label_list).not_to include('meta_ctwa')
      expect(other_conversation.reload.label_list).to include('meta_ctwa')
      expect(other_account.labels.exists?(title: 'meta_ctwa')).to be(true)
    end
  end
end
