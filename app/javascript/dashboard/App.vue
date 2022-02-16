<template>
  <div id="app" class="app-wrapper app-root">
    <update-banner
      v-if="
        hasAnUpdateAvailable && globalConfig.displayManifest && showUpdateBanner
      "
      :latest-chatwoot-version="latestChatwootVersion"
      :dismiss-update-banner="dismissUpdateBanner"
    />
    <transition name="fade" mode="out-in">
      <router-view></router-view>
    </transition>
    <add-account-modal
      :show="showAddAccountModal"
      :has-accounts="hasAccounts"
    />
    <woot-snackbar-box />
    <network-notification />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import AddAccountModal from '../dashboard/components/layout/sidebarComponents/AddAccountModal';
import WootSnackbarBox from './components/SnackbarContainer';
import UpdateBanner from './components/ui/UpdateBanner';

import NetworkNotification from './components/NetworkNotification';
import { accountIdFromPathname } from './helper/URLHelper';
const semver = require('semver');

export default {
  name: 'App',

  components: {
    WootSnackbarBox,
    AddAccountModal,
    NetworkNotification,
    UpdateBanner,
  },

  data() {
    return {
      showAddAccountModal: false,
      latestChatwootVersion: null,
      showUpdateBanner: true,
    };
  },

  computed: {
    ...mapGetters({
      getAccount: 'accounts/getAccount',
      currentUser: 'getCurrentUser',
      globalConfig: 'globalConfig/get',
    }),
    hasAccounts() {
      return (
        this.currentUser &&
        this.currentUser.accounts &&
        this.currentUser.accounts.length !== 0
      );
    },
    hasAnUpdateAvailable() {
      if (!semver.valid(this.latestChatwootVersion)) {
        return false;
      }
      return (
        semver.lt(this.globalConfig.appVersion, this.latestChatwootVersion) &&
        this.checkUpdateDismissedOrNot(this.latestChatwootVersion)
      );
    },
    getDismissedUpdates() {
      const storedNames = JSON.parse(localStorage.getItem('dismissedUpdates'));
      return storedNames || [];
    },
    setDismissedUpdates() {
      const storedNames = JSON.parse(localStorage.getItem('dismissedUpdates'));
      return storedNames;
    },
  },

  watch: {
    currentUser() {
      if (!this.hasAccounts) {
        this.showAddAccountModal = true;
      }
    },
  },
  mounted() {
    this.$store.dispatch('setUser');
    this.setLocale(window.chatwootConfig.selectedLocale);
    this.initializeAccount();
  },

  methods: {
    setLocale(locale) {
      this.$root.$i18n.locale = locale;
    },

    async initializeAccount() {
      const { pathname } = window.location;
      const accountId = accountIdFromPathname(pathname);

      if (accountId) {
        await this.$store.dispatch('accounts/get');
        const {
          locale,
          latest_chatwoot_version: latestChatwootVersion,
        } = this.getAccount(accountId);
        this.setLocale(locale);
        this.latestChatwootVersion = latestChatwootVersion;
      }
    },
    checkUpdateDismissedOrNot(version) {
      return !this.getDismissedUpdates.includes(version);
    },
    dismissUpdateBanner() {
      const updatedDismissedItems = this.getDismissedUpdates;
      updatedDismissedItems.push(this.latestChatwootVersion);
      localStorage.setItem(
        'dismissedUpdates',
        JSON.stringify(updatedDismissedItems)
      );
      this.showUpdateBanner = false;
    },
  },
};
</script>

<style lang="scss">
@import './assets/scss/app';
</style>

<style src="vue-multiselect/dist/vue-multiselect.min.css"></style>
