class Api::V1::AuditLogsController < ApplicationController
  # Public endpoint: no authentication required
  def latest_sign_ins
    audits = Enterprise::AuditLog.where(action: 'sign_in')
                                 .select('associated_id, MAX(created_at) as latest_sign_in_at')
                                 .group(:associated_id)

    render json: audits.map { |a| { associated_id: a.associated_id, latest_sign_in_at: a.latest_sign_in_at } }
  end
end
