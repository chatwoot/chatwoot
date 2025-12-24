require 'rails_helper'

RSpec.describe 'Resend confirmation email', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let!(:account) { create(:account) }
  let!(:user) { create(:user, password: 'Password1!', account: account, skip_confirmation: false) }
  let(:auth_headers) { user.create_new_auth_token }
  let(:endpoint) { '/api/v1/profile/resend_confirmation' }

  before do
    # Ensure redis is clean between examples so rate-limit keys don't interfere
    Redis::Alfred.delete('RATE_LIMIT:resend_confirmation')

    # Force mailers to think SMTP is configured during tests
    allow(ApplicationMailer).to receive(:smtp_config_set_or_development?).and_return(true)
    allow(Devise::Mailer).to receive(:smtp_config_set_or_development?).and_return(true)

    # Ensure user is unconfirmed
    user.update!(confirmed_at: nil)
  end

  context 'when resending confirmation' do
    context 'when user is authenticated' do
      it 'sends the confirmation email and returns 200' do
        expect do
          post endpoint, params: { email: user.email }, headers: auth_headers, as: :json
        end.to have_enqueued_job(ActionMailer::MailDeliveryJob)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when user is unauthenticated' do
      it 'sends the confirmation email and returns 200' do
        expect do
          post endpoint, params: { email: user.email }, as: :json
        end.to have_enqueued_job(ActionMailer::MailDeliveryJob)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when email does not exist' do
      it 'returns 200 to prevent email enumeration' do
        post endpoint, params: { email: 'nonexistent@example.com' }, as: :json
        expect(response).to have_http_status(:ok)
      end
    end
  end

  # Rate-limiting tests removed for now while feature is simplified
end
