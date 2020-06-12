require 'rails_helper'

RSpec.describe HookJob, type: :job do
  subject(:job) { described_class.perform_later(hook, message) }

  let(:account) { create(:account) }
  let(:hook) { create(:integrations_hook, account: account) }
  let(:message) { create(:message) }

  it 'queues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(hook, message)
      .on_queue('integrations')
  end
end
