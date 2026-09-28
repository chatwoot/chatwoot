json.payload do
  json.array! @passkeys, partial: 'api/v1/profile/passkeys/passkey', as: :passkey
end
