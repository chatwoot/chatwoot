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
  <div id="app" class="woot-survey-wrap">
    <Response />
  </div>
</template>

<style lang="scss">
@import '~survey/assets/scss/woot.scss';
</style>
