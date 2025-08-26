require 'rails_helper'

RSpec.describe Captain::Tools::Copilot::GetArticleService do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:service) { described_class.new(assistant, user: user) }

  describe '#name' do
    it 'returns the correct service name' do
      expect(service.name).to eq('get_article')
    end
  end

  describe '#description' do
    it 'returns the service description' do
      expect(service.description).to eq('Get details of an article including its content and metadata')
    end
  end

  describe '#parameters' do
    it 'returns the expected parameter schema' do
      expect(service.parameters).to eq(
        {
          type: 'object',
          properties: {
            article_id: {
              type: 'number',
              description: 'The ID of the article to retrieve'
            }
          },
          required: %w[article_id]
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
    context 'when article_id is blank' do
      it 'returns error message' do
        expect(service.execute({})).to eq('Missing required parameters')
      end
    end

    context 'when article is not found' do
      it 'returns not found message' do
        expect(service.execute({ 'article_id' => 999 })).to eq('Article not found')
      end
    end

    context 'when article exists' do
      let(:portal) { create(:portal, account: account) }
      let(:article) { create(:article, account: account, portal: portal, author: user, title: 'Test Article', content: 'Content') }

      it 'returns the article in llm text format' do
        result = service.execute({ 'article_id' => article.id })
        expect(result).to eq(article.to_llm_text)
      end

      context 'when article belongs to different account' do
        let(:other_account) { create(:account) }
        let(:other_portal) { create(:portal, account: other_account) }
        let(:other_article) { create(:article, account: other_account, portal: other_portal, author: user, title: 'Other Article') }

        it 'returns not found message' do
          expect(service.execute({ 'article_id' => other_article.id })).to eq('Article not found')
        end
      end
    end
  end
end
