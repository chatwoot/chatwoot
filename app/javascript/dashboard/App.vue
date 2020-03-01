<template>
  <div id="app" class="app-wrapper app-root">
    <transition name="fade" mode="out-in">
      <router-view></router-view>
    </transition>
    <woot-snackbar-box />
  </div>
</template>

<script>
import WootSnackbarBox from './components/SnackbarContainer';

export default {
  name: 'App',

  components: {
    WootSnackbarBox,
  },

  mounted() {
    this.$store.dispatch('setUser');
  },
};
</script>

<style lang="scss">
@import './assets/scss/app';
</style>

<style src="vue-multiselect/dist/vue-multiselect.min.css"></style>
