# configuration related audited gem : https://github.com/collectiveidea/audited

Audited.config do |config|
  # Use Enterprise AuditLog only if Enterprise edition is available
  if defined?(Enterprise::AuditLog)
    config.audit_class = 'Enterprise::AuditLog'
  else
    # Use default audit class for OSS version
    config.audit_class = Audited::Audit
  end
end
