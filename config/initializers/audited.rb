# configuration related audited gem : https://github.com/collectiveidea/audited

Audited.config do |config|
  config.audit_class = 'Audited::Audit' # [chatpaw] was Enterprise::AuditLog
end
