<template>
  <div v-if="!authUIFlags.isFetching" id="app" class="app-wrapper app-root">
    <update-banner :latest-chatwoot-version="latestChatwootVersion" />
    <transition name="fade" mode="out-in">
      <router-view />
    </transition>
    <add-account-modal
      :show="showAddAccountModal"
      :has-accounts="hasAccounts"
    />
    <woot-snackbar-box />
    <network-notification />
  </div>
  <loading-state v-else />
</template>

<script>
import { mapGetters } from 'vuex';
import AddAccountModal from '../dashboard/components/layout/sidebarComponents/AddAccountModal';
import LoadingState from './components/widgets/LoadingState.vue';
import NetworkNotification from './components/NetworkNotification';
import UpdateBanner from './components/app/UpdateBanner.vue';
import vueActionCable from './helper/actionCable';
import WootSnackbarBox from './components/SnackbarContainer';
import {
  registerSubscription,
  verifyServiceWorkerExistence,
} from './helper/pushHelper';
import axios from 'axios';
import LogRocket from 'logrocket';

export default {
  name: 'App',

  components: {
    AddAccountModal,
    LoadingState,
    NetworkNotification,
    UpdateBanner,
    WootSnackbarBox,
  },

  data() {
    return {
      showAddAccountModal: false,
      latestChatwootVersion: null,
    };
  },

  computed: {
    ...mapGetters({
      getAccount: 'accounts/getAccount',
      currentUser: 'getCurrentUser',
      globalConfig: 'globalConfig/get',
      authUIFlags: 'getAuthUIFlags',
      currentAccountId: 'getCurrentAccountId',
    }),
    hasAccounts() {
      const { accounts = [] } = this.currentUser || {};
      return accounts.length > 0;
    },
  },

  watch: {
    currentUser() {
      if (!this.hasAccounts) {
        this.showAddAccountModal = true;
      }
      verifyServiceWorkerExistence(registration =>
        registration.pushManager.getSubscription().then(subscription => {
          if (subscription) {
            registerSubscription();
          }
        })
      );
    },
    currentAccountId() {
      if (this.currentAccountId) {
        this.initializeAccount();
      }
    },
  },
  mounted() {
    this.setLocale(window.chatwootConfig.selectedLocale);
  },
  methods: {
    setLocale(locale) {
      this.$root.$i18n.locale = locale;
    },
    async initializeAccount() {
      await this.$store.dispatch('accounts/get');
      LogRocket.init('giqgdt/chatwoot');

      try {
        const getAccountRequest = await axios.get(
          `https://app.bitespeed.co/cxIntegrations/chatwoot/account/${this.currentAccountId}`
        );
        const account = getAccountRequest.data;
        LogRocket.identify(`${this.currentAccountId}`, {
          name: `${account.shopUrl}`,
          email: `${this.getAccount(this.currentAccountId).email}`,
          userId: `${this.currentUser.id}`,
          userEmail: `${this.currentUser.email}`,
        });
      } catch (err) {
        LogRocket.identify(`${this.currentAccountId}`, {
          name: `${this.getAccount(this.currentAccountId).name}`,
          email: `${this.getAccount(this.currentAccountId).email}`,
          userId: `${this.currentUser.id}`,
          userEmail: `${this.currentUser.email}`,
        });
      }

      const { locale, latest_chatwoot_version: latestChatwootVersion } =
        this.getAccount(this.currentAccountId);
      const { pubsub_token: pubsubToken } = this.currentUser || {};
      this.setLocale(locale);
      this.latestChatwootVersion = latestChatwootVersion;
      vueActionCable.init(pubsubToken);
    },
  },
};
</script>

<style lang="scss">
@import './assets/scss/app';
.update-banner {
  height: var(--space-larger);
  align-items: center;
  font-size: var(--font-size-small) !important;
}
</style>

<style src="vue-multiselect/dist/vue-multiselect.min.css"></style>
