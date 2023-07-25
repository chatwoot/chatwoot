<template>
  <div
    v-if="!authUIFlags.isFetching"
    id="app"
    class="app-wrapper app-root"
    :class="{ 'app-rtl--wrapper': isRTLView, dark: theme === 'dark' }"
    :dir="isRTLView ? 'rtl' : 'ltr'"
  >
    <update-banner :latest-chatwoot-version="latestChatwootVersion" />
    <template v-if="!accountUIFlags.isFetchingItem && currentAccountId">
      <payment-pending-banner />
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
import AddAccountModal from '../dashboard/components/layout/sidebarComponents/AddAccountModal';
import LoadingState from './components/widgets/LoadingState.vue';
import NetworkNotification from './components/NetworkNotification';
import UpdateBanner from './components/app/UpdateBanner.vue';
import UpgradeBanner from './components/app/UpgradeBanner.vue';
import PaymentPendingBanner from './components/app/PaymentPendingBanner.vue';
import vueActionCable from './helper/actionCable';
import WootSnackbarBox from './components/SnackbarContainer';
import rtlMixin from 'shared/mixins/rtlMixin';
import { LocalStorage } from 'shared/helpers/localStorage';
import {
  registerSubscription,
  verifyServiceWorkerExistence,
} from './helper/pushHelper';
import { LOCAL_STORAGE_KEYS } from './constants/localStorage';

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
  },

  mixins: [rtlMixin],

  data() {
    return {
      showAddAccountModal: false,
      latestChatwootVersion: null,
      theme: 'light',
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
      this.setColorTheme(
        window.matchMedia('(prefers-color-scheme: dark)').matches
      );
    },
    setColorTheme(isOSOnDarkMode) {
      const selectedColorScheme =
        LocalStorage.get(LOCAL_STORAGE_KEYS.COLOR_SCHEME) || 'light';
      if (
        (selectedColorScheme === 'auto' && isOSOnDarkMode) ||
        selectedColorScheme === 'dark'
      ) {
        this.theme = 'dark';
        document.body.classList.add('dark');
      } else {
        this.theme = 'light ';
        document.body.classList.remove('dark');
      }
    },
    listenToThemeChanges() {
      const mql = window.matchMedia('(prefers-color-scheme: dark)');
      mql.onchange = e => this.setColorTheme(e.matches);
    },
    setLocale(locale) {
      this.$root.$i18n.locale = locale;
    },
    async initializeAccount() {
      await this.$store.dispatch('accounts/get');
      this.$store.dispatch('setActiveAccount', {
        accountId: this.currentAccountId,
      });
      const {
        locale,
        latest_chatwoot_version: latestChatwootVersion,
      } = this.getAccount(this.currentAccountId);
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
