<template>
  <div class="wizard-body columns content-box small-9">
    <div class="login-init full-height" v-if="!hasLoginStarted">
      <a href="#" @click="startLogin()"><img src="~dashboard/assets/images/channels/facebook_login.png" alt="Facebook-logo"/></a>
      <p>{{ $t('INBOX_MGMT.ADD.FB.HELP') }}</p>
    </div>
    <div v-else>
      <loading-state :message="emptyStateMessage" v-if="showLoader"></loading-state>
      <form class="row" v-on:submit.prevent="createChannel()" v-if="!showLoader">
        <div class="medium-12 columns">
          <page-header
            :header-title="$t('INBOX_MGMT.ADD.DETAILS.TITLE')"
            :header-content="$t('INBOX_MGMT.ADD.DETAILS.DESC')"
          />
        </div>
        <div class="medium-7 columns">
          <div class="medium-12 columns">
            <div class="input-wrap" :class="{ 'error': $v.selectedPage.$error }">Choose Page
              <multiselect
                v-model.trim="selectedPage"
                :close-on-select="true"
                :allow-empty="true"
                :options="getSelectablePages"
                track-by="id"
                label="name"
                placeholder="Pick a value"
                selected-label=''
                @select="setPageName"
              />
              <span class="message" v-if="$v.selectedPage.$error">Select a page from the list</span>
            </div>
          </div>
          <div class="medium-12 columns">
            <label :class="{ 'error': $v.pageName.$error }">Inbox Name
              <input type="text" v-model.trim="pageName" @input="$v.pageName.$touch" placeholder="Pick A Name Your Inbox">
              <span class="message" v-if="$v.pageName.$error">Add a name for your inbox</span>
            </label>
          </div>
          <div class="medium-12 columns text-right">
            <input type="submit" value="Create Inbox" class="button">
          </div>
        </div>
      </form>
    </div>
  </div>
</template>
<script>
/* eslint no-console: 0 */
/* eslint-env browser */
/* global FB */
/* global bus */
/* global $v, __FB_ID__ */
import { required } from 'vuelidate/lib/validators';
import ChannelApi from '../../../../api/channels';
import LoadingState from '../../../../components/widgets/LoadingState';
import PageHeader from '../SettingsSubPageHeader';
import router from '../../../index';

export default {

  components: {
    LoadingState,
    PageHeader,
  },

  data() {
    return {
      isCreating: false,
      omniauth_token: '',
      user_access_token: '',
      channel: 'facebook',
      selectedPage: { name: null, id: null },
      pageName: '',
      pageList: [],
      emptyStateMessage: this.$t('INBOX_MGMT.DETAILS.LOADING_FB'),
      hasLoginStarted: false,
    };
  },

  validations: {

    pageName: {
      required,
    },

    selectedPage: {
      isEmpty() {
        return this.selectedPage !== null && !!this.selectedPage.name;
      },
    },

  },

  created() {
    this.initFB();
    this.loadFBsdk();
  },

  computed: {
    showLoader() {
      return !this.user_access_token || this.isCreating;
    },
    getSelectablePages() {
      return this.pageList.filter(item => (!item.exists));
    },
  },

  mounted() {
    this.initFB();
  },

  methods: {
    startLogin() {
      this.hasLoginStarted = true;
      this.tryFBlogin();
    },

    setPageName({ name }) {
      this.$v.selectedPage.$touch();
      this.pageName = name;
    },

    initChannelAuth(channel) {
      if (channel === 'facebook') {
        this.loadFBsdk();
      }
    },

    initFB() {
      if (window.fbSDKLoaded === undefined) {
        window.fbAsyncInit = () => {
          FB.init({
            appId: __FB_ID__,
            xfbml: true,
            version: 'v2.8',
            status: true,
          });
          window.fbSDKLoaded = true;
          FB.AppEvents.logPageView();
          // this.tryFBlogin();
        };
      } else {
        // this.tryFBlogin();
      }
    },

    loadFBsdk() {
      ((d, s, id) => {
        let js;
        const fjs = js = d.getElementsByTagName(s)[0];
        if (d.getElementById(id)) {
          return;
        }
        js = d.createElement(s);
        js.id = id;
        js.src = '//connect.facebook.net/en_US/sdk.js';
        fjs.parentNode.insertBefore(js, fjs);
      })(document, 'script', 'facebook-jssdk');
    },

    tryFBlogin() {
      FB.login((response) => {
        if (response.status === 'connected') {
          this.fetchPages(response.authResponse.accessToken);
        } else if (response.status === 'not_authorized') {
          // The person is logged into Facebook, but not your app.
          this.emptyStateMessage = this.$t('INBOX_MGMT.DETAILS.ERROR_FB_AUTH');
        } else {
          // The person is not logged into Facebook, so we're not sure if
          // they are logged into this app or not.
          this.emptyStateMessage = this.$t('INBOX_MGMT.DETAILS.ERROR_FB_AUTH');
        }
      }, { scope: 'manage_pages,read_page_mailboxes,pages_messaging,pages_messaging_phone_number' });
    },

    fetchPages(_token) {
      ChannelApi.fetchFacebookPages(_token).then((response) => {
        this.pageList = response.data.data.page_details;
        this.user_access_token = response.data.data.user_access_token;
      }).catch();
    },

    channelParams() {
      return {
        user_access_token: this.user_access_token,
        page_access_token: this.selectedPage.access_token,
        page_name: this.selectedPage.name,
        page_id: this.selectedPage.id,
        inbox_name: this.pageName,
      };
    },

    createChannel() {
      this.$v.$touch();
      if (!this.$v.$error) {
        this.emptyStateMessage = this.$t('INBOX_MGMT.DETAILS.CREATING_CHANNEL');
        this.isCreating = true;
        this.$store.dispatch('addInboxItem', {
          channel: this.channel,
          params: this.channelParams(),
        }).then((response) => {
          console.log(response);
          router.replace({ name: 'settings_inboxes_add_agents', params: { page: 'new', inbox_id: response.data.id } });
        }).catch((error) => {
          console.log(error);
          this.isCreating = false;
        });
      }
    },
  },
};
</script>
