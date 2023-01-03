<template>
  <div
    v-if="!forwardTo"
    class="wizard-body small-12 medium-9 columns height-auto"
  >
    <div class="row channels">
      <div
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
export default {
  components: {
    ForwardToOption,
  },
  data() {
    return { forwardTo: false };
  },
  methods: {
    async onMicrosoftClick() {
      try {
        const msalConfig = {
          auth: {
            clientId: 'f200029c-6075-41bc-872d-1b37af066b21',
          },
        };

        const msalInstance = new msal.PublicClientApplication(msalConfig);

        const loginResponse = await msalInstance.loginPopup({
          scopes: [
            'https://outlook.office.com/IMAP.AccessAsUser.All',
            'https://outlook.office.com/SMTP.Send',
            'offline_access',
          ],
          redirectUri: 'http://localhost:3000',
        });

        console.log(loginResponse);

        // var currentAccount = loginResponse.account;

        // refresh token silently if fails open a popup to add user details for login
        // var silentRequest = {
        //   scopes: ["Mail.Read"],
        //   account: currentAccount,
        //   forceRefresh: false,
        //   cacheLookupPolicy: 'acquireTokenSilent' // will default to CacheLookupPolicy.Default if omitted
        // };

        // var request = {
        //   scopes: ["Mail.Read"],
        //   loginHint: currentAccount.username // For v1 endpoints, use upn from idToken claims
        // };

        // const tokenResponse = await msalInstance.acquireTokenSilent(silentRequest).catch(async (error) => {
        //   if (error instanceof InteractionRequiredAuthError) {
        //     // fallback to interaction when silent call fails
        //     return await msalInstance.acquireTokenPopup(request).catch(error => {
        //       if (error instanceof InteractionRequiredAuthError) {
        //         // fallback to interaction when silent call fails
        //         return msalInstance.acquireTokenRedirect(request)
        //       }
        //     });
        //   }
        // });
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
