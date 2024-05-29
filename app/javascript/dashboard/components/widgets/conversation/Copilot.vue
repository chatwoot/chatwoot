<template>
  <div class="copilot">
    <woot-button
      v-if="showCopilot"
      color-scheme="primary"
      icon="star-glitters"
      size="tiny"
      @click="askCopilot"
    >
      Ask Copilot
    </woot-button>
    <fluent-icon
      v-if="showLoadingSmartResponseIcon"
      icon="star-glitters"
      class="ml-2 mt-1"
      size="12"
    />
  </div>
</template>

<script>
export default {
  props: {
    showCopilot: { type: Boolean, default: false },
    showLoadingSmartResponseIcon: { type: Boolean, default: false },
  },
  methods: {
    askCopilot() {
      this.$emit('ask-copilot');
    },
  },
};
</script>
