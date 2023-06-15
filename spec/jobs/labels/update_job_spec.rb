require 'rails_helper'

RSpec.describe Labels::UpdateJob do
  subject(:job) { described_class.perform_later(new_label_title, old_label_title, account_id) }

  let(:new_label_title) { 'new-title' }
  let(:old_label_title) { 'old-title' }
  let(:account_id) { 1 }

  it 'queues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(new_label_title, old_label_title, account_id)
      .on_queue('default')
  end
end
