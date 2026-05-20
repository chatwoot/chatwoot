require 'rails_helper'

RSpec.describe Onboarding::HelpCenterArticleBuilder do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :administrator) }
  let(:portal) { create(:portal, account_id: account.id) }

  describe 'source url validation' do
    it 'requires source urls' do
      article = { urls: [], title: 'X' }
      builder = described_class.new(account: account, portal: portal, user: user, article: article)

      expect(Firecrawl::Configuration).not_to receive(:client)
      expect { builder.perform }
        .to raise_error(Onboarding::HelpCenterErrors::ArticleBuildFailed, /no source urls/)
    end
  end
end
