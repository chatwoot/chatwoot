# config/initializers/audit.rb
Audited.config do |config|
  config.audit_class = 'CustomAudit'
end
