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
      let!(:user) { create(:user, name: 'Disabled User') }
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
      let!(:params_without_confirmed_at) do
        { user: {
          name: 'agent@example.com',
          display_name: 'agent@example.com',
          email: 'agent@example.com',
          password: 'Password1!',
          type: 'SuperAdmin'
        } }
      end
      let!(:params_with_blank_confirmed_at) do
        { user: {
          name: 'agent-2@example.com',
          display_name: 'agent-2@example.com',
          email: 'agent-2@example.com',
          password: 'Password1!',
          confirmed_at: '',
          type: 'SuperAdmin'
        } }
      end

      it 'shows the list of users' do
        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/users'
        doc = Nokogiri::HTML(response.body)
        header_texts = doc.css('table thead th').map { |header| header.text.squish }

        expect(response).to have_http_status(:success)
        expect(response.body).to include('New user')
        expect(response.body).to include(CGI.escapeHTML(user.name))
        expect(header_texts).not_to include('MFA')
      end

      it 'prefills confirmed_at on new user form' do
        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/users/new'

        expect(response).to have_http_status(:success)
        expect(response.body).to include('name="user[confirmed_at]"')
        confirmed_at_value = response.body[/name="user\[confirmed_at\]".*?value="([^"]+)"/m, 1]
        expect(confirmed_at_value).to be_present
      end

      it 'creates the new super_admin record' do
        sign_in(super_admin, scope: :super_admin)

        post '/super_admin/users', params: params

        expect(response).to redirect_to("http://www.example.com/super_admin/users/#{User.last.id}")
        expect(SuperAdmin.last.email).to eq('admin@example.com')

        post '/super_admin/users', params: params
        expect(response).to redirect_to('http://www.example.com/super_admin/users/new')
      end

      it 'creates unconfirmed users when confirmed_at is not provided in payload' do
        sign_in(super_admin, scope: :super_admin)

        post '/super_admin/users', params: params_without_confirmed_at

        expect(response).to redirect_to("http://www.example.com/super_admin/users/#{User.last.id}")
        expect(User.last).not_to be_confirmed
      end

      it 'creates unconfirmed users when confirmed_at is explicitly cleared' do
        sign_in(super_admin, scope: :super_admin)

        post '/super_admin/users', params: params_with_blank_confirmed_at

        expect(response).to redirect_to("http://www.example.com/super_admin/users/#{User.last.id}")
        expect(User.last).not_to be_confirmed
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

  describe 'POST /super_admin/users/:id/resend_confirmation' do
    def mail_jobs
      ActiveJob::Base.queue_adapter.enqueued_jobs.select do |job|
        job[:job].to_s == 'ActionMailer::MailDeliveryJob'
      end
    end

    context 'when it is an unauthenticated super admin' do
      let!(:user) { create(:user, skip_confirmation: false) }

      it 'returns unauthorized and does not enqueue a confirmation email' do
        ActiveJob::Base.queue_adapter.enqueued_jobs.clear
        post "/super_admin/users/#{user.id}/resend_confirmation"

        expect(response).to have_http_status(:redirect)
        expect(mail_jobs.count).to eq(0)
      end
    end

    context 'when it is an authenticated super admin' do
      before { sign_in(super_admin, scope: :super_admin) }

      context 'when the user is not confirmed' do
        let!(:user) { create(:user, skip_confirmation: false) }

        it 'redirects and enqueues a confirmation email' do
          ActiveJob::Base.queue_adapter.enqueued_jobs.clear
          post "/super_admin/users/#{user.id}/resend_confirmation"

          expect(response).to have_http_status(:redirect)
          expect(mail_jobs.count).to be >= 1
        end
      end

      context 'when the user is already confirmed' do
        let!(:user) { create(:user) }

        it 'redirects and does not enqueue a confirmation email' do
          expect(user).to be_confirmed
          ActiveJob::Base.queue_adapter.enqueued_jobs.clear
          post "/super_admin/users/#{user.id}/resend_confirmation"

          expect(response).to have_http_status(:redirect)
          expect(mail_jobs.count).to eq(0)
        end
      end
    end
  end

  describe 'GET /super_admin/users/:id' do
    let!(:user) { create(:user, name: 'MFA Enabled User', otp_required_for_login: true) }

    it 'shows the MFA status on the user detail page' do
      sign_in(super_admin, scope: :super_admin)

      get "/super_admin/users/#{user.id}"
      doc = Nokogiri::HTML(response.body)
      labels = doc.css('dt.attribute-label').map { |label| label.text.squish }

      expect(response).to have_http_status(:success)
      expect(labels).to include('MFA')
      expect(response.body).to include('Enabled')
      expect(response.body).to include(CGI.escapeHTML(user.name))
    end

    it 'renders an impersonation form without minting a token' do
      sign_in(super_admin, scope: :super_admin)

      expect { get "/super_admin/users/#{user.id}" }
        .not_to(change { Redis::Alfred.keys_count("USER_SSO_AUTH_TOKEN::#{user.id}::*") })

      form = Nokogiri::HTML(response.body).at_css("form[action='/super_admin/users/#{user.id}/impersonate']")

      expect(form).to be_present
      expect(form['method']).to eq('post')
      expect(form['target']).to eq('_blank')
      expect(form['rel']).to eq('noopener')
      expect(response.body).not_to include('sso_auth_token=')
    end

    it 'renders a copy impersonation link form next to the impersonate button' do
      sign_in(super_admin, scope: :super_admin)

      get "/super_admin/users/#{user.id}"
      form = Nokogiri::HTML(response.body).at_css("form[action='/super_admin/users/#{user.id}/impersonation_link']")

      expect(form).to be_present
      expect(form['method']).to eq('post')
    end
  end

  describe 'POST /super_admin/users/:id/impersonation_link' do
    let!(:user) { create(:user) }

    it 'mints a token for the signed-in super admin and returns the link' do
      sign_in(super_admin, scope: :super_admin)

      with_modified_env FRONTEND_URL: 'https://dashboard.example.com' do
        expect { post "/super_admin/users/#{user.id}/impersonation_link", as: :json }
          .to change { Redis::Alfred.keys_count("USER_SSO_AUTH_TOKEN::#{user.id}::*") }.by(1)
      end

      link = URI(response.parsed_body['url'])
      query = Rack::Utils.parse_query(link.query)

      expect(response).to have_http_status(:ok)
      expect("#{link.scheme}://#{link.host}#{link.path}").to eq('https://dashboard.example.com/app/login')
      expect(user.sso_auth_token_impersonator_id(query.fetch('sso_auth_token'))).to eq(super_admin.id)
    end

    it 'requires super admin authentication without minting a token' do
      expect { post "/super_admin/users/#{user.id}/impersonation_link" }
        .not_to(change { Redis::Alfred.keys_count("USER_SSO_AUTH_TOKEN::#{user.id}::*") })

      expect(response).to redirect_to(new_super_admin_session_path)
    end
  end

  describe 'POST /super_admin/users/:id/impersonate' do
    let!(:user) { create(:user) }

    it 'mints a token for the signed-in super admin and redirects to the frontend' do
      sign_in(super_admin, scope: :super_admin)

      with_modified_env FRONTEND_URL: 'https://dashboard.example.com' do
        expect { post "/super_admin/users/#{user.id}/impersonate" }
          .to change { Redis::Alfred.keys_count("USER_SSO_AUTH_TOKEN::#{user.id}::*") }.by(1)
      end

      location = URI(response.location)
      query = Rack::Utils.parse_query(location.query)

      expect(response).to have_http_status(:see_other)
      expect("#{location.scheme}://#{location.host}#{location.path}").to eq('https://dashboard.example.com/app/login')
      expect(query).to include('email' => user.email, 'impersonation' => 'true')
      expect(user.sso_auth_token_impersonator_id(query.fetch('sso_auth_token'))).to eq(super_admin.id)
    end

    it 'requires super admin authentication without minting a token' do
      expect { post "/super_admin/users/#{user.id}/impersonate" }
        .not_to(change { Redis::Alfred.keys_count("USER_SSO_AUTH_TOKEN::#{user.id}::*") })

      expect(response).to redirect_to(new_super_admin_session_path)
    end

    context 'with CSRF protection enabled' do
      around do |example|
        previous = ActionController::Base.allow_forgery_protection
        ActionController::Base.allow_forgery_protection = true
        example.run
      ensure
        ActionController::Base.allow_forgery_protection = previous
      end

      it 'rejects a POST without a CSRF token' do
        sign_in(super_admin, scope: :super_admin)

        expect { post "/super_admin/users/#{user.id}/impersonate" }
          .not_to(change { Redis::Alfred.keys_count("USER_SSO_AUTH_TOKEN::#{user.id}::*") })

        expect(response).to have_http_status(422)
      end
    end
  end
end
