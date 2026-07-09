require 'rails_helper'

# Focused coverage for the three small CTWA/credential resolvers used by the
# Meta CAPI dispatch/backfill path.
RSpec.describe 'Crm::MetaCapi resolvers' do # rubocop:disable RSpec/DescribeClass
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :administrator) }
  let(:pipeline) { account.crm_pipelines.create!(name: 'P', created_by: user, status: :active) }
  let(:stage) { account.crm_pipeline_stages.create!(pipeline: pipeline, name: 'S', position: 0) }

  def card_with_conversation(additional_attributes)
    channel = create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud',
                                        validate_provider_config: false, sync_templates: false)
    conversation = create(:conversation, account: account, inbox: channel.inbox,
                                         additional_attributes: additional_attributes)
    account.crm_cards.create!(pipeline: pipeline, stage: stage, title: 'C', currency: 'BRL', primary_conversation: conversation)
  end

  describe Crm::MetaCapi::CtwaClidResolver do
    it 'prefers the campaign origin clid' do
      card = card_with_conversation('campaign' => { 'ctwa_clid' => 'ORIGIN' },
                                    'campaign_touches' => [{ 'ctwa_clid' => 'TOUCH' }])

      expect(described_class.resolve(card)).to eq('ORIGIN')
    end

    it 'falls back to the most recent touch carrying a clid' do
      card = card_with_conversation('campaign_touches' => [{ 'ctwa_clid' => 'FIRST' }, { 'foo' => 'bar' }, { 'ctwa_clid' => 'LAST' }])

      expect(described_class.resolve(card)).to eq('LAST')
    end

    it 'returns nil when there is no CTWA signal' do
      card = card_with_conversation({})

      expect(described_class.resolve(card)).to be_nil
    end

    it 'returns nil for a standalone card without a conversation' do
      card = account.crm_cards.create!(pipeline: pipeline, stage: stage, title: 'Standalone', currency: 'BRL')

      expect(described_class.resolve(card)).to be_nil
    end
  end

  describe Crm::MetaCapi::StageTypeResolver do
    it 'reads the configured funnel_stage_type from the stage metadata' do
      stage.update!(metadata: { 'funnel_stage_type' => 'qualified' })

      expect(described_class.resolve(stage)).to eq('qualified')
    end

    it 'returns nil when the stage did not opt in' do
      expect(described_class.resolve(stage)).to be_nil
    end

    it 'returns nil for a blank stage' do
      expect(described_class.resolve(nil)).to be_nil
    end
  end
end
