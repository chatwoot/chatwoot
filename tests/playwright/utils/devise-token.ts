import crypto from 'crypto';

// Devise stores a digest of the reset password token, never the raw value, so a
// test that seeds the column has to derive the pair the same way Devise does:
//
//   key    = PBKDF2-HMAC-SHA1(secret_key_base, "Devise reset_password_token", 65536, 64)
//   digest = HMAC-SHA256(key, raw)
//
// Note these are Devise's own key generator settings, which differ from the
// Rails application key generator (1000 iterations, SHA256).
//
// The digest goes into users.reset_password_token and the raw token is what
// PUT /auth/password accepts.
const KEY_SALT = 'Devise reset_password_token';
const KEY_ITERATIONS = 65536;
const KEY_DIGEST = 'sha1';
const KEY_LENGTH = 64;

// Devise.friendly_token uses url-safe base64 with padding stripped.
function friendlyToken(length = 20) {
  return crypto
    .randomBytes(length)
    .toString('base64url')
    .slice(0, length);
}

export function generateResetPasswordToken(secretKeyBase = process.env.SECRET_KEY_BASE) {
  if (!secretKeyBase) {
    throw new Error(
      'SECRET_KEY_BASE is required to derive Devise reset password tokens. ' +
        'Set it to the same value the Chatwoot app runs with.'
    );
  }

  const key = crypto.pbkdf2Sync(
    secretKeyBase,
    KEY_SALT,
    KEY_ITERATIONS,
    KEY_LENGTH,
    KEY_DIGEST
  );
  const raw = friendlyToken();
  const digest = crypto.createHmac('sha256', key).update(raw).digest('hex');

  return { raw, digest };
}
