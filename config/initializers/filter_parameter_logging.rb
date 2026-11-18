# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [
  :password, :secret, :_key, :auth, :crypt, :salt, :certificate, :otp, :access, :private, :protected, :ssn,
  :install_url, :otp_secret, :otp_code, :backup_code, :mfa_token, :otp_backup_codes,
  # WhatsApp Web session import: `session` is a blob of impersonation credentials
  # (Noise/Signal keys, ADV signatures). Redact the whole key so no field leaks.
  :session,
  # A native inbox's proxy URL carries the proxy's user and password.
  :proxy_url
]

# Regex to filter all occurrences of 'token' in keys except for 'website_token'
filter_regex = /\A(?!.*\bwebsite_token\b).*token/i

# Apply the regex for filtering
Rails.application.config.filter_parameters += [filter_regex]
