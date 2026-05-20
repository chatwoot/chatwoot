require 'rails_helper'

RSpec.describe Onboarding::HelpCenterArticleWriterJob do
  let(:account) { create(:account) }
  let(:portal) { create(:portal, account_id: account.id) }
  let!(:admin) { create(:user, account: account, role: :administrator) }
  let(:generation_id) { 'generation-123' }
  let(:article_spec) { { 'urls' => ['https://x.test/a'], 'title' => 'A', 'category_id' => nil } }
  let(:article_payload) { { 'article' => article_spec } }
  let(:job_args) { [account.id, portal.id, admin.id, generation_id, article_payload] }
  let(:state_key) { Onboarding::HelpCenterGenerationState.key(generation_id) }

  before do
    Onboarding::HelpCenterGenerationState.start(generation_id, total: 2)
    clear_enqueued_jobs
  end

  after do
    Redis::Alfred.delete(state_key)
  end

  describe 'queue' do
    it 'enqueues on the low queue' do
      expect { described_class.perform_later(*job_args) }
        .to have_enqueued_job(described_class).on_queue('low')
    end
  end

  describe 'success path' do
    let(:built_article) { instance_double(Article, id: 9876) }

    before do
      builder = instance_double(Onboarding::HelpCenterArticleBuilder, perform: built_article)
      allow(Onboarding::HelpCenterArticleBuilder).to receive(:new).and_return(builder)
    end

    it 'invokes the builder and increments the Redis counter' do
      described_class.perform_now(*job_args)

      expect(Onboarding::HelpCenterGenerationState.current(generation_id)).to include('finished' => '1')
      expect(Onboarding::HelpCenterArticleBuilder).to have_received(:new).with(
        account: account,
        portal: portal,
        user: admin,
        article: article_spec
      )
    end

    it 'flips status to completed once the last writer finishes' do
      described_class.perform_now(*job_args)
      expect(Onboarding::HelpCenterGenerationState.current(generation_id)).to include('status' => 'generating')

      described_class.perform_now(*job_args)
      expect(Onboarding::HelpCenterGenerationState.current(generation_id)).to include(
        'status' => 'completed', 'finished' => '2'
      )
    end
  end

  describe 'failure handling' do
    it 'increments the counter on ArticleBuildFailed without re-raising' do
      allow(Onboarding::HelpCenterArticleBuilder).to receive(:new).and_raise(
        Onboarding::HelpCenterErrors::ArticleBuildFailed, 'no source urls'
      )

      described_class.perform_now(*job_args)

      expect(Onboarding::HelpCenterGenerationState.current(generation_id)).to include('finished' => '1')
    end

    it 'broadcasts completion when the final writer fails with ArticleBuildFailed' do
      allow(Onboarding::HelpCenterArticleBuilder).to receive(:new).and_raise(
        Onboarding::HelpCenterErrors::ArticleBuildFailed, 'no source urls'
      )
      Onboarding::HelpCenterGenerationState.record_article_finished(generation_id)
      payload = hash_including(generation_id: generation_id, status: 'completed')

      expect { described_class.perform_now(*job_args) }
        .to have_enqueued_job(ActionCableBroadcastJob)
        .with([admin.pubsub_token], 'help_center.generation_completed', payload)
      expect(Onboarding::HelpCenterGenerationState.current(generation_id)).to include(
        'status' => 'completed', 'finished' => '2'
      )
    end

    it 're-enqueues itself on transient Firecrawl errors' do
      allow(Onboarding::HelpCenterArticleBuilder).to receive(:new).and_raise(
        Firecrawl::FirecrawlError, 'transient'
      )

      expect { described_class.perform_now(*job_args) }
        .to have_enqueued_job(described_class).with(*job_args)
    end

    it 'increments the counter when Firecrawl retries are exhausted' do
      allow(Onboarding::HelpCenterArticleBuilder).to receive(:new).and_raise(
        Firecrawl::FirecrawlError, 'always failing'
      )

      perform_enqueued_jobs do
        described_class.perform_later(*job_args)
      end

      expect(Onboarding::HelpCenterGenerationState.current(generation_id)).to include('finished' => '1')
    end
  end

  describe 'broadcasts' do
    let(:built_article) { instance_double(Article, id: 9876) }

    before do
      builder = instance_double(Onboarding::HelpCenterArticleBuilder, perform: built_article)
      allow(Onboarding::HelpCenterArticleBuilder).to receive(:new).and_return(builder)
    end

    it 'broadcasts help_center.article_generated on success' do
      payload = hash_including(generation_id: generation_id, article_id: 9876, articles_finished: 1)
      expect { described_class.perform_now(*job_args) }
        .to have_enqueued_job(ActionCableBroadcastJob)
        .with([admin.pubsub_token], 'help_center.article_generated', payload)
    end

    it 'broadcasts help_center.generation_completed when the last writer finishes' do
      described_class.perform_now(*job_args)
      payload = hash_including(generation_id: generation_id, status: 'completed')

      expect { described_class.perform_now(*job_args) }
        .to have_enqueued_job(ActionCableBroadcastJob)
        .with([admin.pubsub_token], 'help_center.generation_completed', payload)
    end

    it 'does not broadcast article_generated on builder failure' do
      allow(Onboarding::HelpCenterArticleBuilder).to receive(:new).and_raise(
        Onboarding::HelpCenterErrors::ArticleBuildFailed, 'no source urls'
      )

      expect { described_class.perform_now(*job_args) }
        .not_to have_enqueued_job(ActionCableBroadcastJob)
        .with(anything, 'help_center.article_generated', anything)
    end

    it 'broadcasts generation_completed on late retries past total' do
      described_class.perform_now(*job_args)
      described_class.perform_now(*job_args)
      clear_enqueued_jobs

      expect { described_class.perform_now(*job_args) }
        .to have_enqueued_job(ActionCableBroadcastJob)
        .with([admin.pubsub_token], 'help_center.generation_completed', hash_including(generation_id: generation_id))
    end

    it 'skips progress broadcasts when state is missing' do
      Redis::Alfred.delete(state_key)

      expect { described_class.perform_now(*job_args) }
        .not_to have_enqueued_job(ActionCableBroadcastJob)
    end
  end
end
