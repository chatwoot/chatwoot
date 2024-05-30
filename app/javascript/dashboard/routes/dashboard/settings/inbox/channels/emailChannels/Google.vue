<template>
  <div
    class="border border-slate-25 dark:border-slate-800/60 bg-white dark:bg-slate-900 h-full p-6 w-full max-w-full md:w-3/4 md:max-w-[75%] flex-shrink-0 flex-grow-0"
  >
    <settings-sub-page-header
      :header-title="$t('INBOX_MGMT.ADD.GOOGLE.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.GOOGLE.DESCRIPTION')"
    />
    <a
      :href="getGoogleAuthUrl()"
      class="inline-flex justify-center rounded-md mt-5 bg-white py-3 px-4 shadow-sm ring-1 ring-inset ring-slate-200 dark:ring-slate-600 hover:bg-slate-50 focus:outline-offset-0 dark:bg-slate-700 dark:hover:bg-slate-700"
    >
      <img src="/assets/images/auth/google.svg" alt="Google Logo" class="h-6" />
      <span class="text-base font-medium ml-2 text-slate-600 dark:text-white">
        {{ $t('INBOX_MGMT.ADD.GOOGLE.SIGN_IN') }}
      </span>
    </a>
  </div>
</template>
<script setup>
import { joinUrl } from 'shared/helpers/joinUrl';
import SettingsSubPageHeader from '../../../SettingsSubPageHeader.vue';

function getRedirectUrl() {
  const baseUrl = window.chatwootConfig.hostURL;
  const path = '/google/callback';
  return joinUrl(baseUrl, path);
}

function getGoogleAuthUrl() {
  const baseUrl =
    'https://accounts.google.com/o/oauth2/auth/oauthchooseaccount';
  const clientId = window.chatwootConfig.googleOAuthClientId;
  const redirectUrl = getRedirectUrl();
  const responseType = 'code';
  const scope = 'email profile https://mail.google.com/';

  // Build the query string
  const queryString = new URLSearchParams({
    client_id: clientId,
    redirect_uri: redirectUrl,
    response_type: responseType,
    scope: scope,
  }).toString();

  // Construct the full URL
  return `${baseUrl}?${queryString}`;
}
</script>
