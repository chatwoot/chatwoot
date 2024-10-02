<script>
import SimpleDivider from '../Divider/SimpleDivider.vue';

export default {
  components: {
    SimpleDivider,
  },
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
  },
};
</script>

<!-- eslint-disable vue/no-unused-refs -->
<!-- Added ref for writing specs -->
<template>
  <div class="flex flex-col">
    <a
      :href="getGoogleAuthUrl()"
      class="inline-flex justify-center w-full px-4 py-3 bg-white rounded-md shadow-sm ring-1 ring-inset ring-slate-200 dark:ring-slate-600 hover:bg-slate-50 focus:outline-offset-0 dark:bg-slate-700 dark:hover:bg-slate-700"
    >
      <span class="i-logos-google-icon h-6" />
      <span class="ml-2 text-base font-medium text-slate-600 dark:text-white">
        {{ $t('LOGIN.OAUTH.GOOGLE_LOGIN') }}
      </span>
    </a>
    <SimpleDivider
      v-if="showSeparator"
      ref="divider"
      :label="$t('COMMON.OR')"
      class="uppercase"
    />
  </div>
</template>
