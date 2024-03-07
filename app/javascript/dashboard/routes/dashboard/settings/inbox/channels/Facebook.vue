<template>
  <div
    class="border border-slate-25 dark:border-slate-800/60 bg-white dark:bg-slate-900 h-full p-6 w-full max-w-full md:w-3/4 md:max-w-[75%] flex-shrink-0 flex-grow-0"
  >
    <div v-if="!hasLoginStarted" class="login-init h-full">
      <a href="#" @click="startLogin()">
        <img
          src="~dashboard/assets/images/channels/facebook_login.png"
          alt="Facebook-logo"
        />
      </a>
      <p>
        {{
          useInstallationName(
            $t('INBOX_MGMT.ADD.FB.HELP'),
            globalConfig.installationName
          )
        }}
      </p>
    </div>
    <div v-else>
      <div v-if="hasError" class="max-w-lg mx-auto text-center">
        <h5>{{ errorStateMessage }}</h5>
        <p
          v-if="errorStateDescription"
          v-dompurify-html="errorStateDescription"
        />
      </div>
      <loading-state v-else-if="showLoader" :message="emptyStateMessage" />
      <form
        v-else
        class="mx-0 flex flex-wrap"
        @submit.prevent="createChannel()"
      >
        <div class="w-full">
          <page-header
            :header-title="$t('INBOX_MGMT.ADD.DETAILS.TITLE')"
            :header-content="
              useInstallationName(
                $t('INBOX_MGMT.ADD.DETAILS.DESC'),
                globalConfig.installationName
              )
            "
          />
        </div>
        <div class="w-3/5">
          <div class="w-full">
            <div class="input-wrap" :class="{ error: $v.selectedPage.$error }">
              {{ $t('INBOX_MGMT.ADD.FB.CHOOSE_PAGE') }}
              <multiselect
                v-model.trim="selectedPage"
                :close-on-select="true"
                :allow-empty="true"
                :options="getSelectablePages"
                track-by="id"
                label="name"
                :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
                :deselect-label="$t('FORMS.MULTISELECT.ENTER_TO_REMOVE')"
                :placeholder="$t('INBOX_MGMT.ADD.FB.PICK_A_VALUE')"
                selected-label
                @select="setPageName"
              />
              <span v-if="$v.selectedPage.$error" class="message">
                {{ $t('INBOX_MGMT.ADD.FB.CHOOSE_PLACEHOLDER') }}
              </span>
            </div>
          </div>
          <div class="w-full">
            <label :class="{ error: $v.pageName.$error }">
              {{ $t('INBOX_MGMT.ADD.FB.INBOX_NAME') }}
              <input
                v-model.trim="pageName"
                type="text"
                :placeholder="$t('INBOX_MGMT.ADD.FB.PICK_NAME')"
                @input="$v.pageName.$touch"
              />
              <span v-if="$v.pageName.$error" class="message">
                {{ $t('INBOX_MGMT.ADD.FB.ADD_NAME') }}
              </span>
            </label>
          </div>
          <div class="w-full text-right">
            <input type="submit" value="Create Inbox" class="button" />
          </div>
        </div>
      </form>
    </div>
  </div>
</template>
<script>
/* eslint-env browser */
/* global FB */
import { required } from 'vuelidate/lib/validators';
import LoadingState from 'dashboard/components/widgets/LoadingState.vue';
import { mapGetters } from 'vuex';
import ChannelApi from '../../../../../api/channels';
import PageHeader from '../../SettingsSubPageHeader.vue';
import router from '../../../../index';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import accountMixin from '../../../../../mixins/account';

export default {
  components: {
    LoadingState,
    PageHeader,
  },
  mixins: [globalConfigMixin, accountMixin],
  data() {
    return {
      isCreating: false,
      hasError: false,
      omniauth_token: '',
      user_access_token: '',
      channel: 'facebook',
      selectedPage: { name: null, id: null },
      pageName: '',
      pageList: [],
      emptyStateMessage: this.$t('INBOX_MGMT.DETAILS.LOADING_FB'),
      errorStateMessage: '',
      errorStateDescription: '',
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

  computed: {
    showLoader() {
      return !this.user_access_token || this.isCreating;
    },
    getSelectablePages() {
      return this.pageList.filter(item => !item.exists);
    },
    ...mapGetters({
      currentUser: 'getCurrentUser',
      globalConfig: 'globalConfig/get',
    }),
  },

  created() {
    this.initFB();
    this.loadFBsdk();
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
        js.src = '//connect.facebook.net/en_US/sdk.js';
        fjs.parentNode.insertBefore(js, fjs);
      })(document, 'script', 'facebook-jssdk');
    },

    tryFBlogin() {
      FB.login(
        response => {
          this.hasError = false;
          if (response.status === 'connected') {
            this.fetchPages(response.authResponse.accessToken);
          } else if (response.status === 'not_authorized') {
            // eslint-disable-next-line no-console
            console.error('FACEBOOK AUTH ERROR', response);
            this.hasError = true;
            // The person is logged into Facebook, but not your app.
            this.errorStateMessage = this.$t(
              'INBOX_MGMT.DETAILS.ERROR_FB_UNAUTHORIZED'
            );
            this.errorStateDescription = this.$t(
              'INBOX_MGMT.DETAILS.ERROR_FB_UNAUTHORIZED_HELP'
            );
          } else {
            // eslint-disable-next-line no-console
            console.error('FACEBOOK AUTH ERROR', response);
            this.hasError = true;
            // The person is not logged into Facebook, so we're not sure if
            // they are logged into this app or not.
            this.errorStateMessage = this.$t(
              'INBOX_MGMT.DETAILS.ERROR_FB_AUTH'
            );
            this.errorStateDescription = '';
          }
        },
        {
          scope:
            'pages_manage_metadata,business_management,pages_messaging,instagram_basic,pages_show_list,pages_read_engagement,instagram_manage_messages',
        }
      );
    },

    async fetchPages(_token) {
      try {
        const response = await ChannelApi.fetchFacebookPages(
          _token,
          this.accountId
        );
        const {
          data: { data },
        } = response;
        this.pageList = data.page_details;
        this.user_access_token = data.user_access_token;
      } catch (error) {
        // Ignore error
      }
    },

    channelParams() {
      return {
        user_access_token: this.user_access_token,
        page_access_token: this.selectedPage.access_token,
        page_id: this.selectedPage.id,
        inbox_name: this.selectedPage.name,
      };
    },

    createChannel() {
      this.$v.$touch();
      if (!this.$v.$error) {
        this.emptyStateMessage = this.$t('INBOX_MGMT.DETAILS.CREATING_CHANNEL');
        this.isCreating = true;
        this.$store
          .dispatch('inboxes/createFBChannel', this.channelParams())
          .then(data => {
            router.replace({
              name: 'settings_inboxes_add_agents',
              params: { page: 'new', inbox_id: data.id },
            });
          })
          .catch(() => {
            this.isCreating = false;
          });
      }
    },
  },
};
</script>
<style scoped lang="scss">
.login-init {
  @apply pt-[30%] text-center;

  p {
    @apply p-6;
  }

  > a > img {
    @apply w-60;
  }
}
</style>
