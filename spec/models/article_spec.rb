require 'rails_helper'

RSpec.describe Article do
  let!(:account) { create(:account) }
  let(:user) { create(:user, account_ids: [account.id], role: :agent) }
  let!(:portal_1) { create(:portal, account_id: account.id, config: { allowed_locales: %w[en es] }) }
  let!(:category_1) { create(:category, slug: 'category_1', locale: 'en', portal_id: portal_1.id) }

  context 'with validations' do
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:author_id) }
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:content) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:author) }
  end

  # This validation happens in ApplicationRecord
  describe 'length validations' do
    let(:article) do
      create(:article, category_id: category_1.id, content: 'This is the content', description: 'this is the description',
                       slug: 'this-is-title', title: 'this is title',
                       portal_id: portal_1.id, author_id: user.id)
    end

    context 'when it validates content length' do
      it 'valid when within limit' do
        article.content = 'a' * 1000
        expect(article.valid?).to be true
      end

      it 'invalid when crossed the limit' do
        article.content = 'a' * 25_001
        article.valid?
        expect(article.errors[:content]).to include('is too long (maximum is 20000 characters)')
      end
    end
  end

  describe 'add_locale_to_article' do
    let(:portal) { create(:portal, config: { allowed_locales: %w[en es pt], default_locale: 'es' }) }
    let(:category) { create(:category, slug: 'category_1', locale: 'pt', portal_id: portal.id) }

    it 'adds locale to article from category' do
      article = create(:article, category_id: category.id, content: 'This is the content', description: 'this is the description',
                                 slug: 'this-is-title', title: 'this is title',
                                 portal_id: portal.id, author_id: user.id)
      expect(article.locale).to eq(category.locale)
    end

    it 'adds locale to article from portal' do
      article = create(:article, content: 'This is the content', description: 'this is the description',
                                 slug: 'this-is-title', title: 'this is title',
                                 portal_id: portal.id, author_id: user.id, locale: '')
      expect(article.locale).to eq(portal.default_locale)
    end
  end

  describe 'search' do
    let!(:portal_2) { create(:portal, account_id: account.id, config: { allowed_locales: %w[en es] }) }
    let!(:category_2) { create(:category, slug: 'category_2', locale: 'es', portal_id: portal_1.id) }
    let!(:category_3) { create(:category, slug: 'category_3', locale: 'es', portal_id: portal_2.id) }

    before do
      create(:article, category_id: category_1.id, content: 'This is the content', description: 'this is the description',
                       slug: 'this-is-title', title: 'this is title',
                       portal_id: portal_1.id, author_id: user.id)
      create(:article, category_id: category_1.id, slug: 'title-1', title: 'title 1', content: 'This is the content', portal_id: portal_1.id,
                       author_id: user.id)
      create(:article, category_id: category_2.id, slug: 'title-2', title: 'title 2', portal_id: portal_2.id, author_id: user.id)
      create(:article, category_id: category_2.id, slug: 'title-3', title: 'title 3', portal_id: portal_1.id, author_id: user.id)
      create(:article, category_id: category_3.id, slug: 'title-6', title: 'title 6', portal_id: portal_2.id, author_id: user.id, status: :published)
      create(:article, category_id: category_2.id, slug: 'title-7', title: 'title 7', portal_id: portal_1.id, author_id: user.id, status: :published)
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

      it 'auto saves article slug' do
        article = create(:article, category_id: category_1.id, title: 'the awesome article 1', content: 'This is the content', portal_id: portal_1.id,
                                   author_id: user.id)
        expect(article.slug).to include('the-awesome-article-1')
      end
    end
  end

  describe '#to_llm_text' do
    it 'returns formatted article text' do
      category = create(:category, name: 'Test Category', slug: 'test_category', portal_id: portal_1.id)
      article = create(:article, title: 'Test Article', category_id: category.id, content: 'This is the content', portal_id: portal_1.id,
                                 author_id: user.id)
      expected_output = <<~TEXT
        Title: #{article.title}
        ID: #{article.id}
        Status: #{article.status}
        Category: #{category.name}
        Author: #{user.name}
        Views: #{article.views}
        Created At: #{article.created_at}
        Updated At: #{article.updated_at}
        Content:
        #{article.content}
      TEXT

      expect(article.to_llm_text).to eq(expected_output)
    end
  end
end
