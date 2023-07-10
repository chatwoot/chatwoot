<template>
  <div class="animation-container margin-top-1">
    <div class="ai-typing--wrap ">
      <fluent-icon icon="wand" size="14" class="ai-typing--icon" />
      <label>AI is writing</label>
    </div>
    <span class="loader" />
    <span class="loader" />
    <span class="loader" />
  </div>
</template>

<style lang="scss" scoped>
.ai-typing--wrap {
  display: flex;
  align-items: center;
  gap: 4px;

  .ai-typing--icon {
    color: var(--v-500);
  }
}

.animation-container {
  position: relative;
  display: flex;
}

.animation-container label {
  display: inline-block;
  margin-right: 8px;
  color: var(--v-400);
}

.loader {
  display: inline-block;
  width: 6px;
  height: 6px;
  margin-right: 4px;
  margin-top: 12px;
  background-color: var(--v-300);
  border-radius: 50%;
  animation: bubble-scale 1.2s infinite;
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
</style>
