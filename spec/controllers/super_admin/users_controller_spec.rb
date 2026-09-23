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
  end

  describe 'SES suppression diagnostic' do
    let!(:user) { create(:user, email: 'bounced@example.com') }
    let(:suppression) { instance_double(Email::SesSuppressionService) }

    before do
      sign_in(super_admin, scope: :super_admin)
      allow(Email::SesSuppressionService).to receive(:new).and_return(suppression)
    end

    context 'when SES suppression is not configured' do
      it 'returns not found for every action' do
        %w[check_email_suppression clear_email_suppression send_test_email].each do |action|
          post "/super_admin/users/#{user.id}/#{action}"
          expect(response).to have_http_status(:not_found)
        end
      end

      it 'hides the diagnostic buttons' do
        get "/super_admin/users/#{user.id}"

        expect(response.body).not_to include('Check email delivery')
        expect(response.body).not_to include('Send test email')
      end
    end

    context 'when SES suppression is configured' do
      around do |example|
        with_modified_env(SES_SUPPRESSION_ROLE_ARN: 'arn:aws:iam::123456789012:role/test') { example.run }
      end

      it 'shows check and test buttons but not clear before a check' do
        get "/super_admin/users/#{user.id}"

        expect(response.body).to include('Check email delivery')
        expect(response.body).to include('Send test email')
        expect(response.body).not_to include('Unblock email')
      end

      it 'shows an active clear button after a bounce check' do
        get "/super_admin/users/#{user.id}", params: { suppression: 'bounce' }

        button = Nokogiri::HTML(response.body).at_css('button:contains("Unblock email")')
        expect(button).to be_present
        expect(button['disabled']).to be_nil
      end

      it 'shows a disabled clear button after a complaint check' do
        get "/super_admin/users/#{user.id}", params: { suppression: 'complaint' }

        button = Nokogiri::HTML(response.body).at_css('button:contains("Unblock email")')
        expect(button['disabled']).to be_present
        expect(button['title']).to eq('Blocked after a spam complaint. Escalate to engineering.')
      end

      it 'reports an address that is not suppressed' do
        allow(suppression).to receive(:lookup).with(user.email).and_return(status: :not_suppressed)

        post "/super_admin/users/#{user.id}/check_email_suppression"

        expect(response).to redirect_to("/super_admin/users/#{user.id}?suppression=not_suppressed")
        expect(flash[:notice]).to eq('Emails to bounced@example.com are not blocked.')
      end

      it 'reports a bounce with its date' do
        travel_to Time.utc(2026, 9, 6, 10, 0, 0)
        since = Time.utc(2026, 9, 1, 10, 0, 0)
        allow(suppression).to receive(:lookup).with(user.email).and_return(status: :bounce, since: since)

        post "/super_admin/users/#{user.id}/check_email_suppression"

        expect(response).to redirect_to("/super_admin/users/#{user.id}?suppression=bounce")
        expect(flash[:alert]).to eq('Emails to bounced@example.com are blocked because one bounced on 1 Sep 2026 (5 days ago). ' \
                                    'Unblock it, then send a test email.')
      end

      it 'reports a complaint as an error with an escalation note' do
        travel_to Time.utc(2026, 9, 6, 10, 0, 0)
        since = Time.utc(2026, 9, 1, 10, 0, 0)
        allow(suppression).to receive(:lookup).with(user.email).and_return(status: :complaint, since: since)

        post "/super_admin/users/#{user.id}/check_email_suppression"

        expect(response).to redirect_to("/super_admin/users/#{user.id}?suppression=complaint")
        expect(flash[:error]).to eq('Emails to bounced@example.com are blocked because the user marked one as spam on 1 Sep 2026 (5 days ago). ' \
                                    'Escalate to engineering.')
      end

      it 'reports a failed lookup' do
        allow(suppression).to receive(:lookup).with(user.email).and_return(status: :unavailable)

        post "/super_admin/users/#{user.id}/check_email_suppression"

        expect(response).to redirect_to("/super_admin/users/#{user.id}?suppression=unavailable")
        expect(flash[:alert]).to eq("Couldn't check delivery for bounced@example.com. Try again, or escalate to engineering.")
      end

      it 'clears the suppression and logs who did it' do
        allow(suppression).to receive(:clear!)
        allow(Rails.logger).to receive(:info)

        post "/super_admin/users/#{user.id}/clear_email_suppression"

        expect(suppression).to have_received(:clear!).with(user.email)
        expect(Rails.logger).to have_received(:info).with(a_string_including('ses_suppression_cleared', super_admin.email, user.email))
        expect(flash[:notice]).to eq('Unblocked bounced@example.com. Send a test email to confirm delivery.')
      end

      it 'reports a failed clear' do
        allow(suppression).to receive(:clear!).and_raise(StandardError, 'boom')

        post "/super_admin/users/#{user.id}/clear_email_suppression"

        expect(flash[:error]).to eq("Couldn't unblock bounced@example.com (boom). Escalate to engineering.")
      end

      it 'queues a test email and logs who sent it' do
        allow(Rails.logger).to receive(:info)

        expect do
          post "/super_admin/users/#{user.id}/send_test_email"
        end.to have_enqueued_mail(EmailDeliveryTestMailer, :delivery_test).with(user)

        expect(Rails.logger).to have_received(:info).with(a_string_including('ses_test_email_sent', super_admin.email, user.email))
        expect(flash[:notice]).to eq('Test email on its way to bounced@example.com. Ask the user to check their inbox and spam folder.')
      end
    end
  end
end
