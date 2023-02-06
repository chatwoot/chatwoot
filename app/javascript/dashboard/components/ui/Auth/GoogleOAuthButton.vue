<template>
  <div>
    <div v-if="showSeparator" class="separator">
      OR
    </div>
    <a :href="getGoogleAuthUrl()">
      <button class="button large expanded button__google_login">
        <img
          src="/assets/images/auth/google.svg"
          alt="Google Logo"
          class="icon"
        />
        <slot>{{ $t('LOGIN.OAUTH.GOOGLE_LOGIN') }}</slot>
      </button>
    </a>
  </div>
</template>

<script>
export default {
  props: {
    showSeparator: {
      type: Boolean,
      default: true,
    },
  },
  methods: {
    getGoogleAuthUrl() {
      // Ideally a request to /auth/google_oauth2 should be made
      // Creating the URL manually because the devise-token-auth with
      // omniauth has a standing issue on redirecting the post request
      // https://github.com/lynndylanhurley/devise_token_auth/issues/1466
      const baseUrl =
        'https://accounts.google.com/o/oauth2/auth/oauthchooseaccount';
      const clientId = window.chatwootConfig.googleOAuthClientId;
      const redirectUri = window.chatwootConfig.googleOAuthCallbackUrl;
      const responseType = 'code';
      const scope = 'email profile';

      // Build the query string
      const queryString = new URLSearchParams({
        client_id: clientId,
        redirect_uri: redirectUri,
        response_type: responseType,
        scope: scope,
      }).toString();

      // Construct the full URL
      return `${baseUrl}?${queryString}`;
    },
    showGoogleOAuth() {
      return Boolean(window.chatwootConfig.googleOAuthClientId);
    },
  },
};
</script>

<style lang="scss" scoped>
.separator {
  display: flex;
  align-items: center;
  margin: 2rem 0rem;
  gap: 1rem;
  color: var(--s-300);
  font-size: var(--font-size-small);
  &::before,
  &::after {
    content: '';
    flex: 1;
    height: 1px;
    background: var(--s-100);
  }
}
.button__google_login {
  background: var(--white);
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  border: 1px solid var(--s-100);
  color: var(--b-800);
}
</style>
