require 'rails_helper'

RSpec.describe Onboarding::HelpCenterArticleGenerationJob do
  let(:account) { create(:account, custom_attributes: {}) }
  let(:portal) { create(:portal, account_id: account.id) }
  let!(:admin) { create(:user, account: account, role: :administrator) }
  let(:generation_id) { 'generation-123' }
  let(:job_args) { [account.id, portal.id, admin.id, generation_id] }
  let(:curated_plan) do
    {
      'allowed_urls' => ['https://x.test/a', 'https://x.test/b'],
      'categories' => [{ 'name' => 'Getting Started', 'description' => 'desc' }],
      'articles' => [
        { 'title' => 'Hello', 'urls' => ['https://x.test/a'], 'category_name' => 'Getting Started' },
        { 'title' => 'World', 'urls' => ['https://x.test/b'], 'category_name' => 'Getting Started' }
      ]
    }
  end

  before do
    Onboarding::HelpCenterGenerationStatus.create!(account, generation_id)
    clear_enqueued_jobs
    curator = instance_double(Onboarding::HelpCenterCurator, perform: curated_plan)
    allow(Onboarding::HelpCenterCurator).to receive(:new).and_return(curator)
  end

  after do
    Redis::Alfred.delete(Onboarding::HelpCenterGenerationCounter.key(generation_id))
  end

  describe 'queue' do
    it 'enqueues on the low queue' do
      expect { described_class.perform_later(*job_args) }
        .to have_enqueued_job(described_class).on_queue('low')
    end
  end

  describe 'happy path' do
    it 'creates categories, stores generating state, creates a counter, and fans out article payloads' do
      expect do
        perform_enqueued_jobs(only: described_class) { described_class.perform_later(*job_args) }
      end.to change { portal.categories.count }.by(1)

      expect(account.reload.custom_attributes.dig('onboarding', 'help_center_generation')).to eq(
        'id' => generation_id,
        'status' => 'generating'
      )
      Redis::Alfred.with do |conn|
        expect(conn.hget(Onboarding::HelpCenterGenerationCounter.key(generation_id), 'total')).to eq('2')
        expect(conn.hget(Onboarding::HelpCenterGenerationCounter.key(generation_id), 'finished')).to eq('0')
      end
      expect(enqueued_jobs).to include(
        a_hash_including(
          'job_class' => Onboarding::HelpCenterArticleWriterJob.name,
          'arguments' => array_including(
            account.id,
            portal.id,
            admin.id,
            generation_id,
            hash_including(
              'article' => hash_including('title' => 'Hello', 'category_id' => portal.categories.first.id),
              'allowed_urls' => ['https://x.test/a', 'https://x.test/b']
            )
          )
        )
      )
    end
  end

  describe 'orphan article filtering' do
    let(:curated_plan) do
      {
        'allowed_urls' => ['https://x.test/a', 'https://x.test/b'],
        'categories' => [{ 'name' => 'Getting Started', 'description' => 'desc' }],
        'articles' => [
          { 'title' => 'Valid', 'urls' => ['https://x.test/a'], 'category_name' => 'Getting Started' },
          { 'title' => 'Orphan', 'urls' => ['https://x.test/b'], 'category_name' => 'NonExistent' }
        ]
      }
    end

    it 'drops articles whose category was not emitted alongside them' do
      perform_enqueued_jobs(only: described_class) { described_class.perform_later(*job_args) }

      writer_jobs = enqueued_jobs.select { |job| job['job_class'] == Onboarding::HelpCenterArticleWriterJob.name }
      expect(writer_jobs.size).to eq(1)
      expect(writer_jobs.first['arguments']).to include(
        hash_including('article' => hash_including('title' => 'Valid'))
      )
    end
  end

  describe 'transaction rollback' do
    let(:curated_plan) do
      {
        'categories' => [{ 'name' => 'Getting Started', 'description' => 'desc' }],
        'articles' => [{ 'title' => 'Orphan', 'urls' => ['https://x.test/b'], 'category_name' => 'NonExistent' }]
      }
    end

    it 'leaves zero categories when no article can be stamped' do
      described_class.perform_now(*job_args)

      expect(portal.categories.count).to eq(0)
      expect(account.reload.custom_attributes.dig('onboarding', 'help_center_generation')).to eq(
        'id' => generation_id,
        'status' => 'skipped',
        'skip_reason' => 'no articles after category stamping (LLM article category_name did not match any curated category)'
      )
    end
  end

  describe 'idempotency' do
    it 'no-ops when the generation is already generating' do
      Onboarding::HelpCenterGenerationStatus.mark_generating!(account, generation_id)

      expect { described_class.perform_now(*job_args) }
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

      described_class.perform_now(*job_args)

      expect(account.reload.custom_attributes.dig('onboarding', 'help_center_generation')).to eq(
        'id' => generation_id,
        'status' => 'skipped',
        'skip_reason' => 'no website url'
      )
    end
  end

  describe 'firecrawl retries' do
    it 'transitions to skipped after retries exhaust' do
      curator = instance_double(Onboarding::HelpCenterCurator)
      allow(curator).to receive(:perform).and_raise(Firecrawl::FirecrawlError, 'rate limited')
      allow(Onboarding::HelpCenterCurator).to receive(:new).and_return(curator)

      perform_enqueued_jobs { described_class.perform_later(*job_args) }

      expect(account.reload.custom_attributes.dig('onboarding', 'help_center_generation')).to include(
        'id' => generation_id,
        'status' => 'skipped',
        'skip_reason' => a_string_including('firecrawl exhausted')
      )
    end
  end

  describe 'broadcasts' do
    it 'broadcasts generation_completed with status: skipped on CurationSkipped' do
      curator = instance_double(Onboarding::HelpCenterCurator)
      allow(curator).to receive(:perform).and_raise(
        CustomExceptions::HelpCenter::CurationSkipped, 'no website url'
      )
      allow(Onboarding::HelpCenterCurator).to receive(:new).and_return(curator)

      payload = hash_including(generation_id: generation_id, status: 'skipped', skip_reason: 'no website url')
      expect { described_class.perform_now(*job_args) }
        .to have_enqueued_job(ActionCableBroadcastJob)
        .with([admin.pubsub_token], 'help_center.generation_completed', payload)
    end
  end
end
