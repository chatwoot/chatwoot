require 'rails_helper'

RSpec.describe '/api/v1/accounts/:account_id/inboxes/:inbox_id/widget_announcements', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:base_url) { "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/widget_announcements" }

  describe 'GET index' do
    let!(:announcement) { create(:widget_announcement, account: account, inbox: inbox) }

    it 'returns the inbox announcements for an administrator' do
      get base_url, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload'].pluck('id')).to eq([announcement.id])
    end

    it 'is unauthorized for an agent' do
      get base_url, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST create' do
    it 'creates an announcement with a schedule' do
      post base_url,
           headers: admin.create_new_auth_token,
           params: {
             widget_announcement: {
               title: 'Maintenance window', message: 'Slower replies tonight',
               level: 'warning', starts_at: 1.hour.from_now, ends_at: 3.hours.from_now
             }
           },
           as: :json

      expect(response).to have_http_status(:success)
      expect(inbox.widget_announcements.count).to eq(1)
      expect(inbox.widget_announcements.first.level).to eq('warning')
    end

    it 'rejects an end time before the start time' do
      post base_url,
           headers: admin.create_new_auth_token,
           params: {
             widget_announcement: { title: 'Bad window', starts_at: 2.hours.from_now, ends_at: 1.hour.from_now }
           },
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH update' do
    let!(:announcement) { create(:widget_announcement, account: account, inbox: inbox) }

    it 'toggles the enabled flag' do
      patch "#{base_url}/#{announcement.id}",
            headers: admin.create_new_auth_token,
            params: { widget_announcement: { enabled: false } },
            as: :json

      expect(response).to have_http_status(:success)
      expect(announcement.reload.enabled).to be(false)
    end
  end

  describe 'DELETE destroy' do
    let!(:announcement) { create(:widget_announcement, account: account, inbox: inbox) }

    it 'removes the announcement' do
      delete "#{base_url}/#{announcement.id}", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(inbox.widget_announcements.count).to eq(0)
    end
  end
end
