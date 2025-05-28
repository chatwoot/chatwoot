<script>
/* global FB */
import InboxReconnectionRequired from '../components/InboxReconnectionRequired.vue';
import { useAlert } from 'dashboard/composables';

import { loadScript } from 'dashboard/helper/DOMHelpers';
import * as Sentry from '@sentry/vue';

export default {
  components: {
    InboxReconnectionRequired,
  },
  props: {
    inbox: {
      type: Object,
      required: true,
    },
  },
  computed: {
    inboxId() {
      return this.inbox.id;
    },
  },
  mounted() {
    window.fbAsyncInit = this.runFBInit;
  },
  methods: {
    runFBInit() {
      FB.init({
        appId: window.chatwootConfig.fbAppId,
        xfbml: true,
        version: window.chatwootConfig.fbApiVersion,
        status: true,
      });
      window.fbSDKLoaded = true;
      FB.AppEvents.logPageView();
    },

    async loadFBsdk() {
      return loadScript('https://connect.facebook.net/en_US/sdk.js', {
        id: 'facebook-jssdk',
      });
    },

    async startLogin() {
      this.hasLoginStarted = true;
      try {
        // this will load the SDK in a promise, and resolve it when the sdk is loaded
        // in case the SDK is already present, it will resolve immediately
        await this.loadFBsdk();
        this.runFBInit(); // run init anyway, `tryFBlogin` won't wait for `fbAsyncInit` otherwise.
        this.tryFBlogin(); // make an attempt to login
      } catch (error) {
        if (error.name === 'ScriptLoaderError') {
          // if the error was related to script loading, we show a toast
          useAlert(this.$t('INBOX_MGMT.DETAILS.ERROR_FB_LOADING'));
        } else {
          // if the error was anything else, we capture it and show a toast
          Sentry.captureException(error);
          useAlert(this.$t('INBOX_MGMT.DETAILS.ERROR_FB_AUTH'));
        }
      }
    },

    tryFBlogin() {
      FB.login(
        response => {
          if (response.status === 'connected') {
            this.reauthorizeFBPage(response.authResponse.accessToken);
          } else if (response.status === 'not_authorized') {
            // The person is logged into Facebook, but not your app.
            useAlert(this.$t('INBOX_MGMT.DETAILS.ERROR_FB_AUTH'));
          } else {
            // The person is not logged into Facebook, so we're not sure if
            // they are logged into this app or not.
            useAlert(this.$t('INBOX_MGMT.DETAILS.ERROR_FB_AUTH'));
          }
        },
        {
          scope:
            'pages_manage_metadata,business_management,pages_messaging,instagram_basic,pages_show_list,pages_read_engagement,instagram_manage_messages',
          auth_type: 'reauthorize',
        }
      );
    },
    async reauthorizeFBPage(omniauthToken) {
      try {
        await this.$store.dispatch('inboxes/reauthorizeFacebookPage', {
          omniauthToken,
          inboxId: this.inboxId,
        });
        useAlert(this.$t('INBOX_MGMT.FACEBOOK_REAUTHORIZE.MESSAGE_SUCCESS'));
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.FACEBOOK_REAUTHORIZE.MESSAGE_ERROR'));
      }
    },
  },
};
</script>

<template>
  <InboxReconnectionRequired class="mx-8 mt-5" @reauthorize="startLogin" />
</template>

<style lang="scss" scoped>
@import 'dashboard/assets/scss/variables';

.fb--login {
  img {
    max-width: 240px;
    padding: $space-normal 0;
  }
}
</style>
