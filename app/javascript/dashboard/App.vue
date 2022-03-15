<template>
  <div id="app" class="app-wrapper app-root">
    <banner
      v-if="shouldShowBanner"
      class="banner"
      color-scheme="primary"
      :banner-message="bannerMessage"
      href-link="https://github.com/chatwoot/chatwoot/releases"
      :href-link-text="$t('GENERAL_SETTINGS.LEARN_MORE')"
      has-close-button
      @close="dismissUpdateBanner"
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
/* eslint-disable prettier/prettier */
import { mapGetters } from 'vuex';
import Banner from 'dashboard/components/ui/Banner.vue';
import AddAccountModal from '../dashboard/components/layout/sidebarComponents/AddAccountModal';
import WootSnackbarBox from './components/SnackbarContainer';
import LocalStorage from './helper/localStorage';
import NetworkNotification from './components/NetworkNotification';
import { accountIdFromPathname } from './helper/URLHelper';
const semver = require('semver');

const dismissedUpdates = new LocalStorage('dismissedUpdates');

export default {
  name: 'App',

  components: {
    WootSnackbarBox,
    AddAccountModal,
    NetworkNotification,
    Banner,
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
    bannerMessage() {
      return this.$t('GENERAL_SETTINGS.UPDATE_CHATWOOT', {
        latestChatwootVersion: this.latestChatwootVersion,
      });
    },
    isUserAdmin() {
      return this.currentUser.role === 'administrator';
    },
    shouldShowBanner() {
      return (
        this.globalConfig.displayManifest &&
        this.hasAnUpdateAvailable &&
        this.isUserAdmin
      );
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
        const { locale, latest_chatwoot_version: latestChatwootVersion } =
          this.getAccount(accountId);
        this.setLocale(locale);
        this.latestChatwootVersion = latestChatwootVersion;
      }
    },
    checkUpdateDismissedOrNot(version) {
      return !dismissedUpdates.get().includes(version);
    },
    dismissUpdateBanner() {
      const updatedDismissedItems = dismissedUpdates.get();
      updatedDismissedItems.push(this.latestChatwootVersion);
      dismissedUpdates.store(updatedDismissedItems);
      this.showUpdateBanner = false;
      this.latestChatwootVersion = this.globalConfig.appVersion;
    },
  },
};
</script>

<style lang="scss">
@import './assets/scss/app';
.banner {
  height: var(--space-larger);
  align-items: center;
  font-size: var(--font-size-small) !important;
}
</style>

<style src="vue-multiselect/dist/vue-multiselect.min.css"></style>
