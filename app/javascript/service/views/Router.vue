<template>
  <div id="app" class="woot-widget-wrap">
    <home />
  </div>
</template>

<script>
import Home from './Home';

export default {
  name: 'Router',
  components: {
    Home,
  },
};
</script>
