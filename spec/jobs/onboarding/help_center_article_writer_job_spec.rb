require 'rails_helper'

RSpec.describe Onboarding::HelpCenterArticleWriterJob do
  let(:account) { create(:account) }
  let(:portal) { create(:portal, account_id: account.id) }
  let(:plan) do
    { 'articles' => [
      { 'urls' => ['https://x.test/a'], 'title' => 'A', 'category_id' => nil },
      { 'urls' => ['https://x.test/b'], 'title' => 'B', 'category_id' => nil }
    ] }
  end
  let(:generation) do
    HelpCenterGeneration.create!(account: account, portal: portal, status: :generating, plan: plan)
  end

  before { clear_enqueued_jobs }

  describe 'queue' do
    it 'enqueues on the low queue' do
      expect { described_class.perform_later(generation, 0) }
        .to have_enqueued_job(described_class).on_queue('low')
    end
  end

  describe 'success path' do
    before do
      builder = instance_double(Onboarding::HelpCenterArticleBuilder, perform: true)
      allow(Onboarding::HelpCenterArticleBuilder).to receive(:new).and_return(builder)
    end

    it 'invokes the builder and increments articles_finished' do
      expect { described_class.perform_now(generation, 0) }
        .to change { generation.reload.articles_finished }.by(1)
    end

    it 'transitions to completed once the last writer finishes' do
      described_class.perform_now(generation, 0)
      expect(generation.reload.status).to eq('generating')

      described_class.perform_now(generation, 1)
      expect(generation.reload).to be_completed
      expect(generation.finished_at).to be_present
    end
  end

  describe 'failure handling' do
    it 'increments the counter on ArticleBuildFailed without re-raising' do
      allow(Onboarding::HelpCenterArticleBuilder).to receive(:new).and_raise(
        CustomExceptions::HelpCenter::ArticleBuildFailed, 'no source urls'
      )
      expect { described_class.perform_now(generation, 0) }
        .to change { generation.reload.articles_finished }.by(1)
    end

    it 're-enqueues itself on transient Firecrawl errors' do
      allow(Onboarding::HelpCenterArticleBuilder).to receive(:new).and_raise(
        Firecrawl::FirecrawlError, 'transient'
      )
      expect { described_class.perform_now(generation, 0) }
        .to have_enqueued_job(described_class).with(generation, 0)
    end

    it 'increments the counter when Firecrawl retries are exhausted' do
      allow(Onboarding::HelpCenterArticleBuilder).to receive(:new).and_raise(
        Firecrawl::FirecrawlError, 'always failing'
      )
      perform_enqueued_jobs do
        described_class.perform_later(generation, 0)
      end
      expect(generation.reload.articles_finished).to eq(1)
    end
  end

  describe 'broadcasts' do
    let!(:admin) { create(:user, account: account, role: :administrator) }
    let(:built_article) { instance_double(Article, id: 9876) }

    before do
      builder = instance_double(Onboarding::HelpCenterArticleBuilder, perform: built_article)
      allow(Onboarding::HelpCenterArticleBuilder).to receive(:new).and_return(builder)
    end

    it 'broadcasts help_center.article_generated on success' do
      payload = hash_including(generation_id: generation.id, article_id: 9876, articles_finished: 1)
      expect { described_class.perform_now(generation, 0) }
        .to have_enqueued_job(ActionCableBroadcastJob)
        .with([admin.pubsub_token], 'help_center.article_generated', payload)
    end

    it 'broadcasts help_center.generation_completed when the last writer finishes' do
      described_class.perform_now(generation, 0)
      payload = hash_including(generation_id: generation.id, status: 'completed')

      expect { described_class.perform_now(generation, 1) }
        .to have_enqueued_job(ActionCableBroadcastJob)
        .with([admin.pubsub_token], 'help_center.generation_completed', payload)
    end

    it 'does not broadcast article_generated on builder failure' do
      allow(Onboarding::HelpCenterArticleBuilder).to receive(:new).and_raise(
        CustomExceptions::HelpCenter::ArticleBuildFailed, 'no source urls'
      )
      expect { described_class.perform_now(generation, 0) }
        .not_to have_enqueued_job(ActionCableBroadcastJob)
        .with(anything, 'help_center.article_generated', anything)
    end

    it 'does not broadcast generation_completed when another writer already transitioned the generation' do
      # Simulate the race: a concurrent writer already flipped status to :completed.
      generation.update!(status: :completed, articles_finished: generation.planned_total, finished_at: Time.current)

      expect { described_class.perform_now(generation, 0) }
        .not_to have_enqueued_job(ActionCableBroadcastJob)
        .with(anything, 'help_center.generation_completed', anything)
    end
  end
end
