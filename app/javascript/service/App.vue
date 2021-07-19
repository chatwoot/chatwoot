<template>
  <router />
</template>

<script>
import Router from './views/Router';

export default {
  name: 'App',
  components: {
    Router,
  },
};
</script>

<style lang="scss">
@import '~service/assets/scss/woot.scss';
</style>
