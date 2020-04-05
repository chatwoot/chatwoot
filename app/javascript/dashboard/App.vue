<template>
  <div id="app" class="app-wrapper app-root">
    <transition name="fade" mode="out-in">
      <router-view></router-view>
    </transition>
    <woot-snackbar-box />
  </div>
</template>

<script>
import Vue from 'vue';
import { mapGetters } from 'vuex';
import WootSnackbarBox from './components/SnackbarContainer';
import { accountIdFromUrl } from './helper/commons';

export default {
  name: 'App',

  components: {
    WootSnackbarBox,
  },

  computed: {
    ...mapGetters({
      getAccount: 'accounts/getAccount',
    }),
  },

  mounted() {
    this.$store.dispatch('setUser');
    this.initializeAccount();
  },

  methods: {
    async initializeAccount() {
      const accountId = accountIdFromUrl();
      if (accountId) {
        await this.$store.dispatch('accounts/get');
        const { locale } = this.getAccount(accountId);
        Vue.config.lang = locale;
      }
    },
  },
};
</script>

<style lang="scss">
@import './assets/scss/app';
</style>

<style src="vue-multiselect/dist/vue-multiselect.min.css"></style>
