require 'rails_helper'

RSpec.describe Articles::BulkActionJob, type: :job do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:portal) { create(:portal, account: account) }
  let!(:empty_refund_article) do
    create(:article, portal: portal, account: account, author: user, title: 'Refund steps', content: nil, status: :draft)
  end
  let!(:refund_article) { create(:article, portal: portal, account: account, author: user, title: 'Refund policy', status: :draft) }
  let!(:other_article) { create(:article, portal: portal, account: account, author: user, status: :draft) }

  it 'applies the action to the articles the filters match and then tells the agent who started it' do
    expect { described_class.perform_now(portal, user, { locale: 'en', query: 'refund' }, 'update_status', 'published') }
      .to have_enqueued_job(ActionCableBroadcastJob)
      .with([user.pubsub_token], 'article.bulk_action_completed', { account_id: account.id })

    expect(refund_article.reload).to be_published
    expect(other_article.reload).to be_draft
  end

  it 'keeps going past an article that cannot be published' do
    described_class.perform_now(portal, user, { locale: 'en', query: 'refund' }, 'update_status', 'published')

    expect(empty_refund_article.reload).to be_draft
    expect(refund_article.reload).to be_published
  end
end
