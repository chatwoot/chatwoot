<template>
  <div id="app" class="app-wrapper app-root">
    <transition name="fade" mode="out-in">
      <router-view></router-view>
    </transition>
    <add-account-modal
      :show="showAddAccountModal"
      :has-accounts="hasAccounts"
    />
    <woot-snackbar-box />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import AddAccountModal from '../dashboard/components/layout/sidebarComponents/AddAccountModal';
import WootSnackbarBox from './components/SnackbarContainer';
import { accountIdFromPathname } from './helper/URLHelper';

export default {
  name: 'App',

  components: {
    WootSnackbarBox,
    AddAccountModal,
  },

  data() {
    return {
      showAddAccountModal: false,
    };
  },

  computed: {
    ...mapGetters({
      getAccount: 'accounts/getAccount',
      currentUser: 'getCurrentUser',
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
        const { locale } = this.getAccount(accountId);
        this.setLocale(locale);
      }
    },
  },
};
</script>

<style lang="scss">
@import './assets/scss/app';
</style>

<style src="vue-multiselect/dist/vue-multiselect.min.css"></style>
