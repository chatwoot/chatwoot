<template>
  <settings-section
    :title="$t('INBOX_MGMT.FACEBOOK_REAUTHORIZE.TITLE')"
    :sub-title="$t('INBOX_MGMT.FACEBOOK_REAUTHORIZE.SUBTITLE')"
  >
    <a class="fb--login" href="#" @click="tryFBlogin">
      <img
        src="~dashboard/assets/images/channels/facebook_login.png"
        alt="Facebook-logo"
      />
    </a>
  </settings-section>
</template>

<script>
/* global FB */
import SettingsSection from '../../../../../components/SettingsSection';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  components: {
    SettingsSection,
  },
  mixins: [alertMixin],
  props: {
    inboxId: {
      type: Number,
      required: true,
    },
  },
  mounted() {
    this.initFB();
    this.loadFBsdk();
  },

  methods: {
    initFB() {
      if (window.fbSDKLoaded === undefined) {
        window.fbAsyncInit = () => {
          FB.init({
            appId: window.chatwootConfig.fbAppId,
            xfbml: true,
            version: window.chatwootConfig.fbApiVersion,
            status: true,
          });
          window.fbSDKLoaded = true;
          FB.AppEvents.logPageView();
        };
      }
    },

    loadFBsdk() {
      ((d, s, id) => {
        let js;
        // eslint-disable-next-line
        const fjs = (js = d.getElementsByTagName(s)[0]);
        if (d.getElementById(id)) {
          return;
        }
        js = d.createElement(s);
        js.id = id;
        js.src = 'https://connect.facebook.net/en_US/sdk.js';
        fjs.parentNode.insertBefore(js, fjs);
      })(document, 'script', 'facebook-jssdk');
    },

    tryFBlogin() {
      FB.login(
        response => {
          if (response.status === 'connected') {
            this.reauthorizeFBPage(response.authResponse.accessToken);
          } else if (response.status === 'not_authorized') {
            // The person is logged into Facebook, but not your app.
            this.showAlert(this.$t('INBOX_MGMT.DETAILS.ERROR_FB_AUTH'));
          } else {
            // The person is not logged into Facebook, so we're not sure if
            // they are logged into this app or not.
            this.showAlert(this.$t('INBOX_MGMT.DETAILS.ERROR_FB_AUTH'));
          }
        },
        {
          scope:
            'pages_manage_metadata,pages_messaging,instagram_basic,pages_show_list,pages_read_engagement,instagram_manage_messages',
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
        this.showAlert(
          this.$t('INBOX_MGMT.FACEBOOK_REAUTHORIZE.MESSAGE_SUCCESS')
        );
      } catch (error) {
        this.showAlert(
          this.$t('INBOX_MGMT.FACEBOOK_REAUTHORIZE.MESSAGE_ERROR')
        );
      }
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~dashboard/assets/scss/variables';

.fb--login {
  img {
    max-width: 240px;
    padding: $space-normal 0;
  }
}
</style>
