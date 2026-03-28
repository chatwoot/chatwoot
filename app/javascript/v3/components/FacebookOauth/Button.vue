<script>
export default {
  computed: {
    hubUrl() {
      return window.chatwootConfig.hubUrl || '';
    },
  },
  methods: {
    getFacebookAuthUrl() {
      const hubUrl = this.hubUrl;
      if (!hubUrl) return '#';

      const params = new URLSearchParams({
        redirect_uri: `${window.location.origin}/omniauth/igarahub/callback`,
        client_id: 'nexus',
        state: crypto.randomUUID(),
      });
      return `${hubUrl}/api/v1/auth/social/facebook?${params}`;
    },
  },
};
</script>

<template>
  <div class="flex flex-col">
    <a
      :href="getFacebookAuthUrl()"
      class="inline-flex justify-center w-full px-4 py-3 bg-n-background dark:bg-n-solid-3 items-center rounded-md shadow-sm ring-1 ring-inset ring-n-container dark:ring-n-container focus:outline-offset-0 hover:bg-n-alpha-2 dark:hover:bg-n-alpha-2"
    >
      <svg
        width="20"
        height="20"
        viewBox="0 0 24 24"
        fill="#1877F2"
        class="shrink-0"
      >
        <path
          d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"
        />
      </svg>
      <span class="ml-2 text-base font-medium text-n-slate-12">
        {{ $t('LOGIN.OAUTH.FACEBOOK_LOGIN') }}
      </span>
    </a>
  </div>
</template>
