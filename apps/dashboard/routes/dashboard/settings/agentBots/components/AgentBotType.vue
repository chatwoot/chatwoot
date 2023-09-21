<template>
  <span>
    <img
      v-tooltip="botTypeConfig[botType].label"
      class="agent-bot-type--thumbnail"
      :src="botTypeConfig[botType].thumbnail"
      :alt="botTypeConfig[botType].label"
    />
    <span>{{ botTypeConfig[botType].label }}</span>
  </span>
</template>
<script>
export default {
  props: {
    botType: {
      type: String,
      default: 'webhook',
    },
  },
  data() {
    return {
      botTypeConfig: {
        csml: {
          label: this.$t('AGENT_BOTS.TYPES.CSML'),
          thumbnail: '/dashboard/images/agent-bots/csml.png',
        },
        webhook: {
          label: this.$t('AGENT_BOTS.TYPES.WEBHOOK'),
          thumbnail: '/dashboard/images/agent-bots/webhook.svg',
        },
      },
    };
  },
};
</script>
<style scoped>
.agent-bot-type--thumbnail {
  width: auto;
  height: var(--space-slab);
}
</style>
