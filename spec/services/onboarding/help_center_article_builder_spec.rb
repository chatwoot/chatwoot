require 'rails_helper'

RSpec.describe Onboarding::HelpCenterArticleBuilder do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :administrator) }
  let(:portal) { create(:portal, account_id: account.id) }

  describe 'allowlist enforcement' do
    it 'raises BuildFailed when none of the supplied urls are in the allowlist' do
      article = { urls: ['https://attacker.com/x'], title: 'X' }
      builder = described_class.new(
        account: account, portal: portal, user: user, article: article,
        allowed_urls: ['https://ok.com/a']
      )

      expect { builder.perform }
        .to raise_error(CustomExceptions::HelpCenter::ArticleBuildFailed, /no allowlisted urls/)
    end

    it 'does not call Firecrawl when the allowlist rejects every url' do
      article = { urls: ['https://attacker.com/x'], title: 'X' }
      builder = described_class.new(
        account: account, portal: portal, user: user, article: article,
        allowed_urls: ['https://ok.com/a']
      )

      expect(Firecrawl::Configuration).not_to receive(:client)
      expect { builder.perform }.to raise_error(CustomExceptions::HelpCenter::ArticleBuildFailed)
    end
  end
end
