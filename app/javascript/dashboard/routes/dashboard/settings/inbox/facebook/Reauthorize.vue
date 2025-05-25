<script>
/* global FB */
import InboxReconnectionRequired from '../components/InboxReconnectionRequired.vue';
import { useAlert } from 'dashboard/composables';
import FacebookTokenService from 'dashboard/api/facebookTokenService';

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
  data() {
    return {
      isAutoRefreshing: false,
      showAutoRefreshOption: true,
    };
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

    async tryAutoRefresh() {
      this.isAutoRefreshing = true;

      try {
        const result = await FacebookTokenService.refreshToken(this.inboxId);

        if (result.data.success) {
          useAlert('✅ Token đã được refresh tự động thành công! Không cần kết nối lại.');
          // Reload trang để cập nhật trạng thái
          setTimeout(() => {
            window.location.reload();
          }, 1500);
        } else {
          useAlert('⚠️ Không thể refresh token tự động. Vui lòng kết nối lại thủ công.');
          this.showAutoRefreshOption = false;
        }
      } catch (error) {
        console.error('Auto refresh error:', error);
        useAlert('❌ Lỗi khi thử refresh token tự động. Vui lòng kết nối lại thủ công.');
        this.showAutoRefreshOption = false;
      } finally {
        this.isAutoRefreshing = false;
      }
    },
  },
};
</script>

<template>
  <div class="mx-8 mt-5">
    <InboxReconnectionRequired
      :inbox="inbox"
      @reauthorize="startLogin"
    />

    <!-- Auto Refresh Option -->
    <div v-if="showAutoRefreshOption" class="mt-4 p-4 bg-blue-50 border border-blue-200 rounded-lg">
      <div class="flex items-start gap-3">
        <div class="flex-shrink-0 mt-1">
          <svg class="w-5 h-5 text-blue-600" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd" />
          </svg>
        </div>
        <div class="flex-1">
          <h4 class="text-sm font-medium text-blue-900 mb-2">
            💡 Thử refresh token tự động trước
          </h4>
          <p class="text-sm text-blue-700 mb-3">
            Trong nhiều trường hợp, chúng tôi có thể tự động refresh token Facebook mà không cần bạn kết nối lại.
            Điều này sẽ giúp tiết kiệm thời gian và không làm gián đoạn dịch vụ.
          </p>
          <div class="flex gap-2">
            <button
              :disabled="isAutoRefreshing"
              @click="tryAutoRefresh"
              class="inline-flex items-center px-3 py-2 border border-transparent text-sm leading-4 font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <svg v-if="isAutoRefreshing" class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              {{ isAutoRefreshing ? 'Đang thử refresh...' : '🔄 Thử refresh tự động' }}
            </button>
            <button
              @click="startLogin"
              class="inline-flex items-center px-3 py-2 border border-blue-300 text-sm leading-4 font-medium rounded-md text-blue-700 bg-white hover:bg-blue-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              🔗 Kết nối lại thủ công
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
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
