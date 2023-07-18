<template>
  <div class="position-relative">
    <woot-button
      icon="wand"
      color-scheme="secondary"
      variant="smooth"
      size="small"
      class-names="ai-btn"
      @click="onClick"
    >
      {{ $t('INTEGRATION_SETTINGS.OPEN_AI.AI_ASSIST') }}
    </woot-button>

    <div class="radar-ping" />
    <div class="bubble" />
  </div>
</template>
<script>
export default {
  methods: {
    onClick() {
      this.$emit('click');
    },
  },
};
</script>
<style lang="scss" scoped>
.ai-btn {
  background: linear-gradient(
      255.98deg,
      rgba(161, 87, 246, 0.2) 15.83%,
      rgba(71, 145, 247, 0.2) 81.39%
    ),
    linear-gradient(0deg, #f2f5f8, #f2f5f8);
  animation: gradient 5s ease infinite;
}
@keyframes gradient {
  0% {
    background-position: 0% 50%;
  }
  50% {
    background-position: 100% 50%;
  }
  100% {
    background-position: 0% 50%;
  }
}

.radar-ping {
  position: absolute;
  top: 0;
  right: 0;
  margin-top: -0.25rem;
  margin-right: -0.25rem;
  border-radius: 9999px;
  width: 0.75rem;
  height: 0.75rem;
  background-color: var(--w-500);
  animation: ping 1s cubic-bezier(0, 0, 0.2, 1) infinite;

  @keyframes ping {
    75%,
    100% {
      transform: scale(2);
      opacity: 0;
    }
  }
}

.bubble {
  position: absolute;
  top: 0;
  right: 0;
  margin-top: -0.25rem;
  margin-right: -0.25rem;
  border-radius: 9999px;
  width: 0.75rem;
  height: 0.75rem;
  background-color: var(--w-500);
}
</style>
