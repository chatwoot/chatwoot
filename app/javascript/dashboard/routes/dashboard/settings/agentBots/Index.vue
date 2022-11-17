<template>
  <div>Agent Bot list</div>
</template>

<script>
import { mapGetters } from 'vuex';
export default {
  computed: {
    ...mapGetters({
      agentBots: 'agentBots/getBots',
      uiFlags: 'agentBots/getUIFlags',
    }),
  },
  mounted() {
    this.$store.dispatch('agentBots/get');
  },
};
</script>
