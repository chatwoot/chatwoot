<template>
  <div id="app" class="app-wrapper app-root">
    <update-banner :latest-chatwoot-version="latestChatwootVersion" />
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
import { accountIdFromPathname } from './helper/URLHelper';
import { mapGetters } from 'vuex';
import AddAccountModal from '../dashboard/components/layout/sidebarComponents/AddAccountModal';
import NetworkNotification from './components/NetworkNotification';
import UpdateBanner from './components/app/UpdateBanner.vue';
import WootSnackbarBox from './components/SnackbarContainer';

export default {
  name: 'App',

  components: {
    AddAccountModal,
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
    }),
    hasAccounts() {
      return (
        this.currentUser &&
        this.currentUser.accounts &&
        this.currentUser.accounts.length !== 0
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
        const {
          locale,
          latest_chatwoot_version: latestChatwootVersion,
        } = this.getAccount(accountId);
        this.setLocale(locale);
        this.latestChatwootVersion = latestChatwootVersion;
      }
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
