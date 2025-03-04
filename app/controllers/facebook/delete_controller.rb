class Facebook::DeleteController < ApplicationController
  include FacebookConcern

  def create
    signed_request = params['signed_request']
    payload = parse_fb_signed_request(signed_request)
    id_to_process = payload['user_id']

    mark_deleting(id_to_process)
    Webhooks::FacebookDeleteJob.perform_later(id_to_process)
    status_url = "#{app_url_base}/facebook/confirm/#{id_to_process}"

    # IMPORTANT: Do not change the response format below.
    # Facebook's Data Deletion Request system specifically expects responses in this format
    # with a 'url' for status confirmation and a 'confirmation_code' field.
    # See: https://developers.facebook.com/docs/development/create-an-app/app-dashboard/data-deletion-callback/#implementing
    render json: { url: status_url, confirmation_code: id_to_process }, status: :ok
  rescue InvalidDigestError
    render json: { error: 'Invalid signature' }, status: :unprocessable_entity
  end
end
