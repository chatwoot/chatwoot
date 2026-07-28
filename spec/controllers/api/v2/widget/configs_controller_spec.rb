require 'rails_helper'

RSpec.describe '/api/v2/widget/config', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let(:token) do
    Widget::TokenService.new(payload: { source_id: contact_inbox.source_id, inbox_id: web_widget.inbox.id }).generate_token
  end

  describe 'GET /api/v2/widget/config' do
    it 'returns the channel config, contact and ai agent availability' do
      get '/api/v2/widget/config',
          headers: { 'X-Auth-Token' => token },
          params: { website_token: web_widget.website_token },
          as: :json

      expect(response).to have_http_status(:success)
      json_response = response.parsed_body
      expect(json_response['channel_config']['website_token']).to eq(web_widget.website_token)
      expect(json_response['channel_config']['widget_color']).to eq(web_widget.widget_color)
      expect(json_response['contact']['pubsub_token']).to eq(contact_inbox.pubsub_token)
      expect(json_response['ai_agent']).to be_nil
      expect(json_response['portal']).to be_nil
    end

    it 'returns only announcements active within their schedule' do
      active = create(:widget_announcement, account: account, inbox: web_widget.inbox)
      create(:widget_announcement, account: account, inbox: web_widget.inbox, enabled: false)
      create(:widget_announcement, account: account, inbox: web_widget.inbox, starts_at: 1.day.from_now)
      create(:widget_announcement, account: account, inbox: web_widget.inbox, ends_at: 1.day.ago)

      get '/api/v2/widget/config',
          headers: { 'X-Auth-Token' => token },
          params: { website_token: web_widget.website_token },
          as: :json

      announcements = response.parsed_body['announcements']
      expect(announcements.pluck('id')).to eq([active.id])
      expect(announcements.first['level']).to eq('warning')
    end

    it 'returns the portal config when the inbox has one' do
      portal = create(:portal, account: account)
      web_widget.inbox.update!(portal: portal)

      get '/api/v2/widget/config',
          headers: { 'X-Auth-Token' => token },
          params: { website_token: web_widget.website_token },
          as: :json

      expect(response.parsed_body['portal']['slug']).to eq(portal.slug)
    end
  end
end
