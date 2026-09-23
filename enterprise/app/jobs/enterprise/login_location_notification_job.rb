class Enterprise::LoginLocationNotificationJob < ApplicationJob
  queue_as :low

  DISTINCT_IP_LIMIT = 50
  HISTORY_WINDOW = 90.days

  def perform(user_id, recipient_email, device, before_audit_id)
    return unless LoginLocationNotification.enabled?

    device = device.to_h.symbolize_keys
    return if recipient_email.blank? || device[:ip].blank?

    meta = new_location_meta(user_id, device[:ip], before_audit_id)
    return unless meta

    Enterprise::LoginLocationMailer.new_location(meta.merge(device).merge(email: recipient_email)).deliver_later
  end

  private

  def new_location_meta(user_id, remote_address, before_audit_id)
    lookup = IpLookupService.new
    result = lookup.perform(remote_address)
    return if result&.country.blank?

    return unless location_unrecognized?(lookup, user_id, before_audit_id, result.country)

    { city: result.city, country: result.country, ip: remote_address }
  end

  def location_unrecognized?(lookup, user_id, before_audit_id, country)
    history = sign_ins_before_current(user_id, before_audit_id)
    recent = recent_countries(lookup, history)
    return recent.exclude?(country) if recent.present?

    dormant_return?(history)
  end

  def sign_ins_before_current(user_id, before_audit_id)
    scope = Enterprise::AuditLog.where(user_id: user_id, action: 'sign_in').where.not(remote_address: nil)
    scope = scope.where(id: ...before_audit_id) if before_audit_id.present?
    scope
  end

  def recent_countries(lookup, history)
    history.where(created_at: HISTORY_WINDOW.ago..)
           .group(:remote_address)
           .order(Arel.sql('MAX(created_at) DESC'))
           .limit(DISTINCT_IP_LIMIT)
           .pluck(:remote_address)
           .filter_map { |ip| lookup.perform(ip)&.country }
           .uniq
  end

  def dormant_return?(history)
    history.exists?
  end
end
