require 'rails_helper'

RSpec.describe 'Resend Confirmations API', type: :request do
  describe 'POST /resend_confirmation' do
    let(:email) { 'unconfirmed@example.com' }

    context 'when the user exists and is unconfirmed' do
      before { create(:user, email: email, skip_confirmation: false) }

      it 'sends confirmation instructions and returns 200' do
        expect do
          post '/resend_confirmation', params: { email: email }, as: :json
        end.to have_enqueued_mail(Devise::Mailer, :confirmation_instructions)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the user exists and is already confirmed' do
      before { create(:user, email: email) }

      it 'returns 200 without sending confirmation' do
        expect do
          post '/resend_confirmation', params: { email: email }, as: :json
        end.not_to have_enqueued_mail(Devise::Mailer, :confirmation_instructions)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the email does not exist' do
      it 'returns 200 without leaking email existence' do
        post '/resend_confirmation', params: { email: 'nobody@example.com' }, as: :json

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when hCaptcha is configured' do
      before do
        create(:user, email: email, skip_confirmation: false)
        allow(ChatwootCaptcha).to receive(:new).and_return(captcha)
      end

      context 'with a valid captcha response' do
        let(:captcha) { instance_double(ChatwootCaptcha, valid?: true) }

        it 'sends confirmation instructions' do
          expect do
            post '/resend_confirmation',
                 params: { email: email, h_captcha_client_response: 'valid-token' },
                 as: :json
          end.to have_enqueued_mail(Devise::Mailer, :confirmation_instructions)

          expect(response).to have_http_status(:ok)
        end
      end

      context 'with an invalid captcha response' do
        let(:captcha) { instance_double(ChatwootCaptcha, valid?: false) }

        it 'returns 200 without sending confirmation' do
          expect do
            post '/resend_confirmation',
                 params: { email: email, h_captcha_client_response: 'bad-token' },
                 as: :json
          end.not_to have_enqueued_mail(Devise::Mailer, :confirmation_instructions)

          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
