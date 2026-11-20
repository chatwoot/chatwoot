require 'rails_helper'

RSpec.describe Articles::BulkActionJob, type: :job do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:portal) { create(:portal, account: account) }
  let!(:empty_article) { create(:article, portal: portal, account: account, author: user, content: nil, status: :draft) }
  let!(:article) { create(:article, portal: portal, account: account, author: user, status: :draft) }
  let!(:other_article) { create(:article, portal: portal, account: account, author: user, status: :draft) }

  it 'applies the action to the given articles and then tells the agent who started it' do
    expect { described_class.perform_now(portal, user, [article.id], 'update_status', 'archived') }
      .to have_enqueued_job(ActionCableBroadcastJob)
      .with([user.pubsub_token], 'article.bulk_action_completed', { account_id: account.id })

    expect(article.reload).to be_archived
    expect(other_article.reload).to be_draft
  end

  it 'keeps going past an article that cannot be published' do
    described_class.perform_now(portal, user, [empty_article.id, article.id], 'update_status', 'published')

    expect(empty_article.reload).to be_draft
    expect(article.reload).to be_published
  end
end
