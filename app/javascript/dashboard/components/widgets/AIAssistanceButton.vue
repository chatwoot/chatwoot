<template>
  <div v-if="isAIIntegrationEnabled" class="position-relative">
    <woot-button
      v-tooltip.top-end="$t('INTEGRATION_SETTINGS.OPEN_AI.AI_ASSIST')"
      icon="wand"
      color-scheme="secondary"
      variant="smooth"
      size="small"
      @click="openAIAssist"
    />
  </div>
</template>
<script>
import aiMixin from 'dashboard/mixins/aiMixin';

export default {
  mixins: [aiMixin],
  methods: {
    openAIAssist() {
      const ninja = document.querySelector('ninja-keys');
      ninja.open({ parent: 'ai_assist' });
    },
  },
};
</script>
