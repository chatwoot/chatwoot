class ImpersonationLogger
  def self.log(event, user:, super_admin_id:, ip:, via: nil)
    super_admin = User.find_by(id: super_admin_id) if super_admin_id
    fields = {
      super_admin_id: super_admin_id,
      super_admin_email: super_admin&.email,
      user_id: user.id,
      user_email: user.email,
      account_ids: user.account_ids.join(','),
      ip: ip,
      via: via
    }.compact
    Rails.logger.info("[SUPER_ADMIN_IMPERSONATION] #{event} #{fields.map { |key, value| "#{key}=#{value}" }.join(' ')}")
  end
end
