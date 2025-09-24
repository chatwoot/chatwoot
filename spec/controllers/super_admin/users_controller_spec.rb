require 'rails_helper'

RSpec.describe 'Super Admin Users API', type: :request do
  let(:super_admin) { create(:super_admin) }

  describe 'GET /super_admin/users' do
    context 'when it is an unauthenticated super admin' do
      it 'returns unauthorized' do
        get '/super_admin/users'
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an authenticated super admin' do
      let!(:user) { create(:user) }
      let!(:params) do
        { user: {
          name: 'admin@example.com',
          display_name: 'admin@example.com',
          email: 'admin@example.com',
          password: 'Password1!',
          confirmed_at: '2023-03-20 22:32:41',
          type: 'SuperAdmin'
        } }
      end

      it 'shows the list of users' do
        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/users'
        expect(response).to have_http_status(:success)
        expect(response.body).to include('New user')
        expect(response.body).to include(CGI.escapeHTML(user.name))
      end

      it 'creates the new super_admin record' do
        sign_in(super_admin, scope: :super_admin)

        post '/super_admin/users', params: params

        expect(response).to redirect_to("http://www.example.com/super_admin/users/#{User.last.id}")
        expect(SuperAdmin.last.email).to eq('admin@example.com')

        post '/super_admin/users', params: params
        expect(response).to redirect_to('http://www.example.com/super_admin/users/new')
      end
    end
  end

  describe 'DELETE /super_admin/users/:id/avatar' do
    let!(:user) { create(:user, :with_avatar) }

    context 'when it is an unauthenticated super admin' do
      it 'returns unauthorized' do
        delete "/super_admin/users/#{user.id}/avatar", params: { attachment_id: user.avatar.id }
        expect(response).to have_http_status(:redirect)
        expect(user.reload.avatar).to be_attached
      end
    end

    context 'when it is an authenticated super admin' do
      it 'destroys the avatar' do
        sign_in(super_admin, scope: :super_admin)
        delete "/super_admin/users/#{user.id}/avatar", params: { attachment_id: user.avatar.id }
        expect(response).to have_http_status(:redirect)
        expect(user.reload.avatar).not_to be_attached
      end
    end
  end

  describe 'PATCH /super_admin/users/:id' do
    let!(:user) { create(:user) }
    let(:request_path) { "/super_admin/users/#{user.id}" }

    before { sign_in(super_admin, scope: :super_admin) }

    it 'skips reconfirmation when confirmed_at is provided' do
      ActiveJob::Base.queue_adapter.enqueued_jobs.clear
      patch request_path, params: { user: { email: 'updated@example.com', confirmed_at: Time.current } }

      expect(response).to have_http_status(:redirect)
      expect(user.reload.email).to eq('updated@example.com')
      expect(user.reload.unconfirmed_email).to be_nil

      mail_jobs = ActiveJob::Base.queue_adapter.enqueued_jobs.select do |job|
        job[:job].to_s == 'ActionMailer::MailDeliveryJob'
      end
      expect(mail_jobs.count).to eq(0)
    end

    it 'does not skip reconfirmation when confirmed_at is blank' do
      ActiveJob::Base.queue_adapter.enqueued_jobs.clear
      patch request_path, params: { user: { email: 'updated-again@example.com' } }

      expect(response).to have_http_status(:redirect)
      expect(user.reload.unconfirmed_email).to eq('updated-again@example.com')

      mail_jobs = ActiveJob::Base.queue_adapter.enqueued_jobs.select do |job|
        job[:job].to_s == 'ActionMailer::MailDeliveryJob'
      end
      expect(mail_jobs.count).to be >= 1
    end
  end
end
