<template>
  <div class="wizard-body w-[75%] flex-shrink-0 flex-grow-0 max-w-[75%]">
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
        <div class="w-[60%]">
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
      hasError: this.$route.query.error_message !== '',
      omniauth_token: '',
      oa_id: '',
      oa_access_token: '',
      channel: 'zalo',
      pageName: '',
      emptyStateMessage: this.$t('INBOX_MGMT.DETAILS.LOADING_FB'),
      errorStateMessage: this.$route.query.error_message,
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
      return !this.oa_access_token || this.isCreating;
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
    // this.initFB();
    // this.loadFBsdk();
  },

  mounted() {
    // this.initFB();
  },

  methods: {
    startLogin() {
      this.hasLoginStarted = true;
      window.location.replace(
        'https://oauth.zaloapp.com/v4/oa/permission?app_id=1705469258416327647&redirect_uri=https://omni.hoatieucrm.vn/zalo/callback&state=' +
          encodeURIComponent(this.accountId)
      );
    },

    setPageName({ name }) {
      this.$v.selectedPage.$touch();
      this.pageName = name;
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
