<template>
  <div class="animation-container margin-top-1">
    <div class="ai-typing--wrap">
      <fluent-icon icon="wand" size="14" class="ai-typing--icon" />
      <label>
        {{ $t('INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.AI_WRITING') }}
      </label>
    </div>
    <span class="loader" />
    <span class="loader" />
    <span class="loader" />
  </div>
</template>

<style lang="scss" scoped>
.animation-container {
  position: relative;
  display: flex;
  .ai-typing--wrap {
    display: flex;
    align-items: center;
    gap: 4px;

    .ai-typing--icon {
      @apply text-n-iris-11;
    }
  }
  label {
    @apply text-n-iris-11 ltr:mr-1 rtl:ml-1 inline-block;
  }
  .loader {
    animation: bubble-scale 1.2s infinite;
    @apply bg-n-iris-11 inline-block size-1.5 ltr:mr-1 rtl:ml-1 mt-3 rounded-full;
  }

  .loader:nth-child(2) {
    animation-delay: 0.4s;
  }

  .loader:nth-child(3) {
    animation-delay: 0.8s;
  }

  @keyframes bubble-scale {
    0%,
    100% {
      transform: scale(1);
    }
    25% {
      transform: scale(1.3);
    }
    50% {
      transform: scale(1);
    }
  }
}
</style>
