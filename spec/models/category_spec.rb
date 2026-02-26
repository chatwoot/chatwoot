# == Schema Information
#
# Table name: categories
#
#  id                     :bigint           not null, primary key
#  description            :text
#  icon                   :string           default("")
#  locale                 :string           default("en")
#  name                   :string
#  position               :integer
#  slug                   :string           not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :integer          not null
#  associated_category_id :bigint
#  parent_category_id     :bigint
#  portal_id              :integer          not null
#
# Indexes
#
#  index_categories_on_associated_category_id         (associated_category_id)
#  index_categories_on_locale                         (locale)
#  index_categories_on_locale_and_account_id          (locale,account_id)
#  index_categories_on_parent_category_id             (parent_category_id)
#  index_categories_on_slug_and_locale_and_portal_id  (slug,locale,portal_id) UNIQUE
#
require 'rails_helper'

RSpec.describe Category do
  context 'with validations' do
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:name) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:portal) }
    it { is_expected.to have_many(:articles) }
    it { is_expected.to have_many(:sub_categories) }
    it { is_expected.to have_many(:associated_categories) }
    it { is_expected.to have_many(:related_categories) }
  end

  describe 'validations' do
    let!(:account) { create(:account) }
    let(:user) { create(:user, account_ids: [account.id], role: :agent) }
    let!(:portal) { create(:portal, account_id: account.id, config: { allowed_locales: ['en'] }) }

    it 'returns erros when locale is not allowed in the portal' do
      category = create(:category, slug: 'category_1', locale: 'en', portal_id: portal.id)
      expect(category).to be_valid
      category.update(locale: 'es')
      expect(category.errors.full_messages[0]).to eq("Locale es of category is not part of portal's [\"en\"].")
    end
  end

  describe 'search' do
    let!(:account) { create(:account) }
    let(:user) { create(:user, account_ids: [account.id], role: :agent) }
    let!(:portal_1) { create(:portal, account_id: account.id, config: { allowed_locales: %w[en es] }) }
    let!(:portal_2) { create(:portal, account_id: account.id, config: { allowed_locales: %w[en es] }) }

    before do
      create(:category, slug: 'category_1', locale: 'en', portal_id: portal_1.id)
      create(:category, slug: 'category_2', locale: 'es', portal_id: portal_1.id)
      create(:category, slug: 'category_3', locale: 'es', portal_id: portal_2.id)
    end

    context 'when no parameters passed' do
      it 'returns all the articles in portal' do
        records = portal_1.categories.search({})
        expect(records.count).to eq(portal_1.categories.count)

        records = portal_2.categories.search({})
        expect(records.count).to eq(portal_2.categories.count)
      end
    end

    context 'when params passed' do
      it 'returns all the categories with all the params filters' do
        params = { locale: 'es' }
        records = portal_2.categories.search(params)
        expect(records.count).to eq(1)

        params = { locale: 'en' }
        records = portal_1.categories.search(params)
        expect(records.count).to eq(1)
      end
    end
  end
end
