require 'rails_helper'

RSpec.describe Labels::RemoveAssociationsJob do
  subject(:job) do
    described_class.perform_later(
      label_title: label_title,
      account_id: account_id,
      tagging_ids: tagging_ids
    )
  end

  let(:label_title) { 'billing' }
  let(:account_id) { 1 }
  let(:tagging_ids) { [10, 20, 30] }

  it 'queues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(label_title: label_title, account_id: account_id, tagging_ids: tagging_ids)
      .on_queue('default')
  end
end
