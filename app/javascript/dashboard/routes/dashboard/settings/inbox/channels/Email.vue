<template>
  <div
    v-if="!forwardTo"
    class="wizard-body small-12 medium-9 columns height-auto"
  >
    <div class="row channels">
      <div
        v-if="globalConfig.azureAppId"
        class="small-6 medium-4 large-3 columns channel"
        @click="onMicrosoftClick"
      >
        <img src="~dashboard/assets/images/channels/microsoft.png" />
        <h3 class="channel__title">
          Microsoft
        </h3>
      </div>
      <div
        class="small-6 medium-4 large-3 columns channel"
        @click="onOtherClick"
      >
        <img src="~dashboard/assets/images/channels/email.png" />
        <h3 class="channel__title">
          Other
        </h3>
      </div>
    </div>
  </div>
  <forward-to-option v-else />
</template>
<script>
import * as msal from '@azure/msal-browser';
import ForwardToOption from './Email/ForwardToOption.vue';
import { mapGetters } from 'vuex';
import router from '../../../..';

export default {
  components: {
    ForwardToOption,
  },
  data() {
    return { forwardTo: false };
  },
  computed: {
    ...mapGetters({ globalConfig: 'globalConfig/get' }),
  },
  methods: {
    async onMicrosoftClick() {
      try {
        const msalConfig = {
          auth: { clientId: this.globalConfig.azureAppId },
        };

        const msalInstance = new msal.PublicClientApplication(msalConfig);

        const loginResponse = await msalInstance.loginPopup({
          scopes: [
            'https://outlook.office.com/IMAP.AccessAsUser.All',
            'https://outlook.office.com/SMTP.Send',
            'offline_access',
          ],
          redirectUri: window.location.origin,
        });

        const { account: { username, name } = {} } = loginResponse;

        const emailChannel = await this.$store.dispatch(
          'inboxes/createChannel',
          {
            name,
            channel: {
              type: 'email',
              email: username,
              provider: 'microsoft',
              provider_config: loginResponse,
            },
          }
        );

        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: emailChannel.id,
          },
        });
      } catch (err) {
        // handle error
      }
    },
    onOtherClick() {
      this.forwardTo = true;
    },
  },
};
</script>
