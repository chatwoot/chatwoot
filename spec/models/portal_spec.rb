# == Schema Information
#
# Table name: portals
#
#  id                    :bigint           not null, primary key
#  archived              :boolean          default(FALSE)
#  color                 :string
#  config                :jsonb
#  custom_domain         :string
#  header_text           :text
#  homepage_link         :string
#  name                  :string           not null
#  page_title            :string
#  slug                  :string           not null
#  ssl_settings          :jsonb            not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :integer          not null
#  channel_web_widget_id :bigint
#
# Indexes
#
#  index_portals_on_channel_web_widget_id  (channel_web_widget_id)
#  index_portals_on_custom_domain          (custom_domain) UNIQUE
#  index_portals_on_slug                   (slug) UNIQUE
#
require 'rails_helper'

RSpec.describe Portal do
  context 'with validations' do
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:slug) }
    it { is_expected.to validate_presence_of(:name) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:categories) }
    it { is_expected.to have_many(:folders) }
    it { is_expected.to have_many(:articles) }
    it { is_expected.to have_many(:inboxes) }
  end

  describe 'validations' do
    let!(:account) { create(:account) }
    let!(:portal) { create(:portal, account_id: account.id) }

    context 'when set portal config' do
      it 'Adds default allowed_locales en' do
        expect(portal.config).to be_present
        expect(portal.config['allowed_locales']).to eq(['en'])
        expect(portal.config['default_locale']).to eq('en')
      end

      it 'Does not allow any other config than allowed_locales' do
        portal.update(config: { 'some_other_key': 'test_value' })
        expect(portal).not_to be_valid
        expect(portal.errors.full_messages[0]).to eq('Cofig in portal on some_other_key is not supported.')
      end

      it 'converts empty string to nil' do
        portal.update(custom_domain: '')
        expect(portal.custom_domain).to be_nil
      end
    end
  end
end
