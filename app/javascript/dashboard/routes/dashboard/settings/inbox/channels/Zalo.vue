<template>
  <div class="wizard-body w-[75%] flex-shrink-0 flex-grow-0 max-w-[75%]">
    <div v-if="!hasLoginStarted" class="login-init h-full">
      <a href="#" @click="startLogin()">
        <img
          src="~dashboard/assets/images/channels/zalo_login.jpg"
          alt="Zalo-logo"
        />
      </a>
      <p>
        {{
          useInstallationName(
            $t('INBOX_MGMT.ADD.ZALO.HELP'),
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
            :header-title="$t('INBOX_MGMT.DETAILS.TITLE')"
            :header-content="
              useInstallationName(
                $t('INBOX_MGMT.DETAILS.DESC_ZALO'),
                globalConfig.installationName
              )
            "
          />
        </div>
        <div class="w-[60%]">
          <div class="w-full">
            <label :class="{ error: $v.pageName.$error }">
              {{ $t('INBOX_MGMT.ADD.ZALO.INBOX_NAME') }}
              <input
                v-model.trim="pageName"
                type="text"
                :placeholder="$t('INBOX_MGMT.ADD.ZALO.PICK_NAME')"
                @input="$v.pageName.$touch"
              />
              <span v-if="$v.pageName.$error" class="message">
                {{ $t('INBOX_MGMT.ADD.ZALO.ADD_NAME') }}
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
import axios from 'axios';
import PageHeader from '../../SettingsSubPageHeader.vue';
import router from '../../../../index';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import accountMixin from '../../../../../mixins/account';
import ZaloChannel from '../../../../../api/channel/zaloChannel';

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
      access_token: '',
      refresh_token: '',
      expires_in: '',
      oa_id: '',
      pageName: '',
      avatar: '',
      channel: 'zalo',
      emptyStateMessage: this.$t('INBOX_MGMT.DETAILS.LOADING_ZALO'),
      errorStateMessage: '',
      errorStateDescription: '',
      hasLoginStarted: false,
    };
  },

  validations: {
    pageName: {
      required,
    },
  },

  computed: {
    showLoader() {
      return this.oa_id === '' || this.isCreating;
    },
    ...mapGetters({
      currentUser: 'getCurrentUser',
      globalConfig: 'globalConfig/get',
    }),
  },

  created() {
    if (this.$route.query.code) this.getAccessToken();
  },

  methods: {
    startLogin() {
      this.hasLoginStarted = true;
      window.location.replace(
        'https://oauth.zaloapp.com/v4/oa/permission?app_id=' +
          window.chatwootConfig.zaloAppId +
          '&redirect_uri=' +
          window.chatwootConfig.hostURL +
          '/zalo/callback&state=' +
          encodeURIComponent(this.accountId)
      );
    },

    async getSecretKey() {
      const response = await ZaloChannel.secretKey();
      return response.data.secret_key;
    },

    async getAccessToken() {
      this.hasLoginStarted = true;
      const url = 'https://oauth.zaloapp.com/v4/oa/access_token';
      const data = new URLSearchParams();
      data.append('code', this.$route.query.code);
      data.append('app_id', window.chatwootConfig.zaloAppId);
      data.append('grant_type', 'authorization_code');
      const secret_key = await this.getSecretKey();

      const config = {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          secret_key: secret_key,
        },
      };

      axios
        .post(url, data, config)
        .then(response => {
          this.access_token = response.data.access_token;
          this.refresh_token = response.data.refresh_token;
          this.expires_in = response.data.expires_in;
          this.fetchOaData(this.access_token);
        })
        .catch(error => {
          this.hasError = true;
          this.errorStateMessage = error.message;
        });
    },

    fetchOaData(access_token) {
      const url = 'https://openapi.zalo.me/v2.0/oa/getoa';

      axios
        .get(url, {
          headers: {
            access_token: access_token,
          },
        })
        .then(response => {
          const data = response.data;
          if (data.error === 0) {
            this.oa_id = data.data.oa_id;
            this.pageName = data.data.name;
            this.avatar = data.data.avatar;
          } else {
            this.hasError = true;
            this.errorStateMessage = data.message;
          }
        })
        .catch(error => {
          this.hasError = true;
          this.errorStateMessage = error.message;
        });
    },

    channelParams() {
      return {
        oa_id: this.oa_id,
        access_token: this.access_token,
        refresh_token: this.refresh_token,
        expires_in: this.expires_in,
        inbox_name: this.pageName,
        avatar_url: this.avatar,
      };
    },

    createChannel() {
      this.$v.$touch();
      if (!this.$v.$error) {
        this.emptyStateMessage = this.$t('INBOX_MGMT.DETAILS.CREATING_CHANNEL');
        this.isCreating = true;
        this.$store
          .dispatch('inboxes/createZaloChannel', this.channelParams())
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
