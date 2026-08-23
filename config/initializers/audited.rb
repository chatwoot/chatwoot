# configuration related audited gem : https://github.com/collectiveidea/audited

Audited.config do |config|
  config.audit_class = 'Audited::Audit' # [whisker] was Enterprise::AuditLog
end
