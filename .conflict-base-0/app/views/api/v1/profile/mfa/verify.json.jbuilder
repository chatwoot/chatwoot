json.enabled @user.mfa_enabled?
json.backup_codes @backup_codes if @backup_codes.present?
