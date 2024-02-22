<template>
  <div
    v-if="!authUIFlags.isFetching && !accountUIFlags.isFetchingItem"
    id="app"
    class="flex-grow-0 w-full h-full min-h-0 app-wrapper"
    :class="{ 'app-rtl--wrapper': isRTLView }"
    :dir="isRTLView ? 'rtl' : 'ltr'"
  >
    <update-banner :latest-chatwoot-version="latestChatwootVersion" />
    <template v-if="currentAccountId">
      <pending-email-verification-banner v-if="hideOnOnboardingView" />
      <payment-pending-banner v-if="hideOnOnboardingView" />
      <upgrade-banner />
    </template>
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
import AddAccountModal from '../dashboard/components/layout/sidebarComponents/AddAccountModal.vue';
import LoadingState from './components/widgets/LoadingState.vue';
import NetworkNotification from './components/NetworkNotification.vue';
import UpdateBanner from './components/app/UpdateBanner.vue';
import UpgradeBanner from './components/app/UpgradeBanner.vue';
import PaymentPendingBanner from './components/app/PaymentPendingBanner.vue';
import PendingEmailVerificationBanner from './components/app/PendingEmailVerificationBanner.vue';
import vueActionCable from './helper/actionCable';
import WootSnackbarBox from './components/SnackbarContainer.vue';
import rtlMixin from 'shared/mixins/rtlMixin';
import { setColorTheme } from './helper/themeHelper';
import { isOnOnboardingView } from 'v3/helpers/RouteHelper';
import {
  registerSubscription,
  verifyServiceWorkerExistence,
} from './helper/pushHelper';

export default {
  name: 'App',

  components: {
    AddAccountModal,
    LoadingState,
    NetworkNotification,
    UpdateBanner,
    PaymentPendingBanner,
    WootSnackbarBox,
    UpgradeBanner,
    PendingEmailVerificationBanner,
  },

  mixins: [rtlMixin],

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
      accountUIFlags: 'accounts/getUIFlags',
      currentAccountId: 'getCurrentAccountId',
    }),
    hasAccounts() {
      const { accounts = [] } = this.currentUser || {};
      return accounts.length > 0;
    },
    hideOnOnboardingView() {
      return !isOnOnboardingView(this.$route);
    },
  },

  watch: {
    currentUser() {
      if (!this.hasAccounts) {
        this.showAddAccountModal = true;
      }
    },
    currentAccountId() {
      if (this.currentAccountId) {
        this.initializeAccount();
      }
    },
  },
  mounted() {
    this.initializeColorTheme();
    this.listenToThemeChanges();
    this.setLocale(window.chatwootConfig.selectedLocale);
  },
  methods: {
    initializeColorTheme() {
      setColorTheme(window.matchMedia('(prefers-color-scheme: dark)').matches);
    },
    listenToThemeChanges() {
      const mql = window.matchMedia('(prefers-color-scheme: dark)');
      mql.onchange = e => setColorTheme(e.matches);
    },
    setLocale(locale) {
      this.$root.$i18n.locale = locale;
    },
    async initializeAccount() {
      await this.$store.dispatch('accounts/get');
      this.$store.dispatch('setActiveAccount', {
        accountId: this.currentAccountId,
      });
      const { locale, latest_chatwoot_version: latestChatwootVersion } =
        this.getAccount(this.currentAccountId);
      const { pubsub_token: pubsubToken } = this.currentUser || {};
      this.setLocale(locale);
      this.updateRTLDirectionView(locale);
      this.latestChatwootVersion = latestChatwootVersion;
      vueActionCable.init(pubsubToken);

      verifyServiceWorkerExistence(registration =>
        registration.pushManager.getSubscription().then(subscription => {
          if (subscription) {
            registerSubscription();
          }
        })
      );
    },
  },
};
</script>

<style lang="scss">
@import './assets/scss/app';
</style>

<style src="vue-multiselect/dist/vue-multiselect.min.css"></style>
