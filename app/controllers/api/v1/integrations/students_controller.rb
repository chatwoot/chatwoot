# Inbound webhook for Firebase student-form document events.
#
# Authenticated with:
#   Authorization: Bearer <STUDENT_FORM_INTEGRATION_SECRET>
#
# Expected body:
#   {
#     "event": "student.created",
#     "student": {
#       "id": "<firestore_doc_id>",
#       "name": "...",
#       "number_phone": "0555...",
#       "study_division": "...",
#       "ip": "..."
#     }
#   }
class Api::V1::Integrations::StudentsController < ApplicationController
  before_action :authenticate_integration_secret!

  def create
    contact = Integrations::StudentSyncService.new(
      account: target_account,
      student: student_params.to_h.symbolize_keys
    ).perform

    render json: {
      id: contact.id,
      identifier: contact.identifier,
      name: contact.name,
      phone_number: contact.phone_number,
      custom_attributes: contact.custom_attributes
    }, status: :ok
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue KeyError => e
    render_internal_server_error("#{e.key} is not configured")
  end

  private

  def authenticate_integration_secret!
    expected = ENV.fetch('STUDENT_FORM_INTEGRATION_SECRET')
    provided = bearer_token

    return render_unauthorized('Unauthorized') if provided.blank?
    return render_unauthorized('Unauthorized') unless provided.bytesize == expected.bytesize
    return if ActiveSupport::SecurityUtils.secure_compare(provided, expected)

    render_unauthorized('Unauthorized')
  rescue KeyError
    render_internal_server_error('STUDENT_FORM_INTEGRATION_SECRET is not configured')
  end

  def bearer_token
    header = request.headers['Authorization'].to_s
    return if header.blank?

    scheme, token = header.split(' ', 2)
    return unless scheme&.casecmp('Bearer')&.zero?

    token.presence
  end

  def target_account
    Account.find(ENV.fetch('STUDENT_FORM_ACCOUNT_ID'))
  end

  def student_params
    params.require(:student).permit(
      :id,
      :name,
      :number_phone,
      :phone,
      :study_division,
      :ip,
      :type,
      :link_code,
      :created_at
    )
  end
end
