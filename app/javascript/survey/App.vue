<template>
  <div id="app" class="woot-survey-wrap">
    <responses />
  </div>
</template>

<script>
import Responses from './views/Responses.vue';

export default {
  name: 'App',
  components: {
    Responses,
  },
};
</script>

<style lang="scss">
@import '~survey/assets/scss/woot.scss';
</style>
