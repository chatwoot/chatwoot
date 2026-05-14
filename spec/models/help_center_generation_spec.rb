require 'rails_helper'

RSpec.describe HelpCenterGeneration do
  let(:account) { create(:account) }
  let(:portal) { create(:portal, account_id: account.id) }
  let(:plan) { { 'articles' => [{ 'title' => 'A' }, { 'title' => 'B' }], 'allowed_urls' => ['https://x.test/a'] } }

  describe 'after_create_commit' do
    it 'enqueues the article generation job' do
      expect do
        account.help_center_generations.create!(portal: portal)
      end.to have_enqueued_job(Onboarding::HelpCenterArticleGenerationJob)
    end
  end

  describe '#allowed_urls' do
    it 'returns the array stored on the plan' do
      generation = described_class.create!(account: account, portal: portal, plan: plan)
      expect(generation.allowed_urls).to eq(['https://x.test/a'])
    end

    it 'returns [] when the plan is blank' do
      generation = described_class.create!(account: account, portal: portal)
      expect(generation.allowed_urls).to eq([])
    end
  end

  describe '#start_curating!' do
    it 'transitions pending → curating and stamps started_at' do
      generation = described_class.create!(account: account, portal: portal)
      expect { generation.start_curating! }.to change(generation, :status).from('pending').to('curating')
      expect(generation.started_at).to be_present
    end

    it 'is a no-op when the generation is not pending' do
      generation = described_class.create!(account: account, portal: portal, status: :generating)
      expect { generation.start_curating! }.not_to(change { generation.reload.status })
    end
  end

  describe '#mark_skipped!' do
    it 'records the reason, status, and finished_at' do
      generation = described_class.create!(account: account, portal: portal, status: :curating)
      generation.mark_skipped!(reason: 'no website')
      expect(generation).to be_skipped
      expect(generation.skip_reason).to eq('no website')
      expect(generation.finished_at).to be_present
    end
  end

  describe '#record_article_finished!' do
    it 'increments articles_finished atomically' do
      generation = described_class.create!(account: account, portal: portal, status: :generating, plan: plan)
      expect { generation.record_article_finished! }.to change(generation, :articles_finished).by(1)
    end
  end

  describe '#complete_if_finished!' do
    let(:generation) do
      described_class.create!(
        account: account, portal: portal, status: :generating, plan: plan, articles_finished: 2
      )
    end

    it 'transitions to completed and returns true when articles_finished meets planned_total' do
      expect(generation.complete_if_finished!).to be(true)
      expect(generation.reload).to be_completed
      expect(generation.finished_at).to be_present
    end

    it 'returns false on a second call that finds the row already completed' do
      generation.complete_if_finished!
      expect(generation.complete_if_finished!).to be(false)
    end

    it 'returns false when articles_finished is below planned_total' do
      generation.update!(articles_finished: 1)
      expect(generation.complete_if_finished!).to be(false)
      expect(generation.reload).to be_generating
    end
  end
end
