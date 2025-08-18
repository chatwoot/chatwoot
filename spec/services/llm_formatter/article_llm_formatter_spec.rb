require 'rails_helper'

RSpec.describe LlmFormatter::ArticleLlmFormatter do
  let(:account) { create(:account) }
  let(:portal) { create(:portal, account: account) }
  let(:category) { create(:category, slug: 'test_category', portal: portal, account: account) }
  let(:author) { create(:user, account: account) }
  let(:formatter) { described_class.new(article) }

  describe '#format' do
    context 'when article has all details' do
      let(:article) do
        create(:article,
               slug: 'test_article',
               portal: portal, category: category, author: author, views: 100, account: account)
      end

      it 'formats article details correctly' do
        expected_output = <<~TEXT
          Title: #{article.title}
          ID: #{article.id}
          Status: #{article.status}
          Category: #{category.name}
          Author: #{author.name}
          Views: #{article.views}
          Created At: #{article.created_at}
          Updated At: #{article.updated_at}
          Content:
          #{article.content}
        TEXT

        expect(formatter.format).to eq(expected_output)
      end
    end

    context 'when article has no category' do
      let(:article) { create(:article, portal: portal, category: nil, author: author, account: account) }

      it 'shows Uncategorized for category' do
        expect(formatter.format).to include('Category: Uncategorized')
      end
    end
  end
end
