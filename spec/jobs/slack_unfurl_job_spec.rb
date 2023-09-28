require 'rails_helper'

RSpec.describe SlackUnfurlJob do
  subject(:job) { described_class.perform_later(params: link_shared, integration_hook: hook) }

  let(:account) { create(:account) }
  let(:hook) { create(:integrations_hook, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let!(:conversation) { create(:conversation, inbox: inbox) }

  let(:link_shared) do
    {
      team_id: 'TLST3048H',
      api_app_id: 'A012S5UETV4',
      event: link_shared_event.merge(links: [{
                                       url: "https://qa.chatwoot.com/app/accounts/1/conversations/#{conversation.display_id}",
                                       domain: 'qa.chatwoot.com'
                                     }]),
      type: 'event_callback',
      event_time: 1_588_623_033
    }
  end

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .on_queue('low')
  end

  it 'calls the SlackLinkUnfurlService' do
    slack_link_unfurl_service = instance_double(Integrations::Slack::SlackLinkUnfurlService)

    expect(Integrations::Slack::SlackLinkUnfurlService).to receive(:new)
      .with(params: link_shared, integration_hook: hook)
      .and_return(slack_link_unfurl_service)
    expect(slack_link_unfurl_service).to receive(:perform)
    described_class.perform_now(link_shared, hook)
  end
end
