<script>
import Response from './views/Response.vue';

export default {
  name: 'App',
  components: {
    Response,
  },
};
</script>

<template>
  <div id="app" dir="ltr" class="woot-survey-wrap min-h-screen">
    <Response />
  </div>
</template>

<style lang="scss">
@import './assets/scss/woot.scss';
</style>
