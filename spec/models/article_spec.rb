require 'rails_helper'

RSpec.describe Article, type: :model do
  context 'with validations' do
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:category_id) }
    it { is_expected.to validate_presence_of(:author_id) }
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:content) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:category) }
    it { is_expected.to belong_to(:author) }
  end

  describe 'search' do
    let!(:account) { create(:account) }
    let(:user) { create(:user, account_ids: [account.id], role: :agent) }
    let!(:portal_1) { create(:portal, account_id: account.id, config: { allowed_locales: %w[en es] }) }
    let!(:portal_2) { create(:portal, account_id: account.id, config: { allowed_locales: %w[en es] }) }
    let!(:category_1) { create(:category, slug: 'category_1', locale: 'en', portal_id: portal_1.id) }
    let!(:category_2) { create(:category, slug: 'category_2', locale: 'es', portal_id: portal_1.id) }
    let!(:category_3) { create(:category, slug: 'category_3', locale: 'es', portal_id: portal_2.id) }

    before do
      create(:article, category_id: category_1.id, content: 'This is the content', description: 'this is the description', title: 'this is title',
                       portal_id: portal_1.id, author_id: user.id)
      create(:article, category_id: category_1.id, title: 'title 1', content: 'This is the content', portal_id: portal_1.id, author_id: user.id)
      create(:article, category_id: category_2.id, title: 'title 2', portal_id: portal_2.id, author_id: user.id)
      create(:article, category_id: category_2.id, title: 'title 3', portal_id: portal_1.id, author_id: user.id)
      create(:article, category_id: category_3.id, title: 'title 6', portal_id: portal_2.id, author_id: user.id, status: :published)
      create(:article, category_id: category_2.id, title: 'title 7', portal_id: portal_1.id, author_id: user.id, status: :published)
    end

    context 'when no parameters passed' do
      it 'returns all the articles in portal' do
        records = portal_1.articles.search({})
        expect(records.count).to eq(portal_1.articles.count)

        records = portal_2.articles.search({})
        expect(records.count).to eq(portal_2.articles.count)
      end
    end

    context 'when params passed' do
      it 'returns all the articles with all the params filters' do
        params = { query: 'title', locale: 'es', category_slug: 'category_3' }
        records = portal_2.articles.search(params)
        expect(records.count).to eq(1)

        params = { query: 'this', locale: 'en', category_slug: 'category_1' }
        records = portal_1.articles.search(params)
        expect(records.count).to eq(2)

        params = { status: 'published' }
        records = portal_1.articles.search(params)
        expect(records.count).to eq(portal_1.articles.published.size)
      end
    end

    context 'when some params missing' do
      it 'returns data with category slug' do
        params = { category_slug: 'category_2' }
        records = portal_1.articles.search(params)
        expect(records.count).to eq(2)
      end

      it 'returns data with locale' do
        params = { locale: 'es' }
        records = portal_2.articles.search(params)
        expect(records.count).to eq(2)

        params = { locale: 'en' }
        records = portal_1.articles.search(params)
        expect(records.count).to eq(2)
      end

      it 'returns data with text_search query' do
        params = { query: 'title' }
        records = portal_2.articles.search(params)

        expect(records.count).to eq(2)

        params = { query: 'title' }
        records = portal_1.articles.search(params)

        expect(records.count).to eq(4)

        params = { query: 'the content' }
        records = portal_1.articles.search(params)

        expect(records.count).to eq(2)
      end

      it 'returns data with text_search query and locale' do
        params = { query: 'title', locale: 'es' }
        records = portal_2.articles.search(params)
        expect(records.count).to eq(2)
      end

      it 'returns records with locale and category_slug' do
        params = { category_slug: 'category_2', locale: 'es' }
        records = portal_1.articles.search(params)
        expect(records.count).to eq(2)
      end

      it 'return records with category_slug and text_search query' do
        params = { category_slug: 'category_2', query: 'title' }
        records = portal_1.articles.search(params)
        expect(records.count).to eq(2)
      end

      it 'returns records with author and category_slug' do
        params = { category_slug: 'category_2', author_id: user.id }
        records = portal_1.articles.search(params)
        expect(records.count).to eq(2)
      end
    end

    context 'with pagination' do
      it 'returns paginated articles' do
        create_list(:article, 30, category_id: category_2.id, title: 'title 1', portal_id: portal_2.id, author_id: user.id)
        params = { category_slug: 'category_2' }
        records = portal_2.articles.search(params)
        expect(records.count).to eq(25)
      end
    end
  end
end
