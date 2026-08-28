json.feature_available Chatwoot.mfa_enabled?
json.enabled @user.mfa_enabled?
if Chatwoot.mfa_enabled?
  json.backup_codes_generated @user.mfa_service.backup_codes_generated?
  json.remaining_backup_codes @user.mfa_service.remaining_backup_codes_count
end
