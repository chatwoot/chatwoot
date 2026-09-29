json.payload do
  json.array! @passkeys, partial: 'api/v1/profile/passkeys/passkey', as: :passkey
end
json.second_factor_required current_user.mfa_enabled?
