require 'digest'
require 'base64'

# http://localhost:3000/zalo/callback/connect?account_id=1&state=976112031aad6a3763b9bb668bfd9ff06ffd9c6927a&oa_id=1423847451268726170&code=yAmevqOEwGBNWNFmHnYl2zUgK_ew8Bm_dQuY_pTvYpopwbpl56hv2h_96EWLH-4O-yWsn6TxhJJOa3NwNWVbAVo2VCnIAAaowf1amH8XeGVW-plwNaQaCjA5VEHy2hKNw9i6g4KKyGokpqtA0HQ33E-u3Tz4KeD3kOX2vpSMkGoFXJciD5AD9CoUJzXc38zNjSTEaJ5kmnl3vKxWQcxS48UFCSKmSUjoriyIx08Zcdwve0ICDZZCOOwhIkW2MDmujOiVb5fmzWgFl7Z5EqczSlMF3OPS5E57jEewlGC6yHpehpP7R0ZMWO2-ImJ-4QteKPDI2OajlBKFygfoWGaUoJlk6YmmbE-1iJ4wMdqlCFsbaUe14ty0aRhXYZWf4ZM7c_6o2n8LJe3RxjHYHdHSkuMLhrf-KRLKVdc670&state=976112031aad6a3763b9bb668bfd9ff06ffd9c6927a&code_challenge=hLJ1j1Lrw6Zsmxex2PBDoOfbaLxeQoij9l4ae34KKuU

class Zalo::CallbackController < ApplicationController
  VERIFIER_LENGTH = 43

  def new
    state = Random.hex(25).first(VERIFIER_LENGTH)
    challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(state), padding: false)

    auth_options = {
      app_id: Integrations::Zalo::Constants.app_id,
      redirect_uri: connect_zalo_callback_index_url(account_id: params[:account_id], state: state),
      state: state,
      code_challenge: challenge
    }

    redirect_to "https://oauth.zaloapp.com/v4/oa/permission?#{auth_options.to_query}", allow_other_host: true
  end

  def connect
    if permitted_params[:code] && permitted_params[:account_id] && permitted_params[:oa_id]
      verify_request = Integrations::Zalo::VerifyRequestService.new(permitted_params[:state], permitted_params[:code_challenge],
                                                                    permitted_params[:code])

      inbox = create_inbox
      redirect_to app_inbox_agents_url(account_id: account.id, inbox_id: inbox.id)
    else
      redirect_to zalo_app_redirect_url(error: 'Invalid parameters')
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    redirect_to zalo_app_redirect_url(error: e.message)
  end

  private

  def zalo_app_redirect_url(error: nil)
    app_new_zalo_inbox_url(account_id: account.id, error: error)
  end

  def account
    @account ||= Account.find(permitted_params[:account_id])
  end

  def permitted_params
    @permitted_params ||= params.permit(:code, :account_id, :oa_id, :state, :code_challenge)
  end

  def create_inbox
    data = {
      oa_id: permitted_params[:oa_id],
      account_id: permitted_params[:account_id].to_i,
      auth_code: permitted_params[:code]
    }
    # Shopee::CreateInboxService.new(data).perform
  end
end
