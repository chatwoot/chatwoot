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

    it 'rejects duplicate locales in a translation family' do
      portal.update!(config: { allowed_locales: %w[en es] })
      root_category = create(:category, portal: portal, locale: 'en', slug: 'root-category')
      create(:category, portal: portal, locale: 'es', slug: 'spanish-category', associated_category_id: root_category.id)

      duplicate = build(:category, portal: portal, locale: 'es', slug: 'duplicate-spanish-category', associated_category_id: root_category.id)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:locale]).to include('has already been taken')
    end
  end

  describe 'translation associations' do
    it 'associates nested translations with the root category' do
      portal = create(:portal, config: { allowed_locales: %w[en es pt] })
      root_category = create(:category, portal: portal, locale: 'en')
      translation = create(:category, portal: portal, locale: 'es', associated_category_id: root_category.id)

      nested_translation = create(:category, portal: portal, locale: 'pt', associated_category_id: translation.id)

      expect(nested_translation.associated_category_id).to eq(root_category.id)
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
