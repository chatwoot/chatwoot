<template>
  <div id="app" class="woot-widget-wrap">
    <router-view />
  </div>
</template>

<script>
import { mapActions } from 'vuex';

export default {
  name: 'App',

  methods: {
    ...mapActions('conversation', ['fetchOldConversations']),
  },

  mounted() {
    this.fetchOldConversations();
  },
};
</script>

<style lang="scss">
@import '~widget/assets/scss/woot.scss';
</style>
