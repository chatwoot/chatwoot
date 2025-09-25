require 'rails_helper'

RSpec.describe Captain::Tools::Copilot::SearchArticlesService do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:service) { described_class.new(assistant, user: user) }

  describe '#name' do
    it 'returns the correct service name' do
      expect(service.name).to eq('search_articles')
    end
  end

  describe '#description' do
    it 'returns the service description' do
      expect(service.description).to eq('Search articles based on parameters')
    end
  end

  describe '#parameters' do
    it 'returns the expected parameter schema' do
      expect(service.parameters).to eq(
        {
          type: 'object',
          properties: {
            query: {
              type: 'string',
              description: 'Search articles by title or content (partial match)'
            },
            category_id: {
              type: 'number',
              description: 'Filter articles by category ID'
            },
            status: {
              type: 'string',
              enum: %w[draft published archived],
              description: 'Filter articles by status'
            }
          },
          required: ['query']
        }
      )
    end
  end

  describe '#active?' do
    context 'when user is an admin' do
      let(:user) { create(:user, :administrator, account: account) }
      let(:assistant) { create(:captain_assistant, account: account) }

      it 'returns true' do
        expect(service.active?).to be true
      end
    end

    context 'when user is an agent' do
      let(:user) { create(:user, account: account) }
      let(:assistant) { create(:captain_assistant, account: account) }

      it 'returns true' do
        expect(service.active?).to be true
      end
    end

    context 'when user has custom role with knowledge_base_manage permission' do
      let(:user) { create(:user, account: account) }
      let(:assistant) { create(:captain_assistant, account: account) }
      let(:custom_role) { create(:custom_role, account: account, permissions: ['knowledge_base_manage']) }

      before do
        account_user = AccountUser.find_by(user: user, account: account)
        account_user.update(role: :agent, custom_role: custom_role)
      end

      it 'returns true' do
        expect(service.active?).to be true
      end
    end

    context 'when user has custom role without knowledge_base_manage permission' do
      let(:user) { create(:user, account: account) }
      let(:assistant) { create(:captain_assistant, account: account) }
      let(:custom_role) { create(:custom_role, account: account, permissions: []) }

      before do
        account_user = AccountUser.find_by(user: user, account: account)
        account_user.update(role: :agent, custom_role: custom_role)
      end

      it 'returns false' do
        expect(service.active?).to be false
      end
    end
  end

  describe '#execute' do
    context 'when query is blank' do
      it 'returns error message' do
        expect(service.execute({})).to eq('Missing required parameters')
      end
    end

    context 'when no articles are found' do
      it 'returns no articles found message' do
        expect(service.execute({ 'query' => 'test' })).to eq('No articles found')
      end
    end

    context 'when articles are found' do
      let(:portal) { create(:portal, account: account) }
      let!(:article1) { create(:article, account: account, portal: portal, author: user, title: 'Test Article 1', content: 'Content 1') }
      let!(:article2) { create(:article, account: account, portal: portal, author: user, title: 'Test Article 2', content: 'Content 2') }

      it 'returns formatted articles with count' do
        result = service.execute({ 'query' => 'Test' })
        expect(result).to include('Total number of articles: 2')
        expect(result).to include(article1.to_llm_text)
        expect(result).to include(article2.to_llm_text)
      end

      context 'when filtered by category' do
        let(:category) { create(:category, slug: 'test-category', portal: portal, account: account) }
        let!(:article3) { create(:article, account: account, portal: portal, author: user, category: category, title: 'Test Article 3') }

        it 'returns only articles from the specified category' do
          result = service.execute({ 'query' => 'Test', 'category_id' => category.id })
          expect(result).to include('Total number of articles: 1')
          expect(result).to include(article3.to_llm_text)
          expect(result).not_to include(article1.to_llm_text)
          expect(result).not_to include(article2.to_llm_text)
        end
      end

      context 'when filtered by status' do
        let!(:article3) { create(:article, account: account, portal: portal, author: user, title: 'Test Article 3', status: 'published') }
        let!(:article4) { create(:article, account: account, portal: portal, author: user, title: 'Test Article 4', status: 'draft') }

        it 'returns only articles with the specified status' do
          result = service.execute({ 'query' => 'Test', 'status' => 'published' })
          expect(result).to include(article3.to_llm_text)
          expect(result).not_to include(article4.to_llm_text)
        end
      end
    end
  end
end
