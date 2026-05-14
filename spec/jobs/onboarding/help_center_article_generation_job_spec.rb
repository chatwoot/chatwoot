require 'rails_helper'

RSpec.describe Onboarding::HelpCenterArticleGenerationJob do
  let(:account) { create(:account) }
  let(:portal) { create(:portal, account_id: account.id) }
  let(:generation) do
    HelpCenterGeneration.create!(account: account, portal: portal)
  end
  let(:curated_plan) do
    {
      'categories' => [{ 'name' => 'Getting Started', 'description' => 'desc' }],
      'articles' => [
        { 'title' => 'Hello', 'urls' => ['https://x.test/a'], 'category_name' => 'Getting Started' },
        { 'title' => 'World', 'urls' => ['https://x.test/b'], 'category_name' => 'Getting Started' }
      ]
    }
  end

  before do
    generation # force creation before clearing the queue (after_create_commit enqueues this job)
    clear_enqueued_jobs
    curator = instance_double(Onboarding::HelpCenterCurator, perform: curated_plan)
    allow(Onboarding::HelpCenterCurator).to receive(:new).and_return(curator)
  end

  describe 'queue' do
    it 'enqueues on the low queue' do
      expect { described_class.perform_later(generation) }
        .to have_enqueued_job(described_class).on_queue('low')
    end
  end

  describe 'happy path' do
    it 'creates categories, persists the enriched plan, and fans out one writer per article' do
      expect do
        perform_enqueued_jobs(only: described_class) { described_class.perform_later(generation) }
      end.to change { portal.categories.count }.by(1)

      generation.reload
      expect(generation).to be_generating
      expect(generation.plan['articles'].first['category_id']).to eq(portal.categories.first.id)
      writer_jobs = enqueued_jobs.select { |j| j['job_class'] == Onboarding::HelpCenterArticleWriterJob.name }
      expect(writer_jobs.size).to eq(2)
    end
  end

  describe 'orphan article filtering' do
    let(:curated_plan) do
      {
        'categories' => [{ 'name' => 'Getting Started', 'description' => 'desc' }],
        'articles' => [
          { 'title' => 'Valid', 'urls' => ['https://x.test/a'], 'category_name' => 'Getting Started' },
          { 'title' => 'Orphan', 'urls' => ['https://x.test/b'], 'category_name' => 'NonExistent' }
        ]
      }
    end

    it 'drops articles whose category was not emitted alongside them' do
      perform_enqueued_jobs(only: described_class) { described_class.perform_later(generation) }

      generation.reload
      expect(generation.plan['articles'].size).to eq(1)
      expect(generation.plan['articles'].first['title']).to eq('Valid')

      writer_jobs = enqueued_jobs.select { |j| j['job_class'] == Onboarding::HelpCenterArticleWriterJob.name }
      expect(writer_jobs.size).to eq(1)
    end
  end

  describe 'idempotency' do
    it 'no-ops when the generation is not pending' do
      generation.update!(status: :completed)
      expect { described_class.perform_now(generation) }
        .not_to(change { portal.categories.count })
    end
  end

  describe 'curation skipped' do
    it 'records skip_reason and transitions to skipped' do
      curator = instance_double(Onboarding::HelpCenterCurator)
      allow(curator).to receive(:perform).and_raise(
        CustomExceptions::HelpCenter::CurationSkipped, 'no website url'
      )
      allow(Onboarding::HelpCenterCurator).to receive(:new).and_return(curator)

      described_class.perform_now(generation)
      generation.reload
      expect(generation).to be_skipped
      expect(generation.skip_reason).to eq('no website url')
      expect(generation.finished_at).to be_present
    end
  end

  describe 'firecrawl retries' do
    it 'transitions to skipped after retries exhaust' do
      curator = instance_double(Onboarding::HelpCenterCurator)
      allow(curator).to receive(:perform).and_raise(Firecrawl::FirecrawlError, 'rate limited')
      allow(Onboarding::HelpCenterCurator).to receive(:new).and_return(curator)

      perform_enqueued_jobs { described_class.perform_later(generation) }
      generation.reload
      expect(generation).to be_skipped
      expect(generation.skip_reason).to include('firecrawl exhausted')
    end
  end

  describe 'broadcasts' do
    let!(:admin) { create(:user, account: account, role: :administrator) }

    it 'broadcasts generation_completed with status: skipped on CurationSkipped' do
      curator = instance_double(Onboarding::HelpCenterCurator)
      allow(curator).to receive(:perform).and_raise(
        CustomExceptions::HelpCenter::CurationSkipped, 'no website url'
      )
      allow(Onboarding::HelpCenterCurator).to receive(:new).and_return(curator)

      payload = hash_including(generation_id: generation.id, status: 'skipped', skip_reason: 'no website url')
      expect { described_class.perform_now(generation) }
        .to have_enqueued_job(ActionCableBroadcastJob)
        .with([admin.pubsub_token], 'help_center.generation_completed', payload)
    end

    it 'broadcasts generation_completed with status: skipped when firecrawl retries exhaust' do
      curator = instance_double(Onboarding::HelpCenterCurator)
      allow(curator).to receive(:perform).and_raise(Firecrawl::FirecrawlError, 'rate limited')
      allow(Onboarding::HelpCenterCurator).to receive(:new).and_return(curator)

      perform_enqueued_jobs(only: described_class) { described_class.perform_later(generation) }

      expect(enqueued_jobs).to include(
        a_hash_including(
          'job_class' => ActionCableBroadcastJob.name,
          'arguments' => array_including('help_center.generation_completed')
        )
      )
    end
  end
end
