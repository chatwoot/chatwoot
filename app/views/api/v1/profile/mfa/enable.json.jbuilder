issuer = Rails.application.class.module_parent.name
label = "#{issuer}:#{@user.email}"

json.provisioning_url @user.otp_provisioning_uri(label, issuer: issuer)
json.secret @user.otp_secret
json.backup_codes @backup_codes
