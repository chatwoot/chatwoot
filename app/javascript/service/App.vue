<template>
  <div id="app" class="woot-service-wrap">
    <response />
  </div>
</template>

<script>
import Response from './views/Response.vue';

export default {
  name: 'App',
  components: {
    Response,
  },
};
</script>

<style lang="scss">
@import '~service/assets/scss/woot.scss';
</style>
