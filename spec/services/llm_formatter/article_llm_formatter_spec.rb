require 'rails_helper'

RSpec.describe LlmFormatter::ArticleLlmFormatter do
  let(:account) { create(:account) }
  let(:portal) { create(:portal, account: account) }
  let(:category) { create(:category, slug: 'test_category', portal: portal, account: account) }
  let(:author) { create(:user, account: account) }
  let(:formatter) { described_class.new(article) }

  around { |example| with_modified_env(FRONTEND_URL: 'https://app.example.com') { example.run } }

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
          Public URL: https://app.example.com/hc/#{portal.slug}/articles/test_article
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

    context 'when the portal has a custom domain' do
      let(:article) { create(:article, slug: 'refunds', portal: portal, author: author, account: account) }

      it 'gives the help center link on that domain' do
        portal.update!(custom_domain: 'help.example.com')

        expect(formatter.format).to include("Public URL: https://help.example.com/hc/#{portal.slug}/articles/refunds")
      end
    end

    context 'when article is a draft' do
      let(:article) { create(:article, status: :draft, portal: portal, author: author, account: account) }

      it 'says it has no public link' do
        expect(formatter.format).to include('Public URL: None, because the article is not published')
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
