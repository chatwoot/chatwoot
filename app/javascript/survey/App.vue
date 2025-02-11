@use './assets/scss/woot.scss';
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
  <div id="app" class="woot-survey-wrap min-h-screen">
    <Response />
  </div>
</template>

<style lang="scss">
</style>
