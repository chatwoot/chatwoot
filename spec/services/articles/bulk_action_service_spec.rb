require 'rails_helper'

RSpec.describe Articles::BulkActionService do
  let(:account) { create(:account) }
  let(:author) { create(:user, account: account) }
  let(:portal) { create(:portal, account: account, config: { allowed_locales: %w[en es] }) }
  let(:category) { create(:category, portal: portal, account: account, locale: 'en', slug: 'billing') }
  let!(:draft_article) { create(:article, portal: portal, account: account, author: author, status: :draft) }
  let!(:published_article) { create(:article, portal: portal, account: account, author: author, status: :published) }
  let!(:spanish_article) { create(:article, portal: portal, account: account, author: author, locale: 'es', status: :draft) }

  def perform(action, value = nil)
    described_class.new(articles: portal.articles.where(locale: 'en'), action: action, value: value).perform
  end

  describe 'update_status' do
    it 'changes every article it is given and leaves the rest alone' do
      perform('update_status', 'archived')

      expect(draft_article.reload).to be_archived
      expect(published_article.reload).to be_archived
      expect(spanish_article.reload).to be_draft
    end

    it 'pushes unpublished edits live when publishing' do
      published_article.update!(draft_title: 'New title', draft_content: 'New content')

      perform('update_status', 'published')

      expect(published_article.reload).to have_attributes(
        title: 'New title', content: 'New content', draft_title: nil, draft_content: nil, status: 'published'
      )
    end

    it 'leaves a published article with unpublished edits untouched when archiving' do
      published_article.update!(draft_content: 'New content')

      perform('update_status', 'archived')

      expect(published_article.reload).to have_attributes(status: 'published', draft_content: 'New content')
      expect(draft_article.reload).to be_archived
    end
  end

  describe 'update_category' do
    it 'moves every article into the category' do
      perform('update_category', category.id)

      expect(draft_article.reload.category_id).to eq(category.id)
      expect(published_article.reload.category_id).to eq(category.id)
      expect(spanish_article.reload.category_id).to be_nil
    end
  end

  describe 'delete' do
    it 'deletes every article' do
      perform('delete')

      expect(portal.articles.pluck(:id)).to eq([spanish_article.id])
    end
  end
end
